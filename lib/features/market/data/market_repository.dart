import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';

class CandleBatch {
  final List<Candle> candles;
  final bool cached;
  final String? error;
  CandleBatch(this.candles, {this.cached = false, this.error});
}

class MarketRepository {
  final ExchangeGateway exchange;
  final Database db;
  MarketRepository(this.exchange, this.db);
  Future<void> _cache(String key, Object data) async {
    await db.transaction((tx) async {
      await tx.insert('cache', {
        'key': key,
        'body': jsonEncode(data),
        'time': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await tx.execute(
        'DELETE FROM cache WHERE key NOT IN (SELECT key FROM cache ORDER BY time DESC LIMIT 200)',
      );
    });
  }

  Future<dynamic> _read(String key) async {
    final r = await db.query('cache', where: 'key = ?', whereArgs: [key]);
    return r.isEmpty ? null : jsonDecode(r.first['body'] as String);
  }

  Future<List<Quote>> tickers() async {
    final key = '${exchange.id}:tickers';
    try {
      final list = await exchange.tickers();
      await _cache(key, list.map((q) => q.toJson()).toList());
      return list;
    } catch (_) {
      final raw = await _read(key);
      if (raw == null) rethrow;
      return (raw as List)
          .map(
            (m) => Quote.fromJson(Map<String, dynamic>.from(m), cached: true),
          )
          .toList();
    }
  }

  Future<CandleBatch> candles(String symbol, String tf) async {
    final key = '${exchange.id}:$symbol:$tf';
    try {
      final c = await exchange.candles(symbol, tf);
      await _cache(key, c.map((e) => e.toJson()).toList());
      return CandleBatch(c);
    } catch (e) {
      final raw = await _read(key);
      if (raw == null) rethrow;
      return CandleBatch(
        (raw as List).map((r) => Candle.fromJson(r)).toList(),
        cached: true,
        error: 'offline_cache',
      );
    }
  }
}
