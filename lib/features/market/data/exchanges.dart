import '../../../core/data/transport.dart';
import '../domain/models.dart';

class PublicExchange implements ExchangeGateway {
  @override
  final String id;
  final RestTransport transport;
  PublicExchange(this.id, {RestTransport? transport})
    : transport = transport ?? RestTransport() {
    if (!['Toobit', 'LBank'].contains(id)) {
      throw UnsupportedError('Exchange API not verified');
    }
  }
  String get base =>
      id == 'Toobit' ? 'https://api.toobit.com' : 'https://api.lbkex.com';
  String wire(String symbol) => id == 'Toobit'
      ? symbol.replaceAll('/', '')
      : symbol.toLowerCase().replaceAll('/', '_');
  @override
  Future<List<Quote>> tickers() async {
    final data = await transport.get(
      Uri.parse(
        '$base${id == 'Toobit' ? '/quote/v1/ticker/24hr' : '/v2/ticker/24hr.do?symbol=all'}',
      ),
    );
    final list = id == 'Toobit' ? data : data['data'];
    if (list is! List) throw const NetworkFailure('exchange_rejected_request');
    final out = <Quote>[];
    for (final r in list) {
      try {
        final symbol = id == 'Toobit' ? '${r['s']}' : '${r['symbol']}';
        if (!(id == 'Toobit'
            ? symbol.endsWith('USDT')
            : symbol.endsWith('_usdt'))) {
          continue;
        }
        final t = id == 'Toobit' ? r : r['ticker'];
        final q = Quote(
          id,
          id == 'Toobit'
              ? '${symbol.substring(0, symbol.length - 4)}/USDT'
              : symbol.replaceAll('_', '/').toUpperCase(),
          number(t[id == 'Toobit' ? 'c' : 'latest']),
          number(t[id == 'Toobit' ? 'pcp' : 'change']) *
              (id == 'Toobit' ? 100 : 1),
          number(t[id == 'Toobit' ? 'qv' : 'turnover']),
          DateTime.fromMillisecondsSinceEpoch(
            number(r[id == 'Toobit' ? 't' : 'timestamp']).toInt(),
            isUtc: true,
          ),
        );
        if (q.price.isFinite &&
            q.price > 0 &&
            q.volume.isFinite &&
            q.change.isFinite) {
          out.add(q);
        }
      } catch (_) {
        continue;
      }
    }
    if (out.isEmpty) throw const NetworkFailure('empty_market');
    out.sort((a, b) => b.volume.compareTo(a.volume));
    return out;
  }

  @override
  Future<List<Candle>> candles(String symbol, String interval) async {
    const lb = {
      '5m': 'minute5',
      '15m': 'minute15',
      '1h': 'hour1',
      '4h': 'hour4',
      '1d': 'day1',
      '1w': 'week1',
    };
    final uri =
        Uri.parse(
          '$base${id == 'Toobit' ? '/quote/v1/klines' : '/v2/kline.do'}',
        ).replace(
          queryParameters: id == 'Toobit'
              ? {'symbol': wire(symbol), 'interval': interval, 'limit': '500'}
              : {
                  'symbol': wire(symbol),
                  'type': lb[interval]!,
                  'size': '500',
                  'time':
                      '${(DateTime.now().millisecondsSinceEpoch - 500 * intervals[interval]!) ~/ 1000}',
                },
        );
    final data = await transport.get(uri);
    final list = id == 'Toobit' ? data : data['data'];
    if (list is! List) throw const NetworkFailure('candles_unavailable');
    final map = <int, Candle>{};
    for (final row in list) {
      try {
        final raw = List<dynamic>.from(row);
        raw[0] = number(raw[0]).toInt() * (id == 'LBank' ? 1000 : 1);
        final c = Candle.fromJson(raw);
        if (c.valid) map[c.time] = c;
      } catch (_) {
        continue;
      }
    }
    final out = map.values.toList()..sort((a, b) => a.time.compareTo(b.time));
    if (out.isEmpty) throw const NetworkFailure('empty_candles');
    return out;
  }

  @override
  void dispose() => transport.dispose();
}
