import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    return f.openDatabase(
      path ?? p.join(await f.getDatabasesPath(), 'crypto_mobile_v1.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE positions(id TEXT PRIMARY KEY, body TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE orders(id TEXT PRIMARY KEY, state TEXT NOT NULL, created INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE events(id TEXT PRIMARY KEY, position_id TEXT NOT NULL REFERENCES positions(id), time INTEGER NOT NULL, pnl REAL NOT NULL, body TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE cache(key TEXT PRIMARY KEY, body TEXT NOT NULL, time INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE preferences(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
        },
      ),
    );
  }
}
