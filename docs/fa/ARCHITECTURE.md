# معماری

## شکل محصول v1.0.0

تحویل دو ورودی UI دارد:

1. `assets/web/index.html`: برنامهٔ single-page با CSS و JavaScript vanilla، PWA-like و responsive؛ هیچ کتابخانهٔ runtime خارجی ندارد.
2. `android-native/src/app/cryptoaitrader/MainActivity.java`: Android WebView shell، بارگذاری asset محلی و پل JS برای GETهای عمومی امن.

`server/portal_server.mjs` برای اجرای وب در محیط توسعه/preview فایل‌ها را سرو می‌کند و `/api/proxy` محدود دارد. Android از proxy محلی استفاده نمی‌کند؛ Java bridge درخواست‌های HTTPS را انجام می‌دهد.

## جریان داده

`LBank Spot REST → validate/normalize → close-candle filter → indicators → explanatory analysis → local history`.

جریان مستقل Futures:

`Contract /instrument + /marketData → validate active USDT SwapU → scanner status and liquidity/funding`.

فیوچرز و Spot هیچ‌گاه در model یک Quote ادغام نمی‌شوند. بدون Contract OHLCV تأییدشده، بخش futures market scanner فرصت Long/Short Futures نمی‌سازد.

## لایه‌بندی

- Presentation: HTML صفحات dashboard/markets/watch/scanner/signals/paper/history/backtest/settings/about.
- Application state: objectهای APP و state helpers در script واحد، localStorage برای watchlist/paper.
- Domain/pure logic: EMA/SMA/RSI/Wilder ATR/MACD، candle validation/close filtering، signal scoring، risk sizing و conservative backtest.
- Data: LBank Spot و Contract REST، browser same-origin proxy یا Android bridge.

برخی ماژول‌ها در یک HTML نگهداری شده‌اند تا فایل مستقل و Android APK ساده بماند؛ این ساختار یک monolith کوچک است، نه Clean Architecture کامل. در ZIP، Flutter/Dart research prototype قبلی نیز حفظ شده اما APK v1.0.0 آن را اجرا نمی‌کند.

## امنیت

Android WebView JavaScript فقط در asset محلی فعال است. JS bridge تنها HTTPS GET به `api.lbkex.com` یا `lbkperp.lbank.com`، مسیرهای عمومی محدوده، no redirects، timeout و سقف پاسخ 8 MiB را قبول می‌کند. WebView mixed-content خاموش است؛ هیچ bridge سفارش/کلید/ذخیرهٔ secret وجود ندارد.
