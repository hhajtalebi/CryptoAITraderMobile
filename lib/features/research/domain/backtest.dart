import 'dart:math' as math;
import '../../market/domain/models.dart';
import '../../analysis/domain/analysis.dart';
import '../../trading/domain/position.dart';
import '../../trading/domain/risk.dart';

class ResearchReport {
  final List<double> returns;
  final int candles;
  final double maxDrawdown;
  const ResearchReport(this.returns, this.candles, this.maxDrawdown);
  double get net => returns.fold(0, (a, b) => a + b);
  double? get winRate => returns.isEmpty
      ? null
      : returns.where((r) => r > 0).length / returns.length;
  double? get profitFactor {
    final loss = returns.where((r) => r < 0).fold(0.0, (a, b) => a - b);
    return loss == 0
        ? null
        : returns.where((r) => r > 0).fold(0.0, (a, b) => a + b) / loss;
  }
}

class LearnedEdge {
  final int samples;
  final double? winRate, low, high, meanR;
  const LearnedEdge(
    this.samples,
    this.winRate,
    this.low,
    this.high,
    this.meanR,
  );
  factory LearnedEdge.from(List<double> rs) {
    final n = rs.length;
    if (n < 30) return LearnedEdge(n, null, null, null, null);
    final wins = rs.where((r) => r > 0).length,
        p = wins / n,
        z = 1.96,
        d = 1 + z * z / n;
    final center = (p + z * z / (2 * n)) / d,
        margin = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d;
    return LearnedEdge(
      n,
      (wins + 5) / (n + 10),
      center - margin,
      center + margin,
      rs.fold(0.0, (a, b) => a + b) / (n + 10),
    );
  }
}

class WalkForwardFold {
  final int trainBars, testBars;
  final LearnedEdge training;
  final ResearchReport test;
  const WalkForwardFold(
    this.trainBars,
    this.testBars,
    this.training,
    this.test,
  );
}

class Backtester {
  /// No look-ahead: signal at t close, entry t+1 open; stop first per bar.
  static ResearchReport run(
    List<Candle> candles,
    String tf, {
    int start = 60,
    int? end,
  }) {
    final c = candles.where((e) => e.valid).toList();
    final until = math.min(end ?? c.length, c.length), results = <double>[];
    double equity = 10000, peak = 10000, maxDd = 0;
    for (var i = math.max(60, start); i < until - 1; i++) {
      final history = c.sublist(math.max(0, i - 119), i + 1);
      final a = SignalEngine.evaluate(
        'RESEARCH/USDT',
        tf,
        history,
        DateTime.fromMillisecondsSinceEpoch(
          c[i].time + intervals[tf]!,
          isUtc: true,
        ),
      );
      if (!a.tradable) continue;
      final sign = a.direction == Direction.long ? 1.0 : -1.0;
      final entry = c[i + 1].open * (1 + sign * RiskEngine.slippage);
      if ((entry - a.stop) * sign <= 0 ||
          (a.targets.first - entry) * sign <= 0) {
        continue;
      }
      final plan = TradePlan(
        key: '$i',
        exchange: 'research',
        symbol: 'RESEARCH/USDT',
        side: a.direction,
        entry: entry,
        stop: a.stop,
        targets: a.targets,
        atr: a.values['ATR']!,
        signalTime: c[i].time,
        intervalMs: intervals[tf]!,
      );
      final now = DateTime.fromMillisecondsSinceEpoch(
        c[i + 1].time,
        isUtc: true,
      );
      final q = Quote('research', 'RESEARCH/USDT', c[i + 1].open, 0, 0, now);
      final risk = RiskEngine().assess(
        plan,
        q,
        now,
        equity: equity,
        available: equity,
        openRisk: 0,
        dailyPnl: 0,
        positions: 0,
      );
      if (!risk.allowed) continue;
      final p = Position(
        id: '$i',
        exchange: 'research',
        symbol: 'RESEARCH/USDT',
        side: a.direction,
        entry: entry,
        initialQuantity: risk.quantity,
        stop: a.stop,
        targets: a.targets,
        openedAt: c[i + 1].time,
      )..open();
      var j = i + 1;
      for (; j < until && j <= i + 48 && p.active; j++) {
        final b = c[j];
        if ((b.open - p.stop) * sign <= 0) {
          p.onPrice(b.open, b.time);
        } else if ((sign > 0 ? b.low <= p.stop : b.high >= p.stop)) {
          p.onPrice(p.stop, b.time);
        } else {
          p.onPrice(sign > 0 ? b.high : b.low, b.time);
          // If breakeven was introduced within bar, conservatively revisit low/high.
          if (p.active && (sign > 0 ? b.low <= p.stop : b.high >= p.stop)) {
            p.onPrice(p.stop, b.time);
          }
        }
      }
      if (p.active) {
        p.closePart(
          '${p.id}:TIME',
          p.remaining,
          c[math.min(j - 1, until - 1)].close,
          c[math.min(j - 1, until - 1)].time,
          reason: 'TIME',
        );
      }
      results.add(p.pnl / risk.risk);
      equity += p.pnl;
      peak = math.max(peak, equity);
      maxDd = math.max(maxDd, (peak - equity) / peak);
      i = j - 1;
    }
    return ResearchReport(results, until - start, maxDd);
  }

  /// Expanding training windows; frozen strategy, training statistics never see test.
  static List<WalkForwardFold> walk(List<Candle> c, String tf) {
    final folds = <WalkForwardFold>[];
    final train = math.max(120, c.length ~/ 2),
        width = math.max(50, (c.length - train) ~/ 3);
    for (var cut = train; cut + width <= c.length; cut += width) {
      final fit = run(c.sublist(0, cut), tf);
      folds.add(
        WalkForwardFold(
          cut,
          width,
          LearnedEdge.from(fit.returns),
          run(c, tf, start: cut, end: cut + width),
        ),
      );
    }
    return folds;
  }
}
