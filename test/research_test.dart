import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_ai_trader/features/research/domain/backtest.dart';
import 'helpers/fixtures.dart';

void main() {
  test('Historical learning requires 30 outcomes and reports uncertainty', () {
    expect(LearnedEdge.from(List.filled(29, 1)).winRate, null);
    final e = LearnedEdge.from([
      ...List.filled(20, 1.0),
      ...List.filled(10, -1.0),
    ]);
    expect(e.winRate, .625);
    expect(e.low, lessThan(e.winRate!));
    expect(e.high, greaterThan(e.winRate!));
    expect(e.meanR, .25);
  });
  test(
    'Backtest deterministic, bounded results and no open tail positions',
    () {
      final c = candles(count: 300),
          a = Backtester.run(c, '1h'),
          b = Backtester.run(c, '1h');
      expect(a.returns, b.returns);
      expect(a.returns.every((r) => r.isFinite), true);
      expect(a.maxDrawdown, inInclusiveRange(0, 1));
    },
  );
  test(
    'Walk-forward folds only train before test and never exceed dataset',
    () {
      final c = candles(count: 500), folds = Backtester.walk(c, '1h');
      expect(folds, isNotEmpty);
      for (final f in folds) {
        expect(f.trainBars + f.testBars, lessThanOrEqualTo(c.length));
      }
      for (var i = 1; i < folds.length; i++) {
        expect(folds[i].trainBars, greaterThan(folds[i - 1].trainBars));
      }
    },
  );
}
