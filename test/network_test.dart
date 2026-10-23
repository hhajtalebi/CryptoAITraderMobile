import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:crypto_ai_trader/core/data/transport.dart';

void main() {
  test('429 respects cooldown, never retries storm', () async {
    var calls = 0;
    final t = RestTransport(
      client: MockClient((r) async {
        calls++;
        return http.Response('{}', 429, headers: {'retry-after': '20'});
      }),
    );
    await expectLater(
      t.get(Uri.parse('https://test.invalid')),
      throwsA(isA<NetworkFailure>()),
    );
    await expectLater(
      t.get(Uri.parse('https://test.invalid')),
      throwsA(isA<NetworkFailure>()),
    );
    expect(calls, 1);
    t.dispose();
  });
  test('LBank 10004 is rate limiting', () async {
    final t = RestTransport(
      client: MockClient(
        (r) async => http.Response('{"error_code":10004}', 200),
      ),
    );
    await expectLater(
      t.get(Uri.parse('https://test.invalid')),
      throwsA(
        isA<NetworkFailure>().having((e) => e.code, 'code', 'rate_limited'),
      ),
    );
    expect(t.cooldown, isNotNull);
    t.dispose();
  });
  test('403 and malformed JSON fail closed', () async {
    for (final response in [
      http.Response('{}', 403),
      http.Response('not JSON', 200),
    ]) {
      final t = RestTransport(client: MockClient((r) async => response));
      await expectLater(
        t.get(Uri.parse('https://test.invalid')),
        throwsA(isA<NetworkFailure>()),
      );
      t.dispose();
    }
  });
  test('Timeout bounded to three attempts', () async {
    var calls = 0;
    final t = RestTransport(
      timeout: const Duration(milliseconds: 5),
      client: MockClient((r) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      t.get(Uri.parse('https://test.invalid')),
      throwsA(isA<NetworkFailure>()),
    );
    expect(calls, 3);
    t.dispose();
  });
  test('Reconnect resubscribes, handles heartbeat and disposal', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    int subscriptions = 0, pongs = 0;
    final ready = Completer<void>();
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      sockets.add(ws);
      ws.listen((raw) {
        final m = jsonDecode(raw as String);
        if (m['action'] == 'subscribe') {
          subscriptions++;
          ws.add(jsonEncode({'action': 'ping', 'ping': 'alive'}));
          if (subscriptions == 1) {
            Timer(const Duration(milliseconds: 10), () => ws.close());
          } else {
            if (!ready.isCompleted) ready.complete();
          }
        }
        if (m['action'] == 'pong') pongs++;
      });
    });
    final socket = ResilientSocket(
      url: 'ws://127.0.0.1:${server.port}',
      subscriptions: [
        {'action': 'subscribe'},
      ],
      onMessage: (_) {},
      onStatus: (_) {},
      baseDelay: const Duration(milliseconds: 10),
    );
    await socket.start();
    await ready.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(subscriptions, 2);
    expect(pongs, greaterThanOrEqualTo(1));
    socket.dispose();
    for (final ws in sockets) {
      await ws.close();
    }
    await server.close(force: true);
    final n = subscriptions;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(subscriptions, n);
  });
  test(
    'Initial connection failure retries and disposal cancels pending retry',
    () async {
      var calls = 0;
      final got = Completer<void>();
      final socket = ResilientSocket(
        url: 'ws://test.invalid',
        subscriptions: [],
        onMessage: (_) {},
        onStatus: (_) {},
        baseDelay: const Duration(milliseconds: 5),
        connect: (url) async {
          calls++;
          if (calls == 3) got.complete();
          throw const SocketException('offline');
        },
      );
      await socket.start();
      await got.future.timeout(const Duration(seconds: 2));
      socket.dispose();
      final n = calls;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(calls, n);
    },
  );
}
