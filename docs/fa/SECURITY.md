# امنیت و حریم خصوصی

- Android bridge فقط HTTPS GET و میزبان/مسیر دقیق endpointهای عمومی مجاز Spot/Futures را می‌پذیرد؛ port غیر استاندارد، redirect، URL دارای credential، سفارش خصوصی و host ناشناخته رد می‌شود.
- پروکسی Node فقط GET، HTTPS، دو hostname موردنیاز و allowlist مسیرهای read-only عمومی را می‌پذیرد؛ محدودیت پاسخ 2 MiB و timeout دارد.
- preview server فقط `download.html`، `sandbox.html`، `assets/` و `releases/` را ارائه می‌کند؛ `.git`، dotfiles، package manifest و ابزارهای build عمومی نیستند.
- CORS wildcard حذف شده؛ CSP و security headers برای صفحهٔ preview فعال‌اند.
- هیچ API key صرافی درخواست یا ذخیره نمی‌شود. سفارش واقعی/withdrawal وجود ندارد.
- localStorage فقط روی همان origin/device است و رمزگذاری‌شده تلقی نمی‌شود. گزارش export ممکن است سوابق شخصی داشته باشد؛ پیش از اشتراک‌گذاری آن را بررسی کنید.
- signing keystore در Git/ZIP قرار نمی‌گیرد. APK با کلید ارزیابی محلی test-signed است و برای production/Play Store مجاز نیست.
- audit دستگاه واقعی، Play Protect، hardening WebView روی OEMها و penetration test انجام نشده؛ ادعای تأیید امنیت production وجود ندارد.
