# آزمون و تضمین کیفیت

## فرمان‌ها

```bash
npm run build:ui
npm test
CRYPTOAI_STORE_PASSWORD='<local secret>' CRYPTOAI_KEY_PASSWORD='<local secret>' python3 tools/build_release.py
python3 tools/package_release.py
```

کلید keystore و رمزها باید بیرون مخزن نگهداری شوند. ابزار build متغیرهای رمز را از محیط می‌خواند و هنگام چاپ فرمان‌ها redacted می‌کند.

## موارد پوشش‌داده‌شده در Node
- EMA/RSI/ATR و warmup.
- رد کندل گسسته/نامعتبر/آینده و کندل باز؛ تداوم زمانی و stale data.
- تحلیل و بک‌تست با تصمیم مشترک در 15m/1h/4h/1D و تأیید 4H بسته‌شده برای TF پایین‌تر.
- ورود پس از بسته‌شدن سیگنال، stop-first در برخورد چندگانه، adverse gap، کمیسیون/لغزش و سقف cash در Spot LONG.
- train و out-of-sample زمانی مجزا؛ جلوگیری از تغییر سیگنال گذشته با کندل بعدی و عدم استفاده از کندل باز 4H.
- سازنده/تسویهٔ Paper، محدودیت Spot short، سقف سرمایهٔ نقدی و persistence history.
- serialization JSON/CSV/JSONL/TXT، CSV formula-injection safety و persistence JSON.
- allowlist آدرس API، integration server، مسدودسازی POST، SSRF، host/path/port ناامن.

آخرین اجرای تأییدشده: `npm run build:ui` موفق و `npm test` برابر 25/25 پاس.

## حدود آزمون
- Android APK با AAPT/ECJ/D8/apksigner ساخته و امضای v1/v2/v3 و manifest بررسی می‌شود؛ `zipalign`, `adb`, Emulator و Flutter/Dart در این محیط حاضر نیستند.
- نصب/اجرای APK روی گوشی یا شبیه‌ساز تأییدنشده است. امضا و manifest اثبات نصب نیستند.
- live LBank end-to-end از محیط sandbox تضمین نیست؛ در قطع upstream خطا نمایش داده می‌شود و دادهٔ ساختگی جایگزین نمی‌شود.
- کارمزد/لغزش مدل مفروض‌اند و باید با fee tier و market impact واقعی جایگزین شوند؛ نتیجهٔ بک‌تست تضمین عملکرد آینده نیست.
