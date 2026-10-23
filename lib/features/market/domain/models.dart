class Candle {
  final int time; // UTC milliseconds, opening time
  final double open, high, low, close, volume;
  const Candle(
    this.time,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
  );
  bool get valid =>
      time > 0 &&
      [open, high, low, close, volume].every((v) => v.isFinite) &&
      low > 0 &&
      high >= low &&
      high >= open &&
      high >= close &&
      low <= open &&
      low <= close &&
      volume >= 0;
  List<num> toJson() => [time, open, high, low, close, volume];
  factory Candle.fromJson(List<dynamic> a) => Candle(
    (a[0] as num).toInt(),
    number(a[1]),
    number(a[2]),
    number(a[3]),
    number(a[4]),
    number(a[5]),
  );
}

double number(Object? value) => double.tryParse('$value') ?? double.nan;

class Quote {
  final String exchange, symbol;
  final double price, change, volume;
  final DateTime time;
  final bool cached;
  const Quote(
    this.exchange,
    this.symbol,
    this.price,
    this.change,
    this.volume,
    this.time, {
    this.cached = false,
  });
  bool fresh(DateTime now) =>
      !cached &&
      price.isFinite &&
      price > 0 &&
      now.difference(time).inSeconds >= -5 &&
      now.difference(time).inSeconds <= 30;
  Map<String, dynamic> toJson() => {
    'exchange': exchange,
    'symbol': symbol,
    'price': price,
    'change': change,
    'volume': volume,
    'time': time.millisecondsSinceEpoch,
  };
  factory Quote.fromJson(Map<String, dynamic> m, {bool cached = false}) =>
      Quote(
        m['exchange'],
        m['symbol'],
        number(m['price']),
        number(m['change']),
        number(m['volume']),
        DateTime.fromMillisecondsSinceEpoch(m['time'], isUtc: true),
        cached: cached,
      );
}

const intervals = {
  '5m': 300000,
  '15m': 900000,
  '1h': 3600000,
  '4h': 14400000,
  '1d': 86400000,
  '1w': 604800000,
};

abstract interface class ExchangeGateway {
  String get id;
  Future<List<Quote>> tickers();
  Future<List<Candle>> candles(String symbol, String interval);
  void dispose();
}

/// LBank's zone-less WS TS is UTC+8 (verified against REST epoch in probe).
/// Never relabel receipt time as exchange time; unknown timestamps are rejected.
DateTime? parseStreamTime(Object? raw, {bool lbank = false}) {
  final epoch = double.tryParse('$raw');
  if (epoch != null && epoch.isFinite && epoch > 0) {
    return DateTime.fromMillisecondsSinceEpoch(epoch.toInt(), isUtc: true);
  }
  if (raw is! String) return null;
  var text = raw;
  if (lbank &&
      !text.endsWith('Z') &&
      !RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(text)) {
    text = '$text+08:00';
  }
  return DateTime.tryParse(text)?.toUtc();
}
