import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/data/database.dart';
import 'core/providers.dart';
import 'core/presentation/design.dart';
import 'core/presentation/home_page.dart';
import 'features/market/presentation/market_widgets.dart';
import 'features/analysis/presentation/signals_page.dart';
import 'features/trading/presentation/trading_page.dart';
import 'features/portfolio/presentation/portfolio_page.dart';
import 'features/settings/presentation/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: bg,
    ),
  );
  // Never log arbitrary exception payloads (may contain credentials).
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(exception: StateError('UI error; details redacted')),
    );
  };
  try {
    final db = await AppDatabase.open();
    final prefs = await db.query('preferences');
    final values = {for (final r in prefs) r['key']: r['value']};
    runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          localeProvider.overrideWith(
            (ref) => values['locale'] == 'en' ? 'en' : 'fa',
          ),
          exchangeProvider.overrideWith(
            (ref) => values['exchange'] == 'LBank' ? 'LBank' : 'Toobit',
          ),
        ],
        child: const CryptoApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage_rounded, size: 48),
                const SizedBox(height: 20),
                const Text('ذخیره‌سازی در دسترس نیست / Storage unavailable'),
                TextButton(
                  onPressed: main,
                  child: const Text('تلاش مجدد / Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CryptoApp extends ConsumerWidget {
  const CryptoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'CryptoAITrader',
    locale: Locale(ref.watch(localeProvider)),
    supportedLocales: const [Locale('fa'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: mint,
        onPrimary: bg,
        surface: panel,
        onSurface: Color(0xFFE8EDF5),
        secondary: blue,
        error: red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerColor: line,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(40, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(40, 46),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bg,
        selectedColor: mint.withValues(alpha: .15),
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: mint.withValues(alpha: .13),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10,
            color: s.contains(WidgetState.selected) ? mint : muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? mint : muted,
          ),
        ),
      ),
    ),
    home: const AppShell(),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appActiveProvider.notifier).state =
        state == AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider), alert = ref.watch(alertProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: 20,
        title: const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stacked_line_chart_rounded, color: mint, size: 29),
              SizedBox(width: 9),
              Text(
                'crypto',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
              Text(
                'AI',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: mint,
                  letterSpacing: -.6,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr(ref, 'notifications'),
            onPressed: () {
              ref.read(alertProvider.notifier).state = null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(tr(ref, 'notifications'))),
                    body: const SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: HistoryList(),
                    ),
                  ),
                ),
              );
            },
            icon: Badge(
              isLabelVisible: alert != null,
              backgroundColor: mint,
              child: const Icon(Icons.notifications_none_rounded, size: 22),
            ),
          ),
          IconButton(
            tooltip: tr(ref, 'settings'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.tune_rounded, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(tab),
            child: switch (tab) {
              0 => const HomePage(),
              1 => const MarketsPage(),
              2 => const SignalsPage(),
              3 => const TradingPage(),
              _ => const PortfolioPage(),
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: line)),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: tab,
          onDestinationSelected: (i) =>
              ref.read(tabProvider.notifier).state = i,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.space_dashboard_outlined),
              selectedIcon: const Icon(Icons.space_dashboard_rounded),
              label: tr(ref, 'Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.candlestick_chart_outlined),
              label: tr(ref, 'Markets'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.radar_rounded),
              label: tr(ref, 'Signals'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.swap_vert_rounded),
              label: tr(ref, 'Trading'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              label: tr(ref, 'Portfolio'),
            ),
          ],
        ),
      ),
    );
  }
}
