import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto_ai_trader/main.dart';
import 'package:crypto_ai_trader/core/data/database.dart';
import 'package:crypto_ai_trader/core/providers.dart';
import 'package:crypto_ai_trader/features/analysis/application/analysis_provider.dart';
import 'package:crypto_ai_trader/features/analysis/domain/analysis.dart';
import 'package:crypto_ai_trader/features/market/application/market_controller.dart';
import 'package:crypto_ai_trader/features/market/data/market_repository.dart';
import 'package:crypto_ai_trader/features/market/domain/models.dart';
import 'database_integration_test.dart' show FixtureGateway;

class StaticWatchlist extends Watchlist {
  StaticWatchlist(super.db);
  @override
  Future<void> load() async {}
}

// Snapshot fixture is a recorded PUBLIC response, never shipped as runtime data.
class SnapshotMarket extends MarketController {
  SnapshotMarket(MarketRepository repo, List<Quote> quotes)
    : super(repo, 'BTC/USDT', (_) {}, active: false) {
    state = MarketState(
      quotes: {for (final q in quotes) q.symbol: q},
      connection: 'connected',
      loading: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() async {
    await db.close();
  });
  for (final locale in ['en', 'fa']) {
    testWidgets(
      'Five mobile tabs, $locale layout and captured public snapshot',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final font = FontLoader('Vazirmatn')
          ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        final fallback = FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
        await fallback.load();
        final raw = jsonDecode(
          File('test/fixtures/public_snapshot.json').readAsStringSync(),
        );
        final quotes = (raw['quotes'] as List)
                .map((m) => Quote.fromJson(m))
                .toList(),
            c = (raw['candles'] as List)
                .map((v) => Candle.fromJson(v))
                .toList();
        final a = SignalEngine.evaluate(
          'BTC/USDT',
          '1h',
          c,
          DateTime.parse(raw['capturedAt']),
        );
        final boundary = GlobalKey();
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            watchlistProvider.overrideWith((ref) => StaticWatchlist(db)),
            localeProvider.overrideWith((ref) => locale),
            marketProvider.overrideWith(
              (ref) => SnapshotMarket(
                MarketRepository(FixtureGateway(), db),
                quotes,
              ),
            ),
            positionsProvider.overrideWith((ref) async => []),
            historyProvider.overrideWith((ref) async => []),
            analysisProvider.overrideWith(
              (ref) async => AnalysisView(a, CandleBatch(c), false),
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: boundary, child: const CryptoApp()),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
        for (var tab = 1; tab < 5; tab++) {
          await tester.tap(find.byType(NavigationDestination).at(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), null, reason: '$locale tab $tab');
        }
        container.read(tabProvider.notifier).state = 0;
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            'docs/screenshots/home_$locale.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });

        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump();
      },
    );
  }
}
