import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../market/application/market_controller.dart';
import '../../market/data/market_repository.dart';
import '../../market/domain/models.dart';
import '../domain/analysis.dart';

class AnalysisView {
  final Analysis analysis;
  final CandleBatch batch;
  final bool mtfAvailable;
  AnalysisView(this.analysis, this.batch, this.mtfAvailable);
  bool get canTrade => analysis.tradable && !batch.cached && mtfAvailable;
}

Analysis computeAnalysis(Map<String, dynamic> a) => SignalEngine.evaluate(
  a['symbol'],
  a['tf'],
  a['candles'],
  a['now'],
  higher: a['higher'],
  higherMs: a['higherMs'],
);
final analysisProvider = FutureProvider.autoDispose<AnalysisView>((ref) async {
  final symbol = ref.watch(symbolProvider),
      tf = ref.watch(timeframeProvider),
      repo = ref.watch(marketRepositoryProvider);
  final active = ref.watch(appActiveProvider);
  if (active) {
    final timer = Timer(
      const Duration(seconds: 60),
      () => ref.invalidateSelf(),
    );
    ref.onDispose(timer.cancel);
  }
  final batch = await repo.candles(symbol, tf);
  final higherTf = ['1d', '1w'].contains(tf)
      ? '1w'
      : tf == '4h'
      ? '1d'
      : '4h';
  CandleBatch? higher;
  try {
    higher = tf == higherTf ? batch : await repo.candles(symbol, higherTf);
  } catch (_) {
    higher = null;
  }
  final a = await compute(computeAnalysis, {
    'symbol': symbol,
    'tf': tf,
    'candles': batch.candles,
    'higher': higher?.candles,
    'higherMs': intervals[higherTf],
    'now': DateTime.now().toUtc(),
  });
  return AnalysisView(
    a,
    batch,
    tf != higherTf && higher != null && !higher.cached && a.mtf != null,
  );
});
