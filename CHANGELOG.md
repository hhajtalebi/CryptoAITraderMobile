# Changelog

## [1.1.0] — 2026-10-23
- موتور live/backtest از قواعد تصمیم مشترک استفاده می‌کند؛ تایم‌فریم selectable است و 4H confirmation فقط در جایی که واقعاً TF بالاتر است اعمال می‌شود.
- بک‌تست: stop-first برای برخورد همزمان، adverse gap fills، هزینهٔ round-trip fee/slippage، جلوگیری از ورود زودتر از سیگنال و گزارش train / out-of-sample جدا.
- Paper ledger: هزینه و لغزش مشترک، اصلاح سایز ریسک، جلوگیری از short شبیه spot و جلوگیری از close با قیمت stale.
- تحلیل/رویداد/لاگ با سقف محلی در localStorage پایدار می‌شوند؛ خروجی کامل JSON و خروجی تب فعال CSV/JSONL/TXT.
- اعتبارسنجی کندل و زمان endpointها سخت‌گیرانه‌تر شد؛ بررسی timestampهای ثانیه‌ای و میلی‌ثانیه‌ای.
- Proxy فقط GET، HTTPS، میزبان و مسیر دقیق عمومی، اندازهٔ پاسخ محدود؛ فایل‌های dotfile، package و tooling در سرور preview منتشر نمی‌شوند.
- حداقل نسخهٔ اندروید API 21؛ release APK و ZIP نام‌گذاری نسخه‌دار.

## [1.0.2] — 2026-10-23
- حداقل Android API 21 و پشتیبانی امضای v1/v2/v3.
- versionCode 10002.

## [1.0.1] — 2026-10-23
- targetSdk 34 و versionCode 10001 برای سازگاری نصب.

## [1.0.0] — 2026-10-23
- اولین نسخهٔ MVP پژوهشی WebView/HTML.
