import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'design.dart';
import '../../features/market/application/market_controller.dart';
import '../../features/market/presentation/market_widgets.dart';
import '../../features/portfolio/presentation/portfolio_page.dart';
import '../../features/research/presentation/research_page.dart';
import '../../features/assistant/presentation/assistant_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider),
        stars = ref.watch(watchlistProvider),
        rows = market.quotes.values
            .where((q) => stars.contains(q.symbol))
            .take(4)
            .toList();
    return RefreshIndicator(
      onRefresh: () => ref.read(marketProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          Text(
            tr(ref, 'overview'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 25,
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 22),
          const BalanceCard(),
          SectionTitle(
            tr(ref, 'market'),
            trailing: Pill(
              tr(ref, market.connection),
              color: market.connection == 'offline' ? red : mint,
            ),
          ),
          if (market.error != null) Notice(tr(ref, market.error!)),
          const MarketChartCard(),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssistantPage()),
            ),
            child: Surface(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: blue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(ref, 'assistant'),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          tr(ref, 'assistant_sub'),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: muted,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: muted),
                ],
              ),
            ),
          ),
          SectionTitle(
            tr(ref, 'watchlist'),
            trailing: IconButton(
              onPressed: () => ref.read(tabProvider.notifier).state = 1,
              icon: const Icon(Icons.add, size: 20, color: mint),
            ),
          ),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: rows.isEmpty
                ? Notice(tr(ref, 'empty_watch'))
                : Column(children: rows.map(AssetRow.new).toList()),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResearchPage()),
            ),
            child: Surface(
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, color: mint, size: 27),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(ref, 'research'),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          tr(ref, 'research_sub'),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          Notice(tr(ref, 'no_live'), icon: Icons.verified_user_outlined),
        ],
      ),
    );
  }
}
