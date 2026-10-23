import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';
import '../../analysis/application/analysis_provider.dart';
import '../application/market_controller.dart';
import '../domain/models.dart';
import 'candle_chart.dart';

class MarketChartCard extends ConsumerWidget {
  const MarketChartCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(symbolProvider),
        tf = ref.watch(timeframeProvider),
        market = ref.watch(marketProvider),
        q = market.quotes[symbol],
        analysis = ref.watch(analysisProvider);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoinAvatar(symbol),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ref.watch(exchangeProvider),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr(ref, 'retry'),
                onPressed: () {
                  ref.read(marketProvider.notifier).refresh();
                  ref.invalidate(analysisProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 20, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  q == null ? '—' : '\$${price(q.price)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
              ),
              if (q != null)
                Pill(
                  '${q.change >= 0 ? '+' : ''}${q.change.toStringAsFixed(2)}%',
                  color: q.change >= 0 ? mint : red,
                ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: intervals.keys
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: tf == s,
                          onSelected: (_) =>
                              ref.read(timeframeProvider.notifier).state = s,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          analysis.when(
            data: (v) => Column(
              children: [
                if (v.batch.cached)
                  Notice(tr(ref, 'cache'), color: Colors.amber),
                CandleChart(v.batch.candles),
              ],
            ),
            loading: () => const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, s) => SizedBox(
              height: 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: muted),
                  Notice(tr(ref, 'candles_unavailable')),
                  TextButton(
                    onPressed: () => ref.invalidate(analysisProvider),
                    child: Text(tr(ref, 'retry')),
                  ),
                ],
              ),
            ),
          ),
          if (q != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${tr(ref, 'last_update')}: ${q.time.toUtc().toIso8601String().substring(11, 19)} UTC',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 10,
                  color: muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CoinAvatar extends StatelessWidget {
  final String symbol;
  const CoinAvatar(this.symbol, {super.key});
  @override
  Widget build(BuildContext context) {
    final base = symbol.split('/').first,
        color = base == 'BTC'
            ? const Color(0xFFF7B55C)
            : base == 'ETH'
            ? blue
            : mint;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        base.substring(0, 1),
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}

class AssetRow extends ConsumerWidget {
  final Quote q;
  const AssetRow(this.q, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starred = ref.watch(watchlistProvider).contains(q.symbol);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        ref.read(symbolProvider.notifier).state = q.symbol;
        ref.read(tabProvider.notifier).state = 0;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            CoinAvatar(q.symbol),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.symbol.split('/').first,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'USDT • ${q.exchange}',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price(q.price),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${q.change >= 0 ? '+' : ''}${q.change.toStringAsFixed(2)}%',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: q.change >= 0 ? mint : red,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: tr(ref, 'watchlist'),
              onPressed: () async {
                try {
                  await ref.read(watchlistProvider.notifier).toggle(q.symbol);
                } catch (_) {
                  if (context.mounted) toast(context, tr(ref, 'storage_error'));
                }
              },
              icon: Icon(
                starred ? Icons.star_rounded : Icons.star_border_rounded,
                color: starred ? const Color(0xFFFFCB75) : muted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketsPage extends ConsumerStatefulWidget {
  const MarketsPage({super.key});
  @override
  ConsumerState<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends ConsumerState<MarketsPage> {
  String search = '';
  bool onlyStars = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketProvider),
        stars = ref.watch(watchlistProvider);
    final quotes =
        state.quotes.values
            .where(
              (q) =>
                  q.symbol.toLowerCase().contains(search.toLowerCase()) &&
                  (!onlyStars || stars.contains(q.symbol)),
            )
            .toList()
          ..sort((a, b) => b.volume.compareTo(a.volume));
    return RefreshIndicator(
      onRefresh: () => ref.read(marketProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
        children: [
          Text(
            tr(ref, 'market'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: tr(ref, 'search'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(tr(ref, 'all')),
                selected: !onlyStars,
                onSelected: (_) => setState(() => onlyStars = false),
              ),
              ChoiceChip(
                label: Text(tr(ref, 'watchlist')),
                selected: onlyStars,
                onSelected: (_) => setState(() => onlyStars = true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.error != null) Notice(tr(ref, state.error!)),
          if (state.loading) const LinearProgressIndicator(),
          if (quotes.isEmpty && !state.loading)
            Notice(tr(ref, onlyStars ? 'empty_watch' : 'no_data')),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: quotes.take(150).map(AssetRow.new).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
