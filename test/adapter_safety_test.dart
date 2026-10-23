import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:crypto_ai_trader/core/data/transport.dart';
import 'package:crypto_ai_trader/features/market/data/exchanges.dart';
import 'package:crypto_ai_trader/features/market/domain/models.dart';

void main() {
  test('Recorded LBank ISO timestamp is UTC+8, not client receipt time', () {
    final raw = jsonDecode(File('docs/LIVE_PROBE.json').readAsStringSync());
    final time = parseStreamTime(raw['LBank']['wsFrame']['TS'], lbank: true)!;
    expect(time.hour, 15);
    expect(time.isUtc, true);
    expect(parseStreamTime('invalid', lbank: true), null);
  });
  test('Explicit timestamp zone is preserved', () {
    expect(
      parseStreamTime('2026-10-02T15:00:00Z', lbank: true),
      DateTime.utc(2026, 10, 2, 15),
    );
  });
  test('LBank candles include start time and normalize seconds', () async {
    late Uri url;
    final transport = RestTransport(
      client: MockClient((r) async {
        url = r.url;
        return http.Response(
          '{"data":[[1790953200,100,102,99,101,1000]]}',
          200,
        );
      }),
    );
    final api = PublicExchange('LBank', transport: transport);
    final c = await api.candles('BTC/USDT', '1h');
    expect(url.queryParameters['time'], isNotNull);
    expect(url.queryParameters['type'], 'hour1');
    expect(c.single.time, 1790953200000);
    api.dispose();
  });
  test('No fabricated candles after malformed response', () async {
    final api = PublicExchange(
      'Toobit',
      transport: RestTransport(
        client: MockClient((r) async => http.Response('[[1,0,0,0,0,0]]', 200)),
      ),
    );
    await expectLater(
      api.candles('BTC/USDT', '1h'),
      throwsA(isA<NetworkFailure>()),
    );
    api.dispose();
  });
  test('Unverified KCEX cannot masquerade as functioning provider', () {
    expect(() => PublicExchange('KCEX'), throwsUnsupportedError);
  });
}
