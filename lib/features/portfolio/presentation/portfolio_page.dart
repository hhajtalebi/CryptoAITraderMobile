import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';
import '../../trading/data/paper_repository.dart';
import '../../market/application/market_controller.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(positionsProvider).valueOrNull ?? [],
        quotes = ref.watch(marketProvider).quotes;
    final realized = positions.fold(0.0, (s, p) => s + p.pnl),
        reserved = positions.fold(0.0, (s, p) => s + p.reserved);
    double unrealized = 0;
    bool known = true;
    for (final p in positions.where((p) => p.active)) {
      final q = quotes[p.symbol];
      if (q == null ||
          q.exchange != p.exchange ||
          !q.fresh(DateTime.now().toUtc())) {
        known = false;
      } else {
        unrealized += p.unrealized(q.price);
      }
    }
    final balance = PaperRepository.startingBalance + realized;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF183D3C), Color(0xFF12232E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: mint.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(ref, 'balance'),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Color(0xFFB6D3D2),
                    fontSize: 13,
                  ),
                ),
              ),
              Pill(tr(ref, 'paper')),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            known ? '\$${money(balance + unrealized)}' : '—',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 36,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(ref, 'virtual'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              color: muted,
              fontSize: 11,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: Color(0xFF284449)),
          ),
          Row(
            children: [
              Expanded(
                child: Metric(
                  tr(ref, 'available'),
                  '\$${money(balance - reserved)}',
                ),
              ),
              Expanded(
                child: Metric(
                  tr(ref, 'realized'),
                  '${realized >= 0 ? '+' : ''}${money(realized)}',
                  color: realized >= 0 ? mint : red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
    children: [
      Text(
        tr(ref, 'Portfolio'),
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 27,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 20),
      const BalanceCard(),
      Notice(tr(ref, 'foreground')),
      SectionTitle(tr(ref, 'trade_history')),
      const HistoryList(),
    ],
  );
}

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(historyProvider)
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (e, s) => Notice(tr(ref, 'storage_error')),
        data: (rows) => rows.isEmpty
            ? Surface(child: Notice(tr(ref, 'no_notifications')))
            : Surface(
                child: Column(
                  children: rows.map((r) {
                    final body = jsonDecode(r['body'] as String),
                        pnl = (r['pnl'] as num).toDouble();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: (pnl >= 0 ? mint : red).withValues(
                                alpha: .1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              pnl >= 0 ? Icons.south_west : Icons.north_east,
                              size: 17,
                              color: pnl >= 0 ? mint : red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${body['reason']} • ${(r['position_id'] as String).split(':').skip(1).first}',
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    r['time'] as int,
                                  ).toString().substring(0, 16),
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(pnl),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              color: pnl >= 0 ? mint : red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
      );
}
