import '../../analysis/domain/analysis.dart';
import '../../market/domain/models.dart';

class TradePlan {
  final String key, exchange, symbol;
  final Direction side;
  final double entry, stop, atr, riskFraction;
  final List<double> targets;
  final int signalTime, intervalMs;
  const TradePlan({
    required this.key,
    required this.exchange,
    required this.symbol,
    required this.side,
    required this.entry,
    required this.stop,
    required this.targets,
    required this.atr,
    required this.signalTime,
    required this.intervalMs,
    this.riskFraction = .005,
  });
}

class RiskResult {
  final bool allowed;
  final String reason;
  final double quantity, risk;
  const RiskResult(
    this.allowed,
    this.reason, [
    this.quantity = 0,
    this.risk = 0,
  ]);
}

class RiskEngine {
  static const fee = .0006,
      slippage = .0004; // fee + adverse spread/slippage assumption
  RiskResult assess(
    TradePlan p,
    Quote q,
    DateTime now, {
    required double equity,
    required double available,
    required double openRisk,
    required double dailyPnl,
    required int positions,
  }) {
    RiskResult no(String s) => RiskResult(false, s);
    if (p.side == Direction.wait) return no('WAIT');
    if (q.exchange != p.exchange || q.symbol != p.symbol || !q.fresh(now)) {
      return no('stale_quote');
    }
    if (now.millisecondsSinceEpoch - p.signalTime > p.intervalMs * 2 + 30000 ||
        p.signalTime + p.intervalMs > now.millisecondsSinceEpoch) {
      return no('stale_signal');
    }
    if ([
      p.entry,
      p.stop,
      p.atr,
      p.riskFraction,
      equity,
      available,
      openRisk,
      dailyPnl,
      ...p.targets,
    ].any((e) => !e.isFinite)) {
      return no('invalid_number');
    }
    if (equity <= 0 ||
        available <= 0 ||
        p.entry <= 0 ||
        p.stop <= 0 ||
        p.atr <= 0 ||
        p.targets.length != 3) {
      return no('invalid_plan');
    }
    if (p.riskFraction <= 0 || p.riskFraction > .01) return no('risk_limit');
    if (positions >= 5) return no('position_limit');
    if (dailyPnl <= -equity * .03) return no('daily_loss_limit');
    if ((q.price - p.entry).abs() / p.entry > .005) return no('price_moved');
    final sign = p.side == Direction.long ? 1.0 : -1.0;
    final distance = (p.entry - p.stop) * sign;
    if (distance <= 0 || distance < p.atr || distance / p.entry > .08) {
      return no('invalid_stop');
    }
    double previous = p.entry;
    for (final t in p.targets) {
      if (t <= 0 || (t - previous) * sign <= 0) return no('invalid_targets');
      previous = t;
    }
    if (double.parse(
          ((p.targets.first - p.entry) * sign / distance).toStringAsFixed(2),
        ) <
        1.5) {
      return no('risk_reward');
    }
    final cost = p.entry * (2 * fee + 2 * slippage);
    if ((p.targets.first - p.entry).abs() < cost * 3) return no('cost_gate');
    final budget = equity * p.riskFraction;
    final quantity = budget / (distance + cost);
    if (quantity * p.entry * (1 + fee) > available) return no('exposure_limit');
    if (openRisk + budget > equity * .03) return no('portfolio_risk');
    return RiskResult(true, 'approved', quantity, budget);
  }
}
