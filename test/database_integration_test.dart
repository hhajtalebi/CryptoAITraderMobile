import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto_ai_trader/core/data/database.dart';
import 'package:crypto_ai_trader/features/trading/data/paper_repository.dart';
import 'package:crypto_ai_trader/features/trading/domain/position.dart';
import 'package:crypto_ai_trader/features/market/data/market_repository.dart';
import 'package:crypto_ai_trader/features/market/domain/models.dart';
import 'helpers/fixtures.dart';

class FixtureGateway implements ExchangeGateway {
  bool fail = false;
  @override
  String get id => 'Toobit';
  @override
  Future<List<Quote>> tickers() async {
    if (fail) throw const SocketException('test outage');
    return [quote()];
  }

  @override
  Future<List<Candle>> candles(String symbol, String interval) async {
    if (fail) throw const SocketException('test outage');
    return List.generate(
      3,
      (i) => Candle(
        now.millisecondsSinceEpoch - i * 3600000,
        100,
        101,
        99,
        100,
        10,
      ),
    );
  }

  @override
  void dispose() {}
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late PaperRepository repo;
  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repo = PaperRepository(db);
  });
  tearDown(() async {
    await db.close();
  });
  test(
    'Concurrent duplicate orders execute once, persist OPEN state',
    () async {
      final p = await Future.wait(
        List.generate(8, (_) => repo.submit(plan(), quote(), now)),
      );
      expect(p.map((e) => e.id).toSet().length, 1);
      expect((await repo.positions()).length, 1);
      expect((await repo.history()).length, 1);
      expect((await db.query('orders')).single['state'], 'open');
    },
  );
  test('Risk failure rolls back order, position and ledger', () async {
    await expectLater(
      repo.submit(plan(stop: 105), quote(), now),
      throwsStateError,
    );
    expect(await db.query('orders'), isEmpty);
    expect(await repo.positions(), isEmpty);
    expect(await repo.history(), isEmpty);
  });
  test(
    'TP across concurrent quotes recorded exactly once; SL cannot reclose',
    () async {
      await repo.submit(plan(), quote(), now);
      await Future.wait(
        List.generate(6, (_) => repo.mark(quote(price: 120), now)),
      );
      final p = (await repo.positions()).single;
      expect(p.state, PositionState.closed);
      expect((await repo.history()).length, 4);
      await repo.mark(quote(price: 80), now);
      expect((await repo.history()).length, 4);
      expect((await db.query('orders')).single['state'], 'closed');
    },
  );
  test('Out-of-order source quote cannot trigger a retroactive SL', () async {
    await repo.submit(plan(), quote(), now);
    final current = now.add(const Duration(seconds: 10));
    await repo.mark(quote(price: 108, time: current), current);
    final before = (await repo.history()).length;
    await repo.mark(
      quote(price: 90, time: now.add(const Duration(seconds: 5))),
      current,
    );
    expect((await repo.history()).length, before);
    expect((await repo.positions()).single.active, true);
  });
  test('Stale data cannot close positions', () async {
    await repo.submit(plan(), quote(), now);
    expect(await repo.mark(quote(price: 90, cached: true), now), 0);
    expect((await repo.positions()).single.active, true);
  });
  test('Partial-close idempotency survives repository recreation', () async {
    final p = await repo.submit(plan(), quote(), now);
    await repo.close(p.id, 'tap', .5, quote(price: 101), now);
    final fresh = PaperRepository(db);
    await fresh.close(p.id, 'tap', .5, quote(price: 101), now);
    expect(
      (await fresh.positions()).single.remaining,
      closeTo(p.initialQuantity / 2, 1e-8),
    );
    expect((await fresh.history()).length, 2);
  });
  test(
    'Offline cache survives network failure; cached quote not tradable',
    () async {
      final gateway = FixtureGateway(), market = MarketRepository(gateway, db);
      await market.tickers();
      await market.candles('BTC/USDT', '1h');
      gateway.fail = true;
      final q = (await market.tickers()).single;
      expect(q.cached, true);
      expect(q.fresh(now), false);
      expect((await market.candles('BTC/USDT', '1h')).cached, true);
    },
  );
  test('Restart reopens on-disk SQLite without losing events', () async {
    final dir = await Directory.systemTemp.createTemp('cai-test-');
    final path = '${dir.path}/paper.db';
    var disk = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    var r = PaperRepository(disk);
    await r.submit(plan(), quote(), now);
    await disk.close();
    disk = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
    r = PaperRepository(disk);
    await r.submit(plan(), quote(), now);
    expect((await r.positions()).length, 1);
    expect((await r.history()).length, 1);
    await disk.close();
    await dir.delete(recursive: true);
  });
}
