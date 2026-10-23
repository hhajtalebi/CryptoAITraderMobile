# فرایند انتشار

1. روی branch تأییدشده کار کنید؛ وضعیت Git، remote tag و GitHub Releases را بررسی کنید. تغییرات محلی را حفظ کنید.
2. `VERSION`, `package.json`, changelog، منابع UI، min/target SDK، versionCode و مستندات را هماهنگ کنید.
3. `npm ci`, `npm run build:ui`, `npm test` را اجرا کنید. تست Flutter فقط در صورت وجود SDK اجرا شود.
4. `python3 tools/build_release.py`؛ سپس امضا، manifest، versionCode، checksum، اندازه، APK ZIP CRC را اعتبارسنجی کنید.
5. `python3 tools/package_release.py`؛ سورس ZIP باید شامل README/API/tests/docs/build scripts و ignore files و فاقد `.git`, node_modules, keystore, APK/idsig باشد.
6. commit و push به branch session؛ push را تأیید کنید، سپس tag منحصربه‌فرد را به همان commit نهایی وصل کنید.
7. GitHub Release عمومی بسازید و واقعی‌بودن assets APK/Source ZIP را بعد از upload با `gh release view` بررسی کنید. اگر `uploads.github.com` در محیط قابل دسترسی نبود، فقط لینک فایل committed را گزارش کنید و نگویید asset پیوست شده است.
8. در یادداشت انتشار وضعیت APK debug/release/test-sign، محدودیت نصب دستگاه و نتایج دقیق تست‌ها را بنویسید. APK ارزیابی با کلید production یا Play Store اشتباه نشود.
