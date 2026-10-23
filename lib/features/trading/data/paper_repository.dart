import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../market/domain/models.dart';
import '../../analysis/domain/analysis.dart';
import '../domain/position.dart';
import '../domain/risk.dart';

/// Single SQLite transaction for risk, idempotency, balances and execution.
class PaperRepository {
  final Database db;
  static const startingBalance = 10000.0;
  PaperRepository(this.db);
  Future<List<Position>> _list(DatabaseExecutor tx) async => (await tx.query(
    'positions',
  )).map((r) => Position.fromJson(jsonDecode(r['body'] as String))).toList();
  Future<List<Position>> positions() => _list(db);
  Future<void> _save(DatabaseExecutor tx, Position p) async {
    await tx.insert('positions', {
      'id': p.id,
      'body': jsonEncode(p.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await tx.update(
      'orders',
      {'state': p.state.name},
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> _fill(DatabaseExecutor tx, Position p, Fill f) async {
    await tx.insert('events', {
      'id': f.key,
      'position_id': p.id,
      'time': f.time,
      'pnl': f.pnl,
      'body': jsonEncode(f.toJson()),
    });
  }

  Future<Position> submit(
    TradePlan plan,
    Quote quote,
    DateTime now, {
    Map<String, Quote> marks = const {},
  }) => db.transaction((tx) async {
    final id = '${plan.exchange}:${plan.key}';
    final rows = await tx.query('positions', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      return Position.fromJson(jsonDecode(rows.first['body'] as String));
    }
    final list = await _list(tx), active = list.where((p) => p.active).toList();
    if (active.any(
      (p) => p.exchange == plan.exchange && p.symbol == plan.symbol,
    )) {
      throw StateError('symbol_already_open');
    }
    double openLoss = 0;
    for (final p in active) {
      final mark = marks[p.symbol];
      if (mark == null || mark.exchange != p.exchange || !mark.fresh(now)) {
        throw StateError('stale_quote');
      }
      final floating = p.unrealized(mark.price);
      if (floating < 0) {
        openLoss += floating; // Do not reuse unrealized gains as collateral.
      }
    }
    final equity =
        startingBalance + list.fold<double>(0, (s, p) => s + p.pnl) + openLoss;
    final reserved = active.fold<double>(0, (s, p) => s + p.reserved);
    final day = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final daily =
        (await tx.rawQuery(
              'SELECT COALESCE(SUM(pnl),0) AS total FROM events WHERE time >= ?',
              [day],
            )).first['total']
            as num;
    final result = RiskEngine().assess(
      plan,
      quote,
      now,
      equity: equity,
      available: equity - reserved,
      openRisk: active.fold(0.0, (s, p) => s + p.risk),
      dailyPnl: daily.toDouble(),
      positions: active.length,
    );
    if (!result.allowed) throw StateError(result.reason);
    final sign = plan.side == Direction.long ? 1.0 : -1.0;
    final entry = quote.price * (1 + sign * RiskEngine.slippage);
    // Revalidate at actual simulated fill; do not silently bypass RR after drift.
    final actual = TradePlan(
      key: plan.key,
      exchange: plan.exchange,
      symbol: plan.symbol,
      side: plan.side,
      entry: entry,
      stop: plan.stop,
      targets: plan.targets,
      atr: plan.atr,
      signalTime: plan.signalTime,
      intervalMs: plan.intervalMs,
      riskFraction: plan.riskFraction,
    );
    final checked = RiskEngine().assess(
      actual,
      quote,
      now,
      equity: equity,
      available: equity - reserved,
      openRisk: active.fold(0.0, (s, p) => s + p.risk),
      dailyPnl: daily.toDouble(),
      positions: active.length,
    );
    if (!checked.allowed) throw StateError(checked.reason);
    await tx.insert('orders', {
      'id': id,
      'state': 'pending',
      'created': now.millisecondsSinceEpoch,
    });
    final p = Position(
      id: id,
      exchange: plan.exchange,
      symbol: plan.symbol,
      side: plan.side,
      entry: entry,
      initialQuantity: checked.quantity,
      stop: plan.stop,
      targets: plan.targets,
      openedAt: now.millisecondsSinceEpoch,
    );
    p.open();
    await _save(tx, p);
    await _fill(
      tx,
      p,
      Fill(
        '$id:ENTRY',
        'ENTRY',
        p.initialQuantity,
        entry,
        p.pnl,
        now.millisecondsSinceEpoch,
      ),
    );
    return p;
  });
  Future<int> mark(Quote q, DateTime now) => db.transaction((tx) async {
    if (!q.fresh(now)) return 0;
    var count = 0;
    for (final p in await _list(tx)) {
      if (!p.active ||
          p.symbol != q.symbol ||
          p.exchange != q.exchange ||
          q.time.millisecondsSinceEpoch < p.openedAt ||
          q.time.millisecondsSinceEpoch <= p.lastMarkTime) {
        continue;
      }
      p.lastMarkTime = q.time.millisecondsSinceEpoch;
      final fills = p.onPrice(q.price, now.millisecondsSinceEpoch);
      await _save(tx, p);
      if (fills.isNotEmpty) {
        for (final f in fills) {
          await _fill(tx, p, f);
          count++;
        }
      }
    }
    return count;
  });
  Future<void> close(
    String id,
    String eventKey,
    double fraction,
    Quote q,
    DateTime now,
  ) => db.transaction((tx) async {
    if (!q.fresh(now)) throw StateError('stale_quote');
    if (!fraction.isFinite || fraction <= 0 || fraction > 1) {
      throw ArgumentError('fraction');
    }
    final row = (await tx.query(
      'positions',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    final p = Position.fromJson(jsonDecode(row['body'] as String));
    if (q.exchange != p.exchange || q.symbol != p.symbol) {
      throw StateError('wrong_market');
    }
    final f = p.closePart(
      '$id:$eventKey',
      p.remaining * fraction,
      q.price,
      now.millisecondsSinceEpoch,
    );
    if (f != null) {
      await _save(tx, p);
      await _fill(tx, p, f);
    }
  });
  Future<List<Map<String, Object?>>> history() =>
      db.query('events', orderBy: 'time DESC', limit: 200);
}
