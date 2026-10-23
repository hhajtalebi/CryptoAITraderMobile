import 'dart:math' as math;
import '../../market/domain/models.dart';
import 'indicators.dart';

enum Direction { long, short, wait }

class Analysis {
  final String symbol, interval, regime, structure, reason;
  final Direction direction;
  final double confidence, entry, stop, support, resistance;
  final List<double> targets;
  final Map<String, double> values;
  final int candleTime;
  final double? mtf;
  const Analysis({
    required this.symbol,
    required this.interval,
    required this.direction,
    required this.confidence,
    required this.entry,
    required this.stop,
    required this.targets,
    required this.regime,
    required this.structure,
    required this.support,
    required this.resistance,
    required this.reason,
    required this.values,
    required this.candleTime,
    this.mtf,
  });
  String get key => '$symbol:$interval:$candleTime:${direction.name}';
  bool get tradable => direction != Direction.wait;
}

/// Research model mobile-v1: deliberately not presented as upstream model parity.
class SignalEngine {
  static Analysis evaluate(
    String symbol,
    String interval,
    List<Candle> raw,
    DateTime now, {
    List<Candle>? higher,
    int higherMs = 14400000,
  }) {
    final ms = intervals[interval]!;
    final c =
        raw
            .where((c) => c.valid && c.time + ms <= now.millisecondsSinceEpoch)
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    Analysis wait(String why) => Analysis(
      symbol: symbol,
      interval: interval,
      direction: Direction.wait,
      confidence: 0,
      entry: c.isEmpty ? 0 : c.last.close,
      stop: 0,
      targets: [],
      regime: 'unknown',
      structure: 'unknown',
      support: 0,
      resistance: 0,
      reason: why,
      values: {},
      candleTime: c.isEmpty ? 0 : c.last.time,
    );
    if (c.length < 60) return wait('warmup');
    if (now.millisecondsSinceEpoch - c.last.time > ms * 2 + 30000) {
      return wait('stale');
    }
    for (var i = 1; i < c.length; i++) {
      if (c[i].time - c[i - 1].time != ms) return wait('candle_gap');
    }
    final all = Indicators.all(c), v = all.map((k, v) => MapEntry(k, v.last));
    if (v.values.any((v) => !v.isFinite)) return wait('invalid_indicators');
    final recent = c.sublist(c.length - 21, c.length - 1);
    final support = recent.map((v) => v.low).reduce(math.min),
        resistance = recent.map((v) => v.high).reduce(math.max);
    final entry = c.last.close, atr = v['ATR']!;
    if (atr <= 0) return wait('flat_market');
    final trend = v['EMA 20']! > v['EMA 50']! ? 1.0 : -1.0;
    final momentum = (v['RSI']! - 50) / 25;
    final histogram = v['MACD']! - v['MACD signal']!;
    final macd = histogram.abs() < atr * .001
        ? 0.0
        : (histogram > 0 ? 1.0 : -1.0);
    final score = .5 * trend + .25 * momentum.clamp(-1, 1) + .25 * macd;
    final sign = score >= 0 ? 1.0 : -1.0;
    var direction = score.abs() < .55
        ? Direction.wait
        : (sign > 0 ? Direction.long : Direction.short);
    var reason = direction == Direction.wait
        ? 'mixed_evidence'
        : 'trend_momentum';
    final regime = v['ADX']! >= 25 ? 'trending' : 'ranging';
    if (regime == 'ranging') {
      direction = Direction.wait;
      reason = 'range_no_edge';
    }
    double? alignment;
    if (higher != null) {
      final hc = higher
          .where(
            (e) => e.valid && e.time + higherMs <= now.millisecondsSinceEpoch,
          )
          .toList();
      if (hc.length >= 60 &&
          now.millisecondsSinceEpoch - hc.last.time <= higherMs * 2 + 30000) {
        final a = hc.map((e) => e.close).toList();
        alignment =
            (Indicators.ema(a, 20).last > Indicators.ema(a, 50).last
                ? 1.0
                : -1.0) *
            sign;
        if (alignment < 0) {
          direction = Direction.wait;
          reason = 'mtf_conflict';
        }
      }
    }
    // No high-confidence bonus: saturation dampening follows reference lesson.
    final technical = 50 + score.abs() * 25;
    final confidence =
        (technical > 68 ? 68 - (technical - 68) * .5 : technical) +
        (alignment == 1 ? 3 : 0);
    var distance = math.max(
      atr * 1.8,
      sign > 0 ? entry - support + atr * .25 : resistance - entry + atr * .25,
    );
    if (distance / entry > .08) {
      direction = Direction.wait;
      reason = 'stop_too_wide';
    }
    if ((entry - v['EMA 20']!).abs() > atr * 3) {
      direction = Direction.wait;
      reason = 'extended_move';
    }
    return Analysis(
      symbol: symbol,
      interval: interval,
      direction: direction,
      confidence: confidence,
      entry: entry,
      stop: entry - sign * distance,
      targets: [1.5, 2.5, 4].map((r) => entry + sign * distance * r).toList(),
      regime: regime,
      structure: entry > resistance
          ? 'breakout'
          : entry < support
          ? 'breakdown'
          : trend > 0
          ? 'higher_bias'
          : 'lower_bias',
      support: support,
      resistance: resistance,
      reason: reason,
      values: v,
      candleTime: c.last.time,
      mtf: alignment,
    );
  }
}
