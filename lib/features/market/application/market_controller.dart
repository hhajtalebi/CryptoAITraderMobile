import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/data/transport.dart';
import '../data/exchanges.dart';
import '../data/market_repository.dart';
import '../domain/models.dart';

final gatewayProvider = Provider<PublicExchange>((ref) {
  final p = PublicExchange(ref.watch(exchangeProvider));
  ref.onDispose(p.dispose);
  return p;
});
final marketRepositoryProvider = Provider(
  (ref) =>
      MarketRepository(ref.watch(gatewayProvider), ref.watch(databaseProvider)),
);

class MarketState {
  final Map<String, Quote> quotes;
  final String connection;
  final String? error;
  final bool loading;
  const MarketState({
    this.quotes = const {},
    this.connection = 'connecting',
    this.error,
    this.loading = true,
  });
}

class MarketController extends StateNotifier<MarketState> {
  final MarketRepository repo;
  final String selected;
  final void Function(Quote) onQuote;
  final bool active;
  Timer? _poll;
  ResilientSocket? _socket;
  bool _busy = false;
  MarketController(this.repo, this.selected, this.onQuote, {this.active = true})
    : super(const MarketState()) {
    if (active) {
      refresh();
      _poll = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
      _startSocket();
    } else {
      state = const MarketState(connection: 'paused', loading: false);
    }
  }
  Future<void> refresh() async {
    if (_busy || !mounted || !active) return;
    _busy = true;
    try {
      final rows = await repo.tickers();
      if (!mounted) return;
      final q = {for (final e in rows) e.symbol: e};
      // Do not overwrite a newer stream tick with an older REST snapshot.
      for (final old in state.quotes.values) {
        if (!old.cached &&
            old.time.isAfter(q[old.symbol]?.time ?? DateTime(1970))) {
          q[old.symbol] = old;
        }
      }
      state = MarketState(
        quotes: q,
        connection: rows.first.cached ? 'offline' : state.connection,
        loading: false,
        error: rows.first.cached ? 'offline_cache' : null,
      );
      for (final q in rows) {
        if (q.fresh(DateTime.now().toUtc())) onQuote(q);
      }
    } catch (e) {
      if (mounted) {
        state = MarketState(
          quotes: state.quotes,
          connection: 'offline',
          error: e is NetworkFailure ? e.code : 'network_unavailable',
          loading: false,
        );
      }
    } finally {
      _busy = false;
    }
  }

  void _startSocket() {
    final lb = repo.exchange.id == 'LBank';
    final wire = lb
        ? selected.toLowerCase().replaceAll('/', '_')
        : selected.replaceAll('/', '');
    _socket = ResilientSocket(
      url: lb
          ? 'wss://api.lbank.info/ws/V2/'
          : 'wss://stream.toobit.com/quote/ws/v1',
      subscriptions: [
        lb
            ? {'action': 'subscribe', 'subscribe': 'tick', 'pair': wire}
            : {
                'symbol': wire,
                'topic': 'realtimes',
                'event': 'sub',
                'params': {'binary': false},
              },
      ],
      onStatus: (s) {
        if (mounted) {
          state = MarketState(
            quotes: state.quotes,
            connection: s,
            error: state.error,
            loading: state.loading,
          );
        }
      },
      onMessage: (m) {
        final dynamic payload = lb ? m['tick'] : m['data'];
        if (payload == null) return;
        final dynamic row = payload is List
            ? (payload.isEmpty ? null : payload.first)
            : payload;
        if (row is! Map) return;
        final price = number(row[lb ? 'latest' : 'c']);
        final time = parseStreamTime(
          lb ? m['TS'] ?? m['timestamp'] : row['t'] ?? m['ts'],
          lbank: lb,
        );
        if (!price.isFinite || price <= 0 || time == null) return;
        final old = state.quotes[selected];
        final q = Quote(
          repo.exchange.id,
          selected,
          price,
          number(row[lb ? 'change' : 'm']).isFinite
              ? number(row[lb ? 'change' : 'm']) * (lb ? 1 : 100)
              : old?.change ?? 0,
          number(row[lb ? 'turnover' : 'qv']).isFinite
              ? number(row[lb ? 'turnover' : 'qv'])
              : old?.volume ?? 0,
          time,
        );
        if (!q.fresh(DateTime.now().toUtc()) ||
            (old != null && q.time.isBefore(old.time))) {
          return;
        }
        if (mounted) {
          state = MarketState(
            quotes: {...state.quotes, selected: q},
            connection: 'streaming',
            loading: false,
          );
          onQuote(q);
        }
      },
    );
    _socket!.start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}

final marketProvider = StateNotifierProvider<MarketController, MarketState>((
  ref,
) {
  final repo = ref.watch(marketRepositoryProvider),
      selected = ref.watch(symbolProvider),
      active = ref.watch(appActiveProvider);
  final paper = ref.watch(paperProvider);
  bool alive = true;
  ref.onDispose(() => alive = false);
  return MarketController(repo, selected, (q) async {
    if (!alive) return;
    final positions = ref.read(positionsProvider).valueOrNull ?? [];
    if (!positions.any(
      (p) => p.active && p.symbol == q.symbol && p.exchange == q.exchange,
    )) {
      return;
    }
    try {
      final n = await paper.mark(q, DateTime.now().toUtc());
      if (alive && n > 0) {
        ref.invalidate(positionsProvider);
        ref.invalidate(historyProvider);
        ref.read(alertProvider.notifier).state = 'paper_exit';
      }
    } catch (_) {
      if (alive) ref.read(alertProvider.notifier).state = 'storage_error';
    }
  }, active: active);
});
