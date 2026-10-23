# نسخه‌بندی و انتشار

نسخه‌ها با Semantic Versioning ثبت می‌شوند: `MAJOR.MINOR.PATCH`. نسخهٔ فعلی 1.0.0 در `VERSION`, `package.json`, `RELEASE_NOTES.md` و Android manifest یکسان است. Android `versionCode=10000` دارد.

مراحل build:

1. به‌روزرسانی کد و مستندات/تست.
2. `npm test`.
3. بررسی HTML/JS syntax.
4. `python3 tools/build_release.py`.
5. تأیید APKSig، manifest، اندازه و SHA-256.
6. ساخت ZIP سورس بدون `.git`, node_modules, cache, build و secrets.

APK فعلی با sandbox key توسعه‌ای امضا می‌شود. برای انتشار فروشگاهی باید مالک پروژه کلید امضای خودش را نگه دارد و build pipeline را با امضای محرمانه جایگزین کند. کلید release واقعی را در مخزن یا فایل سورس نگذارید.
