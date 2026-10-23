# CryptoAITrader

نسخهٔ **1.0.0** — سندباکس پژوهشی فارسی/انگلیسی برای مرور فید عمومی بازار LBank، تحلیل کندل‌های اسپات، فهرست قراردادهای فیوچرز، واچ‌لیست، بک‌تست و شبیه‌سازی محلی. این محصول سفارش واقعی ارسال نمی‌کند.

## دانلود

- **صفحهٔ HTML سندباکس:** `sandbox.html` — فایل را در مرورگر باز کنید؛ برای فید آنلاین، روش پیشنهادی اجرای سرور در پایین را انجام دهید.
- **APK اندروید:** `releases/v1.0.0/CryptoAITrader-v1.0.0.apk` — Universal Java/WebView APK، حداقل Android 7 / API 24؛ امضای sandbox آزمایشی دارد.
- **ZIP سورس:** `releases/v1.0.0/CryptoAITrader-v1.0.0-source.zip`.
- **یادداشت نسخه:** `RELEASE_NOTES.md`.

> نصب مستقیم APK: فایل را در Android باز کنید و در صورت نیاز اجازهٔ نصب از فایل‌منیجر را فعال کنید. نصب روی دستگاه فیزیکی در این محیط انجام نشده است. اثرانگشت SHA-256 داخل پوشهٔ نسخه است.

## شروع سریع سندباکس وب

نیازمندی: Node.js 20 یا جدیدتر (در این checkout با Node 22 آزموده شد).

```bash
npm install
npm start
```

سپس `http://localhost:4173/` را باز کنید. سرور فقط فایل‌های پروژه را سرو می‌کند و مسیر same-origin `/api/proxy` را برای دو میزبان مجاز LBank فعال می‌کند. در محدودیت شبکهٔ محیط sandbox ممکن است خود فید عمومی قابل دسترسی نباشد؛ رابط در این حالت صریحاً خطا/آفلاین نشان می‌دهد و اطلاعات زندهٔ ساختگی جایگزین نمی‌کند.

برای کار با فایل مستقل `sandbox.html` نیز آن را باز کنید؛ بعضی مرورگرها درخواست cross-origin را در `file://` مسدود می‌کنند، پس برای داده زنده از سرور بالا استفاده کنید. در APK درخواست عمومی از پل Android با allowlist میزبان‌های LBank انجام می‌شود.

## ساخت و آزمون

```bash
npm test
python3 tools/build_release.py
```

ساخت APK در این sandbox با OpenJDK 21، AAPT، ECJ، D8 و apksigner آماده‌شدهٔ محلی آزموده شد؛ لازم نیست Flutter SDK یا Android Studio روی دستگاه توسعه‌دهنده نصب باشد تا APK توزیع‌شده نصب شود. برای توسعهٔ Flutter prototype موجود در `lib/` به Flutter 3.35.7/Dart 3.9.2 و Android SDK نیاز است؛ این prototype نسخهٔ اصلی APK تحویلی 1.0.0 نیست.

## مرزبندی داده و ایمنی

- قیمت‌ها و کندل‌ها از endpointهای عمومی LBank دریافت می‌شوند؛ timestamp پاسخ منبع حفظ می‌شود.
- کندل‌های فعلی از **Spot API** هستند. اطلاعات قرارداد/حجم/فاندینگ/دفتر سفارش از **Contract Futures API** مستقل است.
- چون endpoint عمومی کندل Futures در مستندات بررسی‌شده تأیید نشد، تحلیل کندلی فقط Spot نام‌گذاری می‌شود؛ سیگنال Spot به‌عنوان سیگنال Futures نمایش داده نمی‌شود.
- Paper Trading فقط در localStorage دستگاه است؛ اجرای سفارش، برداشت، کیف‌پول واقعی، AI مولد داخلی یا تضمین سود وجود ندارد.
- امتیاز تحلیل احتمال برد نیست؛ دادهٔ ناقص، کهنه یا گسسته باعث رد تحلیل می‌شود.

## مستندات

- [قراردادهای API و محدودیت‌های واقعی](API.md)
- [نصب](docs/fa/INSTALLATION.md)
- [راهنمای کاربری](docs/fa/USER_GUIDE.md)
- [معماری](docs/fa/ARCHITECTURE.md)
- [موتور تحلیل](docs/fa/SIGNAL_ENGINE.md)
- [استراتژی‌ها](docs/fa/STRATEGIES.md)
- [ذخیره‌سازی](docs/fa/DATABASE.md)
- [لاگ‌ها](docs/fa/LOGGING.md)
- [تست](docs/fa/TESTING.md)
- [انتشار](docs/fa/RELEASE_PROCESS.md)
- [توسعه](docs/fa/DEVELOPMENT.md)
- [امنیت](docs/fa/SECURITY.md)
- [محدودیت‌های تحویل](docs/fa/STATUS.md)
