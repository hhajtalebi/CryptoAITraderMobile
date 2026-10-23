# نصب و اجرا

## Android APK
1. APK نسخه‌دار را در گوشی دریافت کنید.
2. در Downloads روی فایل `.apk` بزنید و در صورت درخواست، اجازهٔ نصب از همان منبع را فعال کنید.
3. حداقل سیستم عامل Android 5.0 / API 21 است؛ target SDK 34.

APK با کلید ارزیابی پروژه امضا می‌شود و Play Protect ممکن است هشدار دهد. این کلید برای Google Play/انتشار عمومی production نیست. نصب روی دستگاه فیزیکی در build environment تأیید نشده؛ اگر خطا می‌بینید، متن کامل خطا و Android version کمک‌کننده است.

## Sandbox وب
با Node.js 20+: `npm ci && npm start` سپس `/` برای صفحهٔ دانلود یا `/sandbox.html` برای برنامه. فید زنده از same-origin proxy استفاده می‌کند؛ دسترسی شبکه به LBank وابسته به محیط است.
