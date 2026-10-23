# توسعه و ساخت

## Web sandbox
نیازمند Node.js 20+؛ وابستگی‌ها از `package-lock.json` نصب شوند:
```bash
npm ci
npm run build:ui
npm test
npm start
```
سرور روی `0.0.0.0:4173` گوش می‌دهد؛ `/` صفحه دانلود و `/sandbox.html` محیط تعاملی است.

## Android APK
در این checkout از `/opt/android-sdk` (AAPT، `android.jar`، ECJ، D8 و apksigner) استفاده می‌شود:
```bash
CRYPTOAI_KEYSTORE=/path/outside/repo/release.jks \\
CRYPTOAI_KEY_ALIAS=release \\
CRYPTOAI_STORE_PASSWORD='<local secret>' \\
CRYPTOAI_KEY_PASSWORD='<local secret>' \\
python3 tools/build_release.py
python3 tools/package_release.py
```
نسخه از `VERSION` خوانده می‌شود؛ versionCode برابر major*10000+minor*100+patch است. خروجی در `releases/vX.Y.Z/` است. امضای sandbox از keystore محلی بیرون مخزن استفاده می‌کند؛ کلید خصوصی را وارد مخزن یا ZIP نکنید. اجرای سازنده با Android SDK/keystore متفاوت به‌صورت دقیق مستند شود.

## مرزبندی سورس
`assets/web/index.html` برنامهٔ WebView تحویلی است. Flutter prototype در `lib/` و `test/` نگه داشته شده اما build toolchain این APK را تولید نمی‌کند. برای تست Flutter، Flutter/Dart/Android SDK نصب‌شده لازم است.
