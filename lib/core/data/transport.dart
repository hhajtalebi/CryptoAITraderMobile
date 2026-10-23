import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:http/http.dart' as http;

class NetworkFailure implements Exception {
  final String code;
  const NetworkFailure(this.code);
  @override
  String toString() => code;
}

class RestTransport {
  final http.Client client;
  final Duration timeout;
  DateTime? cooldown;
  RestTransport({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : client = client ?? http.Client();
  Future<dynamic> get(Uri uri) async {
    if (cooldown != null && DateTime.now().isBefore(cooldown!)) {
      throw const NetworkFailure('rate_limited');
    }
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await client.get(uri).timeout(timeout);
        if (r.statusCode == 429 || r.statusCode == 418) {
          final seconds = int.tryParse(r.headers['retry-after'] ?? '');
          DateTime? date;
          if (seconds == null) {
            try {
              date = HttpDate.parse(r.headers['retry-after'] ?? '');
            } catch (_) {}
          }
          cooldown =
              date ??
              DateTime.now().add(
                Duration(seconds: (seconds ?? 30).clamp(1, 3600)),
              );
          throw const NetworkFailure('rate_limited');
        }
        if (r.statusCode == 403) {
          throw const NetworkFailure('region_or_access_blocked');
        }
        if (r.statusCode >= 500) {
          throw const NetworkFailure('server_unavailable');
        }
        if (r.statusCode != 200) throw NetworkFailure('http_${r.statusCode}');
        final text = r.body;
        final body = await Isolate.run(() => jsonDecode(text));
        if (body is Map && '${body['error_code']}' == '10004') {
          cooldown = DateTime.now().add(const Duration(seconds: 30));
          throw const NetworkFailure('rate_limited');
        }
        return body;
      } on NetworkFailure catch (e) {
        if (e.code != 'server_unavailable' || attempt == 2) rethrow;
      } on FormatException {
        throw const NetworkFailure('invalid_response');
      } on Exception {
        if (attempt == 2) throw const NetworkFailure('network_unavailable');
      }
      await Future<void>.delayed(
        Duration(milliseconds: 400 * (1 << attempt) + Random().nextInt(200)),
      );
    }
    throw const NetworkFailure('network_unavailable');
  }

  void dispose() => client.close();
}

/// Socket factory is injectable for deterministic reconnect tests, not fake production data.
typedef SocketFactory = Future<WebSocket> Function(String url);

class ResilientSocket {
  final String url;
  final List<Map<String, dynamic>> subscriptions;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function(String) onStatus;
  final SocketFactory connect;
  final Duration baseDelay, heartbeat, staleAfter;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry, _heartbeat;
  bool _disposed = false, _connecting = false;
  int _attempt = 0, _generation = 0;
  DateTime _last = DateTime.now();
  ResilientSocket({
    required this.url,
    required this.subscriptions,
    required this.onMessage,
    required this.onStatus,
    SocketFactory? connect,
    this.baseDelay = const Duration(seconds: 1),
    this.heartbeat = const Duration(seconds: 20),
    this.staleAfter = const Duration(seconds: 60),
  }) : connect =
           connect ??
           ((url) =>
               WebSocket.connect(url).timeout(const Duration(seconds: 12)));
  Future<void> start() async {
    if (_disposed || _connecting || _socket != null) return;
    _retry?.cancel();
    _connecting = true;
    final generation = ++_generation;
    onStatus(_attempt == 0 ? 'connecting' : 'reconnecting');
    try {
      final socket = await connect(url);
      if (_disposed || generation != _generation) {
        await socket.close();
        return;
      }
      _socket = socket;
      _last = DateTime.now();
      socket.pingInterval = heartbeat;
      for (final m in subscriptions) {
        socket.add(jsonEncode(m));
      }
      _subscription = socket.listen(
        (raw) {
          if (_disposed) return;
          _last = DateTime.now();
          _attempt = 0;
          try {
            final data = jsonDecode(
              raw is String ? raw : utf8.decode(raw as List<int>),
            );
            if (data is! Map) return;
            final m = Map<String, dynamic>.from(data);
            if (m['action'] == 'ping') {
              socket.add(jsonEncode({'action': 'pong', 'pong': m['ping']}));
              return;
            }
            if (m.containsKey('ping')) {
              socket.add(jsonEncode({'pong': m['ping']}));
              return;
            }
            onMessage(m);
            onStatus('streaming');
          } catch (_) {
            /* Malformed frame ignored, no payload/secret logs. */
          }
        },
        onError: (Object e) => _lost(),
        onDone: _lost,
        cancelOnError: true,
      );
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(heartbeat, (_) {
        if (DateTime.now().difference(_last) > staleAfter) _lost();
      });
      onStatus('connected');
    } catch (_) {
      _schedule();
    } finally {
      _connecting = false;
    }
  }

  void _lost() {
    if (_disposed) return;
    _subscription?.cancel();
    _subscription = null;
    _heartbeat?.cancel();
    _socket?.close();
    _socket = null;
    _schedule();
  }

  void _schedule() {
    if (_disposed || (_retry?.isActive ?? false)) return;
    onStatus('reconnecting');
    final delay = min(
      30000,
      baseDelay.inMilliseconds * (1 << min(_attempt++, 5)),
    );
    _retry = Timer(
      Duration(milliseconds: delay + Random().nextInt(max(1, delay ~/ 4))),
      () {
        start();
      },
    );
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _retry?.cancel();
    _heartbeat?.cancel();
    _subscription?.cancel();
    _socket?.close();
    _socket = null;
  }
}
