import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';
import '../../analysis/application/analysis_provider.dart';
import '../../market/domain/models.dart';
import '../domain/backtest.dart';

Map<String, dynamic> runResearch(Map<String, dynamic> m) {
  final c = m['candles'] as List<Candle>, tf = m['tf'] as String;
  return {'report': Backtester.run(c, tf), 'folds': Backtester.walk(c, tf)};
}

class ResearchPage extends ConsumerStatefulWidget {
  const ResearchPage({super.key});
  @override
  ConsumerState<ResearchPage> createState() => _ResearchPageState();
}

class _ResearchPageState extends ConsumerState<ResearchPage> {
  bool busy = false;
  ResearchReport? report;
  List<WalkForwardFold> folds = [];
  Future<void> run() async {
    final view = ref.read(analysisProvider).valueOrNull;
    if (view == null) return;
    setState(() => busy = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch,
          tf = ref.read(timeframeProvider),
          c = view.batch.candles
              .where((e) => e.time + intervals[tf]! <= now)
              .toList();
      final r = await compute(runResearch, {'candles': c, 'tf': tf});
      if (mounted) {
        setState(() {
          report = r['report'];
          folds = r['folds'];
        });
      }
    } catch (_) {
      if (mounted) toast(context, tr(ref, 'no_data'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = report, edge = r == null ? null : LearnedEdge.from(r.returns);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'research'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Pill(
            '${ref.watch(symbolProvider)} • ${ref.watch(timeframeProvider)}',
            color: blue,
          ),
          Notice(tr(ref, 'research_note')),
          FilledButton.icon(
            onPressed: busy || ref.watch(analysisProvider).valueOrNull == null
                ? null
                : run,
            icon: const Icon(Icons.science_outlined),
            label: Text(tr(ref, 'run')),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: LinearProgressIndicator(),
            ),
          SectionTitle(tr(ref, 'backtest')),
          if (r == null)
            Notice(tr(ref, 'test_not_run'))
          else
            Surface(
              child: Wrap(
                spacing: 32,
                runSpacing: 24,
                children: [
                  Metric(tr(ref, 'trades'), '${r.returns.length}'),
                  Metric(
                    tr(ref, 'win_rate'),
                    r.winRate == null
                        ? '—'
                        : '${(r.winRate! * 100).toStringAsFixed(1)}%',
                  ),
                  Metric(tr(ref, 'net_r'), r.net.toStringAsFixed(2)),
                  Metric(
                    tr(ref, 'drawdown'),
                    '${(r.maxDrawdown * 100).toStringAsFixed(2)}%',
                  ),
                  Metric(
                    'Profit factor',
                    r.profitFactor?.toStringAsFixed(2) ?? '—',
                  ),
                ],
              ),
            ),
          SectionTitle(tr(ref, 'folds')),
          ...folds.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                child: Row(
                  children: [
                    Expanded(
                      child: Metric(
                        'Train → Test',
                        '${f.trainBars} → ${f.testBars}',
                      ),
                    ),
                    Metric(tr(ref, 'net_r'), f.test.net.toStringAsFixed(2)),
                    const SizedBox(width: 18),
                    Metric(tr(ref, 'trades'), '${f.test.returns.length}'),
                  ],
                ),
              ),
            ),
          ),
          SectionTitle(tr(ref, 'edge')),
          Surface(
            child: edge?.winRate == null
                ? Notice(tr(ref, 'insufficient'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Metric(tr(ref, 'samples'), '${edge!.samples}'),
                      const SizedBox(height: 16),
                      Metric(
                        'Beta win rate',
                        '${(edge.winRate! * 100).toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 16),
                      Metric(
                        '95% Wilson',
                        '${(edge.low! * 100).toStringAsFixed(1)}–${(edge.high! * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
          ),
          Notice(tr(ref, 'no_live'), icon: Icons.lock_outline),
        ],
      ),
    );
  }
}
