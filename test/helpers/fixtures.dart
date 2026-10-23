// Deterministic synthetic inputs used ONLY in tests; never bundled into the app.
import 'package:crypto_ai_trader/features/market/domain/models.dart';
import 'package:crypto_ai_trader/features/analysis/domain/analysis.dart';
import 'package:crypto_ai_trader/features/trading/domain/risk.dart';
import 'package:crypto_ai_trader/features/trading/domain/position.dart';

final now = DateTime.utc(2026, 10, 2, 15);
List<Candle> candles({int count = 100, bool flat = false, bool down = false}) =>
    List.generate(count, (i) {
      final p = flat ? 100.0 : 100.0 + (down ? -1 : 1) * i * .1;
      return Candle(
        now.millisecondsSinceEpoch - (count - i) * 3600000,
        p,
        p + (flat ? 0 : .4),
        p - (flat ? 0 : .4),
        p + (flat ? 0 : (down ? -.05 : .05)),
        flat ? 0 : 100 + i.toDouble(),
      );
    });
Quote quote({
  double price = 100,
  DateTime? time,
  bool cached = false,
  String symbol = 'BTC/USDT',
}) => Quote('Toobit', symbol, price, 1, 10000, time ?? now, cached: cached);
TradePlan plan({
  String key = 'test',
  Direction side = Direction.long,
  double entry = 100,
  double stop = 96,
  List<double> targets = const [107, 111, 117],
  double atr = 1,
  double risk = .005,
  String symbol = 'BTC/USDT',
}) => TradePlan(
  key: key,
  exchange: 'Toobit',
  symbol: symbol,
  side: side,
  entry: entry,
  stop: stop,
  targets: targets,
  atr: atr,
  signalTime: now.millisecondsSinceEpoch - 3600000,
  intervalMs: 3600000,
  riskFraction: risk,
);
Position position({Direction side = Direction.long}) => Position(
  id: 'p',
  exchange: 'Toobit',
  symbol: 'BTC/USDT',
  side: side,
  entry: 100,
  initialQuantity: 3,
  stop: side == Direction.long ? 95 : 105,
  targets: side == Direction.long ? [108, 114, 120] : [92, 86, 80],
  openedAt: now.millisecondsSinceEpoch,
);
