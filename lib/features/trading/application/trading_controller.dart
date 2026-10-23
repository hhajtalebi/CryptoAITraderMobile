import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers.dart';
import '../../analysis/application/analysis_provider.dart';
import '../../market/application/market_controller.dart';
import '../../market/domain/models.dart';
import '../domain/risk.dart';
import '../domain/position.dart';

final tradingControllerProvider = Provider((ref) => TradingController(ref));

class TradingController {
  final Ref ref;
  bool busy = false;
  TradingController(this.ref);
  Future<void> submit() async {
    if (busy) return;
    busy = true;
    try {
      final view = ref.read(analysisProvider).valueOrNull;
      if (view == null || !view.canTrade) throw StateError('not_ready');
      final a = view.analysis, q = ref.read(marketProvider).quotes[a.symbol];
      if (q == null) throw StateError('stale_quote');
      await ref
          .read(paperProvider)
          .submit(
            TradePlan(
              key: a.key,
              exchange: ref.read(exchangeProvider),
              symbol: a.symbol,
              side: a.direction,
              entry: a.entry,
              stop: a.stop,
              targets: a.targets,
              atr: a.values['ATR']!,
              signalTime: a.candleTime,
              intervalMs: intervals[a.interval]!,
            ),
            q,
            DateTime.now().toUtc(),
            marks: ref.read(marketProvider).quotes,
          );
      ref.invalidate(positionsProvider);
      ref.invalidate(historyProvider);
    } finally {
      busy = false;
    }
  }

  Future<void> close(Position p, double fraction) async {
    if (busy) return;
    busy = true;
    try {
      final q = ref.read(marketProvider).quotes[p.symbol];
      if (q == null) throw StateError('stale_quote');
      await ref
          .read(paperProvider)
          .close(p.id, const Uuid().v4(), fraction, q, DateTime.now().toUtc());
      ref.invalidate(positionsProvider);
      ref.invalidate(historyProvider);
    } finally {
      busy = false;
    }
  }
}
