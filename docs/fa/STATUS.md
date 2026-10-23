# وضعیت پروژه CryptoAITraderMobile v1.1.0

## پیاده‌سازی‌شده در این نسخه
- برنامهٔ Android WebView با UI فارسی/انگلیسی، Spot و Futures جدا، بازارها، نمودار، اسکن قراردادهای futures و دفتر Paper محلی.
- یک هستهٔ تصمیم فنی برای تحلیل بسته‌شدهٔ Spot و بک‌تست rolling.
- بک‌تست 15m/1h/4h/1D بر اساس دادهٔ Spot؛ 4H فقط برای تایم‌فریم‌های پایین‌تر و با محدودیت زمانی اعمال می‌شود.
- stop-first برای ابهام OHLC، اصلاح fill برای gap، هزینهٔ round-trip و تقسیم زمانی train/out-of-sample.
- history تحلیل، Paper events و logs روی localStorage؛ خروجی JSON کامل و CSV/JSONL/TXT تب فعال.
- Proxy عمومی LBank با GET/HTTPS/host/path allowlist، سقف پاسخ و محدودسازی فایل‌های قابل سرو.
- هیچ سفارش واقعی، API خصوصی، برداشت یا AI آموزش‌دیده وجود ندارد.

## محدودیت‌ها و موارد تأییدنشده
- هیچ endpoint عمومی کندل futures در مستندات بررسی‌شده تأیید نشده؛ Futures scanner وضعیت، قیمت، حجم و funding را نشان می‌دهد ولی سیگنال کندلی Futures صادر نمی‌کند.
- سیگنال‌ها اندیکاتوری پژوهشی‌اند؛ امتیاز آن‌ها احتمال برد نیست.
- Paper Trading فقط Spot-long را به‌عنوان simulator می‌پذیرد؛ فروش استقراضی روی Spot مسدود است. simulator محلی است و قیمت/لغزش/کارمزد زنده را تضمین نمی‌کند.
- بک‌تست فقط تاریخچهٔ محدود endpoint عمومی را می‌سنجد؛ OOS ثابت 30% زمانی جایگزین اعتبارسنجی طولانی، walk-forward مستقل یا تضمین سود نیست.
- تاریخچه در localStorage هر دستگاه است؛ پاک‌کردن دادهٔ مرورگر/برنامه آن را حذف می‌کند و فضای ذخیره محدود است.
- APK با کلید ارزیابی محلی امضا می‌شود، نه کلید production/Play Store. نصب یا اجرای دستگاهی/Emulator در محیط توسعه انجام نشده است.
- در این نسخه `npm run build:ui` و 25 تست Node پاس شده‌اند؛ APK با SDK ساخته، امضای v1/v2/v3 و manifest بررسی شده است. Flutter/Dart، zipalign، adb و Emulator در محیط حاضر نیستند؛ نصب/اجرای گوشی تأیید نشده است.
- GitHub release asset upload ممکن است بسته به دسترسی endpoint `uploads.github.com` محدود باشد؛ وجود صفحهٔ release به‌تنهایی اثبات پیوست asset نیست.
