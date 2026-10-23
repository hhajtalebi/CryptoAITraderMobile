import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_ai_trader/features/analysis/domain/analysis.dart';
import 'package:crypto_ai_trader/features/trading/domain/risk.dart';
import 'package:crypto_ai_trader/features/trading/domain/position.dart';
import 'helpers/fixtures.dart';

void main() {
  RiskResult assess(
    TradePlan p, {
    double equity = 10000,
    double available = 10000,
    double openRisk = 0,
    double daily = 0,
    int positions = 0,
  }) => RiskEngine().assess(
    p,
    quote(),
    now,
    equity: equity,
    available: available,
    openRisk: openRisk,
    dailyPnl: daily,
    positions: positions,
  );
  test('Risk sizing includes costs and respects budget', () {
    final r = assess(plan());
    expect(r.allowed, true);
    expect(r.quantity * (4 + 100 * .002), closeTo(50, 1e-8));
  });
  test('WAIT, NaN, bad targets, stop direction and ATR rejected', () {
    for (final p in [
      plan(side: Direction.wait),
      plan(entry: double.nan),
      plan(stop: 105),
      plan(stop: 99.5, atr: 1),
      plan(targets: [107, 106, 108]),
      plan(targets: [101, 104, 108]),
      plan(risk: .02),
    ]) {
      expect(assess(p).allowed, false);
    }
  });
  test('Daily loss, position limit, exposure and aggregate risk gates', () {
    expect(assess(plan(), daily: -400).reason, 'daily_loss_limit');
    expect(assess(plan(), positions: 5).reason, 'position_limit');
    expect(assess(plan(), available: 50).reason, 'exposure_limit');
    expect(assess(plan(), openRisk: 280).reason, 'portfolio_risk');
  });
  test('Cached and future/stale quotes rejected', () {
    for (final q in [
      quote(cached: true),
      quote(time: now.subtract(const Duration(minutes: 2))),
      quote(time: now.add(const Duration(minutes: 1))),
    ]) {
      expect(
        RiskEngine()
            .assess(
              plan(),
              q,
              now,
              equity: 10000,
              available: 10000,
              openRisk: 0,
              dailyPnl: 0,
              positions: 0,
            )
            .allowed,
        false,
      );
    }
  });
  test('Order state starts pending and cannot double-open', () {
    final p = position();
    expect(p.state, PositionState.pending);
    p.open();
    expect(p.state, PositionState.open);
    expect(p.open, throwsStateError);
  });
  test('TP1/2/3 close original thirds; stop moves after TP1', () {
    final p = position()..open();
    expect(p.onPrice(108, 1).single.reason, 'TP1');
    expect(p.remaining, 2);
    expect(p.stop, 100);
    expect(p.state, PositionState.partiallyClosed);
    expect(p.onPrice(108, 2), isEmpty);
    expect(p.onPrice(114, 3).single.reason, 'TP2');
    expect(p.remaining, 1);
    expect(p.onPrice(120, 4).single.reason, 'TP3');
    expect(p.state, PositionState.closed);
    expect(p.remaining, 0);
    expect(p.onPrice(120, 5), isEmpty);
  });
  test('Gap across all targets executes once each', () {
    final p = position()..open();
    expect(p.onPrice(130, 1).map((e) => e.reason), ['TP1', 'TP2', 'TP3']);
    expect(p.onPrice(130, 2), isEmpty);
  });
  test('SL gap fills at worse observed price, duplicate SL ignored', () {
    final p = position()..open();
    final f = p.onPrice(90, 1).single;
    expect(f.reason, 'SL');
    expect(f.price, lessThan(90));
    expect(p.pnl, lessThan(-30));
    expect(p.onPrice(90, 2), isEmpty);
  });
  test('Breakeven still charges costs', () {
    final p = position()..open();
    p.onPrice(108, 1);
    final f = p.onPrice(100, 2).single;
    expect(f.pnl, lessThan(0));
    expect(p.state, PositionState.closed);
  });
  test('Manual partial cannot execute duplicate or over-close', () {
    final p = position()..open();
    p.closePart('manual', 1.5, 101, 1);
    expect(p.remaining, 1.5);
    expect(p.closePart('manual', 1.5, 101, 1), null);
    expect(() => p.closePart('bad', 2, 101, 1), throwsArgumentError);
    p.onPrice(120, 2);
    expect(p.remaining, 0);
  });
  test('Short targets and short stop mirror long', () {
    final p = position(side: Direction.short)..open();
    expect(p.onPrice(92, 1).single.reason, 'TP1');
    expect(p.stop, 100);
    expect(p.onPrice(100, 2).single.reason, 'SL');
    final s = position(side: Direction.short)..open();
    expect(s.onPrice(75, 3).length, 3);
    expect(s.pnl, greaterThan(0));
  });
  test('Position serialization preserves event idempotency', () {
    final p = position()..open();
    p.onPrice(108, 1);
    final r = Position.fromJson(p.toJson());
    expect(r.onPrice(108, 2), isEmpty);
    expect(r.remaining, 2);
    expect(r.targetIndex, 1);
  });
}
