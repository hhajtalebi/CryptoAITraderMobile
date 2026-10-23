# معماری CryptoAITraderMobile v1.1.0

APK فعلی یک Java Android Activity با WebView asset محلی است؛ برنامهٔ قابل‌اجرا در `assets/web/index.html` و `assets/brand/`, `assets/fonts/` قرار دارد. Flutter prototype در `lib/` بخشی از APK نیست.

## جریان داده
- Spot tickers و candles فقط از `api.lbkex.com` خوانده می‌شوند.
- Futures instruments/marketData از `lbkperp.lbank.com` خوانده می‌شوند؛ دیتاست futures جدا از spot است.
- UI/browser به same-origin `/api/proxy` وصل می‌شود؛ Android به `PublicApiBridge` می‌زند. هردو مسیر محدود به GET و مسیرهای public.
- Futures endpoint کندل public در مستندات تأیید نشده؛ Futures scanner بازار را فهرست می‌کند و سیگنال کندلی صادر نمی‌کند.

## منطق پژوهش
`signalDecision` در live analysis و backtest مشترک است. برای 15m/1h تأیید بسته‌شدهٔ 4H لازم است؛ برای 4H/1D از 4H به‌عنوان تایم‌فریم بالاتر استفاده نمی‌شود. Backtest با OHLC Spot، ورود کندل بعد از سیگنال، هزینه‌های مدل‌شده و stop-first ساخته شده است.

## پایداری
Paper positions در `localStorage` کلید `cait.paper` و تحلیل/رویداد/لاگ‌ها زیر `cait.history` ذخیره می‌شوند. این ذخیره‌سازی cloud sync، encryption یا backup سروری ندارد.
