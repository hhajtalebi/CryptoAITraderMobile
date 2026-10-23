import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import '../providers.dart';

const bg = Color(0xFF090E17),
    panel = Color(0xFF121B29),
    line = Color(0xFF233044),
    mint = Color(0xFF54E0BB),
    muted = Color(0xFF8D9DB5),
    red = Color(0xFFFF7488),
    blue = Color(0xFF8AA8FF);
String money(double v) =>
    v.isFinite ? NumberFormat('#,##0.00', 'en').format(v) : '—';
String price(double v) => v.isFinite
    ? NumberFormat(v.abs() < 1 ? '0.000000' : '#,##0.00', 'en').format(v)
    : '—';
String tr(WidgetRef ref, String key) =>
    translate(ref.watch(localeProvider), key);
String translate(String lang, String key) =>
    lang == 'fa' ? (_fa[key] ?? key) : (_en[key] ?? key);
const _en = {
  'Home': 'Home',
  'Markets': 'Markets',
  'Signals': 'Signals',
  'Trading': 'Trading',
  'Portfolio': 'Portfolio',
  'overview': 'Your market, in focus.',
  'paper': 'PAPER ONLY',
  'balance': 'Paper equity',
  'virtual': 'Virtual USDT • not real funds',
  'available': 'Available',
  'realized': 'Realized PnL',
  'open': 'Open positions',
  'watchlist': 'Watchlist',
  'market': 'Market overview',
  'all': 'All assets',
  'search': 'Search an asset',
  'analysis': 'Market intelligence',
  'technical': 'Technical score',
  'confidence_note': 'Evidence score, not a win probability.',
  'levels': 'Trade plan',
  'entry': 'Entry',
  'stop': 'Stop loss',
  'timeframe': 'Timeframe',
  'indicators': 'Indicators',
  'structure': 'Market structure',
  'support': 'Support',
  'resistance': 'Resistance',
  'regime': 'Market regime',
  'mtf': 'Higher timeframe',
  'unknown': 'Unavailable',
  'trending': 'Trending',
  'ranging': 'Range-bound',
  'higher_bias': 'Upward bias',
  'lower_bias': 'Downward bias',
  'breakout': 'Breakout',
  'breakdown': 'Breakdown',
  'aligned': 'Aligned',
  'conflict': 'Conflict',
  'reason': 'Decision context',
  'wait': 'Waiting is a position.',
  'wait_detail': 'No order is forced. Wait for fresh, aligned evidence.',
  'research': 'Strategy lab',
  'research_sub': 'Backtest • Walk-forward • Historical edge',
  'assistant': 'AI research assistant',
  'assistant_sub': 'Explain the market. Never execute trades.',
  'settings': 'Preferences',
  'exchange': 'Market data source',
  'security': 'Secure credentials',
  'no_live':
      'Live execution is locked. No withdrawal or trading permission required.',
  'cache': 'Cached data • trading disabled',
  'offline': 'Offline',
  'retry': 'Retry',
  'loading': 'Connecting to the market…',
  'empty': 'Nothing here yet',
  'empty_watch': 'Star an asset to build your watchlist.',
  'risk': 'Risk per trade',
  'risk_note': '0.5% equity risk • 1× notional • max 5 positions',
  'submit': 'Review paper order',
  'confirm': 'Confirm paper order',
  'cancel': 'Cancel',
  'confirm_note':
      'Simulated execution with fees and slippage. Stops only monitored while the app is active.',
  'trade_history': 'Execution history',
  'close': 'Close position',
  'partial': 'Close 50%',
  'pnl': 'Net PnL',
  'no_positions': 'Your first paper trade starts with a signal.',
  'notifications': 'Activity',
  'no_notifications': 'No execution events yet.',
  'paper_exit': 'A paper exit was recorded.',
  'storage_error': 'Storage error. Trading paused; retry safely.',
  'run': 'Run research',
  'research_note':
      'Uses fetched closed candles only. Single-timeframe, fixed mobile-v1 model. Short samples do not validate an edge.',
  'trades': 'Trades',
  'win_rate': 'Win rate',
  'drawdown': 'Max drawdown',
  'net_r': 'Net R',
  'folds': 'Out-of-sample folds',
  'samples': 'Samples',
  'insufficient': 'At least 30 completed samples required.',
  'prediction': 'Prediction',
  'prediction_note':
      'Probabilistic forecasting not yet validated; no probability is invented.',
  'backtest': 'Backtest',
  'edge': 'Historical edge',
  'credentials_note':
      'Stored only in Android Keystore-backed storage / iOS Keychain. Never used for live orders.',
  'save': 'Save securely',
  'delete': 'Delete credentials',
  'saved': 'Saved',
  'kcex': 'KCEX • official API verification pending',
  'language': 'Language',
  'live_data': 'Public market data',
  'fresh': 'Fresh',
  'stale': 'Stale',
  'paused': 'Paused',
  'reconnecting': 'Reconnecting',
  'connected': 'Connected',
  'streaming': 'Streaming',
  'connecting': 'Connecting',
  'technical_only': 'Research only',
  'risk_rejected': 'Order blocked',
  'manual': 'Manual',
  'warmup': 'Insufficient closed candles',
  'candle_gap': 'Missing candle interval',
  'invalid_indicators': 'Invalid indicator data',
  'flat_market': 'Flat market',
  'mixed_evidence': 'Mixed directional evidence',
  'trend_momentum': 'Trend and momentum agree',
  'range_no_edge': 'Range regime: no demonstrated edge',
  'mtf_conflict': 'Higher timeframe disagrees',
  'stop_too_wide': 'Stop exceeds risk limit',
  'extended_move': 'Move is overextended',
  'stale_quote': 'Fresh quote required',
  'stale_signal': 'Signal has expired',
  'price_moved': 'Price moved; refresh analysis',
  'risk_reward': 'Reward/risk below minimum',
  'exposure_limit': 'Insufficient unreserved paper funds',
  'symbol_already_open': 'A position already exists for this symbol',
  'network_unavailable': 'Network unavailable',
  'rate_limited': 'Rate limit: cooling down',
  'candles_unavailable': 'Exchange rejected candle request',
  'offline_cache': 'Showing saved data; trading disabled',
  'portfolio_risk': 'Portfolio risk limit reached',
  'daily_loss_limit': 'Daily loss limit reached',
  'position_limit': 'Maximum open positions reached',
  'invalid_stop': 'Stop failed risk checks',
  'ask': 'Ask a question',
  'send': 'Send',
  'endpoint': 'HTTPS API base URL',
  'model': 'Model name',
  'api_key': 'API key',
  'secret': 'Secret',
  'ai_note':
      'Your question and selected public market context are sent to your configured provider. No keys, portfolio or order authority are sent. Answers may be wrong.',
  'ai_setup': 'Configure an OpenAI-compatible HTTPS provider in preferences.',
  'ai_error': 'Provider unavailable or configuration invalid.',
  'assistant_disclaimer': 'Research explanation only. Not financial advice.',
  'foreground': 'Foreground monitoring only',
  'unrealized': 'Unrealized PnL',
  'last_update': 'Source timestamp',
  'no_data': 'No market data available',
  'tp_note': '⅓ at each target; SL → entry after TP1. Fees still apply.',
  'test_not_run': 'No research run yet',
  'risk_budget': 'Maximum planned loss',
  'not_ready':
      'Execution unavailable: fresh data and higher-timeframe confirmation required.',
};
const _fa = {
  'Home': 'خانه',
  'Markets': 'بازارها',
  'Signals': 'سیگنال‌ها',
  'Trading': 'معاملات',
  'Portfolio': 'پرتفوی',
  'overview': 'بازار، در یک نگاه.',
  'paper': 'فقط آزمایشی',
  'balance': 'ارزش حساب آزمایشی',
  'virtual': 'تتر مجازی • پول واقعی نیست',
  'available': 'قابل استفاده',
  'realized': 'سود و زیان محقق‌شده',
  'open': 'موقعیت‌های باز',
  'watchlist': 'دیده‌بان',
  'market': 'نمای بازار',
  'all': 'همه دارایی‌ها',
  'search': 'جستجوی دارایی',
  'analysis': 'تحلیل هوشمند بازار',
  'technical': 'امتیاز فنی',
  'confidence_note': 'امتیاز شواهد است؛ نه احتمال موفقیت.',
  'levels': 'برنامه معامله',
  'entry': 'ورود',
  'stop': 'حد ضرر',
  'timeframe': 'بازه زمانی',
  'indicators': 'اندیکاتورها',
  'structure': 'ساختار بازار',
  'support': 'حمایت',
  'resistance': 'مقاومت',
  'regime': 'رژیم بازار',
  'mtf': 'تایم‌فریم بالاتر',
  'unknown': 'ناموجود',
  'trending': 'رونددار',
  'ranging': 'خنثی',
  'higher_bias': 'تمایل صعودی',
  'lower_bias': 'تمایل نزولی',
  'breakout': 'شکست مقاومت',
  'breakdown': 'شکست حمایت',
  'aligned': 'هم‌جهت',
  'conflict': 'متعارض',
  'reason': 'دلیل تصمیم',
  'wait': 'منتظر ماندن هم یک تصمیم است.',
  'wait_detail': 'معامله اجباری نیست. منتظر داده تازه و شواهد هم‌جهت بمانید.',
  'research': 'آزمایشگاه استراتژی',
  'research_sub': 'بک‌تست • واک‌فوروارد • مزیت تاریخی',
  'assistant': 'دستیار پژوهش هوشمند',
  'assistant_sub': 'توضیح بازار؛ بدون اختیار معامله.',
  'settings': 'تنظیمات',
  'exchange': 'منبع داده بازار',
  'security': 'اطلاعات اتصال امن',
  'no_live': 'معامله واقعی قفل است. مجوز معامله یا برداشت لازم نیست.',
  'cache': 'داده ذخیره‌شده • معامله غیرفعال',
  'offline': 'آفلاین',
  'retry': 'تلاش مجدد',
  'loading': 'در حال اتصال به بازار…',
  'empty': 'هنوز موردی وجود ندارد',
  'empty_watch': 'با ستاره‌دار کردن دارایی، دیده‌بان بسازید.',
  'risk': 'ریسک هر معامله',
  'risk_note': 'ریسک ۰٫۵٪ • اهرم ۱ • حداکثر ۵ موقعیت',
  'submit': 'بررسی سفارش آزمایشی',
  'confirm': 'تأیید سفارش آزمایشی',
  'cancel': 'انصراف',
  'confirm_note':
      'اجرای شبیه‌سازی‌شده با کارمزد و لغزش. حد ضرر فقط هنگام فعال بودن برنامه پایش می‌شود.',
  'trade_history': 'تاریخچه اجراها',
  'close': 'بستن موقعیت',
  'partial': 'بستن ۵۰٪',
  'pnl': 'سود و زیان خالص',
  'no_positions': 'اولین معامله آزمایشی با یک سیگنال شروع می‌شود.',
  'notifications': 'رویدادها',
  'no_notifications': 'هنوز رویداد معاملاتی ثبت نشده است.',
  'paper_exit': 'خروج از معامله آزمایشی ثبت شد.',
  'storage_error': 'خطای ذخیره‌سازی؛ با احتیاط دوباره تلاش کنید.',
  'run': 'اجرای پژوهش',
  'research_note':
      'فقط کندل‌های بسته‌شده دریافت‌شده؛ مدل ثابت mobile-v1 و تک‌تایم‌فریم. نمونه کوتاه، مزیت را اثبات نمی‌کند.',
  'trades': 'معاملات',
  'win_rate': 'نرخ برد',
  'drawdown': 'بیشترین افت',
  'net_r': 'بازده خالص R',
  'folds': 'بازه‌های خارج از نمونه',
  'samples': 'نمونه‌ها',
  'insufficient': 'حداقل ۳۰ نمونه کامل لازم است.',
  'prediction': 'پیش‌بینی',
  'prediction_note':
      'پیش‌بینی احتمالاتی هنوز اعتبارسنجی نشده؛ عدد ساختگی نمایش داده نمی‌شود.',
  'backtest': 'بک‌تست',
  'edge': 'مزیت تاریخی',
  'credentials_note':
      'فقط در ذخیره‌ساز امن متصل به Keystore اندروید یا Keychain آیفون. برای سفارش واقعی استفاده نمی‌شود.',
  'save': 'ذخیره امن',
  'delete': 'حذف اطلاعات اتصال',
  'saved': 'ذخیره شد',
  'kcex': 'KCEX • در انتظار تأیید API رسمی',
  'language': 'زبان',
  'live_data': 'داده عمومی بازار',
  'fresh': 'تازه',
  'stale': 'قدیمی',
  'paused': 'متوقف',
  'reconnecting': 'اتصال مجدد',
  'connected': 'متصل',
  'streaming': 'جریان زنده',
  'connecting': 'در حال اتصال',
  'technical_only': 'فقط پژوهش',
  'risk_rejected': 'سفارش مسدود شد',
  'manual': 'دستی',
  'warmup': 'تعداد کندل بسته‌شده کافی نیست',
  'candle_gap': 'فاصله در داده کندل‌ها',
  'invalid_indicators': 'داده نامعتبر اندیکاتور',
  'flat_market': 'بازار بدون نوسان',
  'mixed_evidence': 'شواهد جهت‌دار متناقض',
  'trend_momentum': 'روند و مومنتوم هم‌جهت‌اند',
  'range_no_edge': 'بازار خنثی؛ بدون مزیت تأییدشده',
  'mtf_conflict': 'تعارض با تایم‌فریم بالاتر',
  'stop_too_wide': 'حد ضرر فراتر از سقف مجاز',
  'extended_move': 'حرکت بیش از حد کشیده شده',
  'stale_quote': 'قیمت تازه لازم است',
  'stale_signal': 'سیگنال منقضی شده',
  'price_moved': 'قیمت تغییر کرده؛ تحلیل را تازه کنید',
  'risk_reward': 'نسبت سود به ریسک ناکافی',
  'exposure_limit': 'موجودی آزاد آزمایشی کافی نیست',
  'symbol_already_open': 'برای این نماد موقعیت باز وجود دارد',
  'network_unavailable': 'شبکه در دسترس نیست',
  'rate_limited': 'محدودیت نرخ؛ در حال مکث',
  'candles_unavailable': 'درخواست کندل توسط صرافی رد شد',
  'offline_cache': 'نمایش کش؛ معامله غیرفعال',
  'portfolio_risk': 'سقف ریسک پرتفوی',
  'daily_loss_limit': 'سقف زیان روزانه',
  'position_limit': 'سقف موقعیت‌های باز',
  'invalid_stop': 'حد ضرر معتبر نیست',
  'ask': 'پرسش خود را بنویسید',
  'send': 'ارسال',
  'endpoint': 'نشانی پایه HTTPS سرویس',
  'model': 'نام مدل',
  'api_key': 'کلید API',
  'secret': 'کلید محرمانه',
  'ai_note':
      'پرسش و داده عمومی بازار به سرویس انتخابی شما ارسال می‌شود. کلیدها، پرتفوی و اختیار معامله ارسال نمی‌شود. پاسخ ممکن است اشتباه باشد.',
  'ai_setup': 'در تنظیمات یک سرویس HTTPS سازگار با OpenAI انتخاب کنید.',
  'ai_error': 'سرویس در دسترس نیست یا تنظیمات معتبر نیست.',
  'assistant_disclaimer': 'فقط توضیح پژوهشی؛ توصیه مالی نیست.',
  'foreground': 'پایش فقط هنگام فعال بودن برنامه',
  'unrealized': 'سود و زیان باز',
  'last_update': 'زمان منبع داده',
  'no_data': 'داده بازار موجود نیست',
  'tp_note':
      'یک‌سوم در هر هدف؛ پس از TP1 حد ضرر به ورود می‌رسد. کارمزد باقی است.',
  'test_not_run': 'پژوهشی اجرا نشده است',
  'risk_budget': 'بیشترین زیان برنامه‌ریزی‌شده',
  'not_ready': 'اجرا غیرفعال: داده تازه و تأیید تایم‌فریم بالاتر لازم است.',
};

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line.withValues(alpha: .65)),
    ),
    child: child,
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, this.color = mint});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      textDirection: RegExp(r'[A-Za-z0-9]').hasMatch(text)
          ? TextDirection.ltr
          : null,
      style: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: .5,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  final String title, value;
  final Color? color;
  const Metric(this.title, this.value, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          color: muted,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.color = muted,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: color,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
