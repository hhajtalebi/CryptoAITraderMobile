import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../features/trading/data/paper_repository.dart';
import '../features/trading/domain/position.dart';
import 'data/secure_vault.dart';

final databaseProvider = Provider<Database>(
  (ref) => throw StateError('Database not initialized'),
);
final vaultProvider = Provider((ref) => const SecureVault());
final paperProvider = Provider(
  (ref) => PaperRepository(ref.watch(databaseProvider)),
);
final positionsProvider = FutureProvider<List<Position>>(
  (ref) => ref.watch(paperProvider).positions(),
);
final historyProvider = FutureProvider(
  (ref) => ref.watch(paperProvider).history(),
);
final localeProvider = StateProvider<String>((ref) => 'fa');
final exchangeProvider = StateProvider<String>((ref) => 'Toobit');
final symbolProvider = StateProvider<String>((ref) => 'BTC/USDT');
final timeframeProvider = StateProvider<String>((ref) => '1h');
final tabProvider = StateProvider<int>((ref) => 0);
final appActiveProvider = StateProvider<bool>((ref) => true);
final alertProvider = StateProvider<String?>((ref) => null);

class Watchlist extends StateNotifier<Set<String>> {
  final Database db;
  Watchlist(this.db) : super({}) {
    load().catchError((Object _) {});
  }
  Future<void> load() async {
    final r = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: ['watchlist'],
    );
    if (mounted && r.isNotEmpty) {
      state = (r.first['value'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();
    }
  }

  Future<void> toggle(String s) async {
    final next = {...state};
    if (!next.remove(s)) next.add(s);
    await db.insert('preferences', {
      'key': 'watchlist',
      'value': next.join(','),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    if (mounted) state = next;
  }
}

final watchlistProvider = StateNotifierProvider<Watchlist, Set<String>>(
  (ref) => Watchlist(ref.watch(databaseProvider)),
);
