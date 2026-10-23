import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';
import '../application/analysis_provider.dart';
import '../domain/analysis.dart';

class SignalsPage extends ConsumerWidget {
  const SignalsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              tr(ref, 'analysis'),
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(analysisProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const SignalCard(),
      SectionTitle(tr(ref, 'levels')),
      ref
          .watch(analysisProvider)
          .when(
            data: (v) => PlanCard(v.analysis),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Notice(tr(ref, 'candles_unavailable')),
          ),
      SectionTitle(tr(ref, 'indicators')),
      ref
          .watch(analysisProvider)
          .when(
            data: (v) => Surface(
              child: Column(
                children: v.analysis.values.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              price(e.value),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
      SectionTitle(tr(ref, 'prediction')),
      Surface(child: Notice(tr(ref, 'prediction_note'))),
    ],
  );
}

class SignalCard extends ConsumerWidget {
  const SignalCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(analysisProvider)
      .when(
        loading: () => Surface(child: Notice(tr(ref, 'loading'))),
        error: (e, s) => Surface(child: Notice(tr(ref, 'candles_unavailable'))),
        data: (v) {
          final a = v.analysis,
              color = a.direction == Direction.wait
                  ? const Color(0xFFFFCB75)
                  : a.direction == Direction.long
                  ? mint
                  : red;
          return Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${a.symbol}  •  ${a.interval}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Pill(a.direction.name.toUpperCase(), color: color),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Metric(
                        tr(ref, 'technical'),
                        '${a.confidence.toStringAsFixed(0)} / 100',
                        color: color,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: a.confidence / 100,
                              strokeWidth: 4,
                              backgroundColor: line,
                              color: color,
                            ),
                          ),
                          Icon(Icons.auto_awesome, size: 19, color: color),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Notice(tr(ref, 'confidence_note')),
                const Divider(color: line),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 25,
                  runSpacing: 20,
                  children: [
                    Metric(tr(ref, 'regime'), tr(ref, a.regime)),
                    Metric(
                      tr(ref, 'mtf'),
                      tr(
                        ref,
                        a.mtf == null
                            ? 'unknown'
                            : a.mtf! > 0
                            ? 'aligned'
                            : 'conflict',
                      ),
                    ),
                    Metric(tr(ref, 'structure'), tr(ref, a.structure)),
                  ],
                ),
                const SizedBox(height: 16),
                Notice(tr(ref, a.reason), color: color),
                if (v.batch.cached) Notice(tr(ref, 'cache'), color: red),
                if (!v.canTrade) Notice(tr(ref, 'wait_detail')),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(tabProvider.notifier).state = 3;
                    },
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: Text(tr(ref, 'submit')),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class PlanCard extends ConsumerWidget {
  final Analysis a;
  const PlanCard(this.a, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Surface(
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Metric(tr(ref, 'entry'), price(a.entry))),
            Expanded(
              child: Metric(
                tr(ref, 'stop'),
                a.stop > 0 ? price(a.stop) : '—',
                color: red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Metric(
                'TP${i + 1}',
                a.targets.length > i ? price(a.targets[i]) : '—',
                color: mint,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Notice(tr(ref, 'tp_note')),
        const Divider(color: line),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: Metric(tr(ref, 'support'), price(a.support))),
            Expanded(child: Metric(tr(ref, 'resistance'), price(a.resistance))),
          ],
        ),
      ],
    ),
  );
}
