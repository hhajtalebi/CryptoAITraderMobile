# امنیت و حریم خصوصی

- داده‌های عمومی فقط با HTTPS از دو میزبان `api.lbkex.com` و `lbkperp.lbank.com` دریافت می‌شوند.
- Android JavaScript bridge فقط GET، host/path allowlist، بدون redirect، timeout و سقف پاسخ دارد.
- برنامه مجوز/مسیر API برای order placement، transfer یا withdraw ندارد.
- API key صرافی درخواست یا ذخیره نمی‌شود.
- Paper Trading و واچ‌لیست روی همان device/browser هستند؛ حذف برنامه یا پاک‌کردن site data ممکن است آن‌ها را حذف کند.
- خروجی JSON تاریخچه ممکن است اطلاعات تحلیل شخصی داشته باشد؛ قبل از اشتراک‌گذاری بازبینی کنید.
- APK با کلید sandbox آزمایشی امضا شده، نه کلید تولید/Play Store. Hash را از فایل همراه همان release کنترل کنید.
- نصب روی دستگاه روت‌شده، proxy interception و امنیت WebView در دستگاه واقعی در این نسخه audit نشده است.
