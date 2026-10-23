# راهنمای توسعه‌دهنده

## فایل‌های اصلی

- `assets/web/index.html`: UI و منطق مرورگر (single-file bundle).
- `server/portal_server.mjs`: static server توسعه و proxy allowlist.
- `android-native/src/app/cryptoaitrader/MainActivity.java`: shell و bridge HTTP امن Android.
- `android-native/AndroidManifest.xml` و `android-native/res`: مجوزها/آیکون/ظاهر native.
- `tests/market_engine.test.mjs`: تست‌های engine.
- `tools/build_release.py`: build، sign، validate و stage APK.

## تغییر UI

ویرایش HTML/CSS/JS انجام دهید؛ سپس syntax را با استخراج script و `node --check` بررسی کنید. برای اضافه‌کردن دادهٔ صرافی، endpoint باید در مستند رسمی تأیید و به allowlist هم سرور preview و هم Java bridge افزوده شود. هرگز endpoint تجاری order در bridge عمومی اضافه نکنید.

## افزودن تایم‌فریم

Map `TF` و mapping رسمی LBank Spot candle type را با unit test به‌روز کنید. حواستان باشد `time` در query epoch seconds است و زمان خروجی کندل ثانیه است؛ داخل برنامه به ms تبدیل می‌شود. اندازه/حد endpoint و محدودیت نرخ رعایت شود.

## APK

اسکریپت build به ابزارهای موجود در مسیر `/opt/android-sdk/tools` و `/opt/android-sdk/jdk` در محیط تولید نیاز دارد. build script فایل امضای آزمایشی موقتی می‌سازد؛ آن را برای انتشار عمومی استفاده نکنید.
