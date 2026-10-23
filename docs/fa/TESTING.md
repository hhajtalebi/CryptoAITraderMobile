# آزمون کیفیت

## اجرای تست‌ها

```bash
npm test
node --check /tmp/web.js # یا ابتدا script inline HTML را استخراج کنید
python3 tools/build_release.py
```

تست‌های `tests/market_engine.test.mjs` محاسبات EMA/RSI/ATR، بسته‌شدن candle، رد warmup ناکافی، هندسهٔ levels در صورت جهت‌دار بودن، URL قرارداد و بک‌تست را بررسی می‌کنند.

## گزارش v1.0.0

- 10/10 تست Node.js موفق.
- `node --check` روی inline JavaScript موفق.
- APK build موفق؛ `apksigner verify`, `aapt dump badging`, package name، version، minSDK/targetSDK و size بررسی شدند.
- Network integration end-to-end از خود برنامه، CORS مرورگر و Android device install در این محیط اجرا نشده‌اند.
- تست Flutter prototype موجود زیر `test/` در این مرحله اجرا نشده است؛ تست گزارش‌شدهٔ این release همان 8 تست Node است.
