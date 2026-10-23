import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';
import '../../analysis/application/analysis_provider.dart';
import '../../analysis/presentation/signals_page.dart';
import '../../market/application/market_controller.dart';
import '../application/trading_controller.dart';
import '../domain/position.dart';

class TradingPage extends ConsumerStatefulWidget {
  const TradingPage({super.key});
  @override
  ConsumerState<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends ConsumerState<TradingPage> {
  bool busy = false;
  Future<void> submit() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'confirm'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Notice(tr(ref, 'confirm_note')),
              Notice(
                tr(ref, 'risk_note'),
                icon: Icons.shield_outlined,
                color: mint,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr(ref, 'confirm')),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr(ref, 'cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    try {
      await ref.read(tradingControllerProvider).submit();
      if (mounted) toast(context, tr(ref, 'saved'));
    } catch (e) {
      if (mounted) {
        toast(
          context,
          '${tr(ref, 'risk_rejected')}: ${tr(ref, e is StateError ? e.message : 'storage_error')}',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(analysisProvider).valueOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr(ref, 'Trading'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Pill(tr(ref, 'paper')),
          ],
        ),
        Notice(tr(ref, 'no_live'), icon: Icons.lock_outline, color: mint),
        if (a != null) PlanCard(a.analysis),
        const SizedBox(height: 16),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(ref, 'risk'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Notice(tr(ref, 'risk_note')),
              Notice(tr(ref, 'foreground'), color: const Color(0xFFFFCB75)),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: a?.canTrade == true && !busy ? submit : null,
                  icon: Icon(
                    busy ? Icons.hourglass_empty : Icons.shield_outlined,
                  ),
                  label: Text(tr(ref, 'submit')),
                ),
              ),
              if (a?.canTrade != true) Notice(tr(ref, 'not_ready')),
            ],
          ),
        ),
        SectionTitle(tr(ref, 'open')),
        ref
            .watch(positionsProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Notice(tr(ref, 'storage_error')),
              data: (list) {
                final open = list.where((p) => p.active).toList();
                return open.isEmpty
                    ? Surface(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.layers_outlined,
                              size: 40,
                              color: muted,
                            ),
                            const SizedBox(height: 16),
                            Notice(tr(ref, 'no_positions')),
                          ],
                        ),
                      )
                    : Column(
                        children: open
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PositionCard(p),
                              ),
                            )
                            .toList(),
                      );
              },
            ),
      ],
    );
  }
}

class PositionCard extends ConsumerStatefulWidget {
  final Position position;
  const PositionCard(this.position, {super.key});
  @override
  ConsumerState<PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends ConsumerState<PositionCard> {
  bool busy = false;
  Future<void> close(double fraction) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref
          .read(tradingControllerProvider)
          .close(widget.position, fraction);
    } catch (e) {
      if (mounted) {
        toast(context, tr(ref, e is StateError ? e.message : 'storage_error'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position,
        q = ref.watch(marketProvider).quotes[p.symbol],
        fresh =
            q != null &&
            q.exchange == p.exchange &&
            q.fresh(DateTime.now().toUtc());
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.symbol,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Pill(p.side.name.toUpperCase()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${p.exchange} • ${p.state.name}',
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10,
              color: muted,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Metric(tr(ref, 'entry'), price(p.entry))),
              Expanded(
                child: Metric(
                  tr(ref, 'unrealized'),
                  fresh ? money(p.unrealized(q.price)) : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${p.remaining.toStringAsFixed(6)} • SL ${price(p.stop)} • TP ${p.targetIndex}/3',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              color: muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: fresh && !busy ? () => close(.5) : null,
                  child: Text(tr(ref, 'partial')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: fresh && !busy ? () => close(1) : null,
                  child: Text(tr(ref, 'close')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
