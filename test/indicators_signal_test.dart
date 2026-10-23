import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_ai_trader/features/analysis/domain/indicators.dart';
import 'package:crypto_ai_trader/features/analysis/domain/analysis.dart';
import 'package:crypto_ai_trader/features/market/domain/models.dart';
import 'helpers/fixtures.dart';

void main() {
  test('SMA/EMA known sequence and warmup', () {
    final a = <double>[1, 2, 3, 4, 5];
    expect(Indicators.sma(a, 3).last, 4);
    expect(Indicators.ema(a, 3), [isNaN, isNaN, 2, 3, 4]);
  });
  test('RSI rising, falling, flat are 100, 0, 50', () {
    expect(Indicators.rsi(List.generate(30, (i) => i.toDouble())).last, 100);
    expect(Indicators.rsi(List.generate(30, (i) => 30 - i.toDouble())).last, 0);
    expect(Indicators.rsi(List.filled(30, 5)).last, 50);
  });
  test(
    'All ten indicator families finite after warmup; flat no division crash',
    () {
      for (final flat in [true, false]) {
        final v = Indicators.all(candles(flat: flat));
        for (final e in v.entries) {
          if (e.key == 'VWAP' && flat) {
            expect(e.value.last, isNaN);
          } else {
            expect(e.value.last.isFinite, true, reason: e.key);
          }
        }
      }
    },
  );
  test('ATR and Bollinger flat are well defined', () {
    final v = Indicators.all(candles(flat: true));
    expect(v['ATR']!.last, 0);
    expect(v['BB upper']!.last, 100);
    expect(v['BB lower']!.last, 100);
    expect(v['Stoch K']!.last, 50);
  });
  test('Insufficient data and zero volume stay WAIT', () {
    expect(
      SignalEngine.evaluate(
        'BTC/USDT',
        '1h',
        candles(count: 20),
        now,
      ).direction,
      Direction.wait,
    );
    expect(
      SignalEngine.evaluate(
        'BTC/USDT',
        '1h',
        candles(flat: true),
        now,
      ).direction,
      Direction.wait,
    );
  });
  test('Forming candle cannot repaint signal', () {
    final c = candles(), a = SignalEngine.evaluate('BTC/USDT', '1h', c, now);
    c.add(Candle(now.millisecondsSinceEpoch, 110, 10000, 1, 9999, 100000));
    final b = SignalEngine.evaluate('BTC/USDT', '1h', c, now);
    expect(a.direction, b.direction);
    expect(a.confidence, b.confidence);
    expect(a.entry, b.entry);
  });
  test('Gapped candles and stale snapshots cannot trade', () {
    final c = candles()..removeAt(65);
    expect(
      SignalEngine.evaluate('BTC/USDT', '1h', c, now).reason,
      'candle_gap',
    );
    expect(
      SignalEngine.evaluate(
        'BTC/USDT',
        '1h',
        candles(),
        now.add(const Duration(days: 1)),
      ).reason,
      'stale',
    );
  });
  test('Both long and short decisions supported, symmetric structure', () {
    final up = SignalEngine.evaluate('BTC/USDT', '1h', candles(), now),
        down = SignalEngine.evaluate(
          'BTC/USDT',
          '1h',
          candles(down: true),
          now,
        );
    expect(up.direction, Direction.long);
    expect(down.direction, Direction.short);
    expect(up.stop, lessThan(up.entry));
    expect(down.stop, greaterThan(down.entry));
  });
  test('Higher timeframe conflict produces WAIT', () {
    final up = SignalEngine.evaluate(
      'BTC/USDT',
      '1h',
      candles(),
      now,
      higher: candles(down: true),
      higherMs: 3600000,
    );
    expect(up.direction, Direction.wait);
    expect(up.reason, 'mtf_conflict');
  });
}
