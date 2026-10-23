# API.md — قراردادهای خارجی و داخلی CryptoAITrader 1.0.0

این سند فقط endpointهای بررسی‌شده و قراردادهای پیاده‌سازی‌شده را فهرست می‌کند. endpoint نامشخص ساخته یا حدس زده نشده است.

## 1. منبع: LBank Spot API (عمومی)

**مستند رسمی:** <https://www.lbank.com/docs/index.html>  
**میزبان REST:** `https://api.lbkex.com`  
دادهٔ بازار عمومی بدون کلید خصوصی API خوانده می‌شود. این نرم‌افزار هیچ مسیر سفارش/برداشت Spot را فراخوانی نمی‌کند.

### 1.1 فهرست جفت‌ها

`GET /v2/currencyPairs.do`

- پاسخ مورد انتظار: `{result, data: string[], error_code, ts}`؛ هر نماد wire مانند `btc_usdt` است.
- برنامه فقط نمادهای `*_usdt` را در صفحهٔ بازار می‌پذیرد و نمادهای اهرمی `3L/3S/5L/5S` را کنار می‌گذارد.

### 1.2 تیکرهای ۲۴ ساعته

`GET /v2/ticker/24hr.do?symbol=all`

- `data[]`: `symbol`, `ticker.latest`, `ticker.high`, `ticker.low`, `ticker.change`, `ticker.turnover`, `ticker.vol`, `timestamp`.
- `latest` و `turnover` رشته یا عدد قابل تبدیل به عدد هستند؛ `timestamp` میلی‌ثانیه است.
- تغییر همان مقدار `change` پاسخ API نمایش داده می‌شود؛ برنامه آن را به‌صورت درصد گزارش می‌کند و مقدار را در داده خام بازنویسی نمی‌کند.
- ردیف بدون قیمت مثبت، تغییر/حجم متناهی یا زمان معتبر حذف می‌شود.

### 1.3 کندل‌های K-Line

`GET /v2/kline.do?symbol=btc_usdt&size=115&type=hour1&time=<unix-seconds>`

تایم‌فریم‌های استفاده‌شده: `minute15`, `hour1`, `hour4`, `day1`, `minute5`. پارامترهای `symbol`, `size`, `type`, `time` با قرارداد رسمی Spot API هستند. آرایهٔ هر کندل:

`[time_seconds, open, high, low, close, volume]`

برنامه زمان را به میلی‌ثانیه تبدیل، کندل‌های نامعتبر را رد، timestampهای تکراری را یکتا و کندل‌ها را صعودی مرتب می‌کند. کندل بسته‌نشده برای سیگنال نهایی استفاده نمی‌شود.

## 2. منبع: LBank Contract Futures API (عمومی)

**مستند رسمی:** <https://www.lbank.com/en-US/docs/contract.html>  
**میزبان REST:** `https://lbkperp.lbank.com`  
**productGroup:** `SwapU` (USDT-margined swap). اپ کلید خصوصی لازم ندارد و فقط GET عمومی می‌زند.

### 2.1 فهرست مشخصات قرارداد

`GET /cfd/openApi/v1/pub/instrument?productGroup=SwapU`

پاسخ: `{data: Instrument[], error_code, msg, result, success}`. فیلدهای به‌کاررفته: `symbol`, `baseCurrency`, `clearCurrency`, `priceTick`, `volumeTick`, `minOrderVolume`, `minOrderCost`, `needSuspend`, `maxLeverage` و مشخصات قرارداد دیگر.

### 2.2 دادهٔ بازار قرارداد

`GET /cfd/openApi/v1/pub/marketData?productGroup=SwapU`

فیلدهای مصرف‌شده در `data[]`: `symbol`, `lastPrice`, `markedPrice`, `openPrice`, `highestPrice`, `lowestPrice`, `volume`, `turnover`, `fundingRate`/`positionFeeRate`, `instrumentStatus`, `lastTime`, `nextFeeTime`.

نماد اسکن‌پذیر باید در instrument list باشد، USDT تسویه شود، `needSuspend` غیرفعال باشد و ticker قیمت معتبر داشته باشد. قراردادهایی با وضعیت بازار غیر فعال از اسکن فرصت جدا می‌شوند. `instrumentStatus=2` در نمونه پاسخ فعال بود؛ هر تغییر نامعتبر API به‌صورت خطای اسکن ثبت می‌شود.

### 2.3 دفتر سفارش

`GET /cfd/openApi/v1/pub/marketOrder?symbol=BTCUSDT&depth=20`

پاسخ `data.symbol`, `data.asks[]`, `data.bids[]`؛ هر سطح شامل `price`, `volume`, `orders` است. اپ نسخهٔ حاضر ممکن است برای تشخیص تازگی/اطلاعات پایه فید کندلی دریافت نکند؛ دفتر سفارش، کندل یا سیگنال را جایگزین نمی‌کند.

### 2.4 زمان API

`GET /cfd/openApi/v1/pub/getTime` — عمومی. پاسخ نمونه دارای `data` زمان سرور و `error_code=0` بود.

### 2.5 محدودیت مستندات

در مستند رسمی Contract API بررسی‌شده، endpoint عمومی **OHLCV/K-line Futures** مشخص نشده است. مسیر مشابه `.../kline` در آزمایش مستندات با 403 پاسخ داد و به‌عنوان قرارداد معتبر استفاده نمی‌شود. به همین علت: (الف) فهرست و تیکر Futures فقط futures باقی می‌مانند؛ (ب) تحلیل اندیکاتوری Spot با برچسب Spot است؛ (ج) اپ سیگنال اجرای Futures یا قیمت ورود Futures را جعل نمی‌کند.

## 3. رفتار شبکه و خطا

- timeout، status غیر 2xx، JSON نامعتبر، پاسخ بدون داده، نرخ محدود، نماد ناموجود و داده stale باید به وضعیت خطا/بدون داده منجر شود، نه جایگزینی با داده ساختگی.
- برنامهٔ Android فقط HTTPS را می‌پذیرد؛ bridge میزبان‌ها را به `api.lbkex.com` و `lbkperp.lbank.com` و مسیرهای عمومی بالا محدود می‌کند، timeout اتصال/خواندن دارد و پاسخ را حداکثر 8MiB می‌پذیرد.
- سرور توسعه `server/portal_server.mjs` همان دو host را allowlist می‌کند و فقط GET proxy ارائه می‌دهد.
- هیچ کلید خصوصی API در تنظیمات، سورس، log یا درخواست‌های عمومی وجود ندارد.

## 4. قرارداد داخلی موتور تحلیل

### Candle

`{time,open,high,low,close,volume}`؛ `time` درون برنامه epoch milliseconds، OHLC مثبت و متناهی، `high >= open/close`, `low <= open/close`, حجم غیرمنفی.

### Quote

`{symbol,base,price,change,volume,time}`. timestamp منبع با زمان دریافت کلاینت جایگزین نمی‌شود.

### Analysis

`{symbol,tf,source:'LBank Spot',side:'LONG'|'SHORT'|'WAIT',score,entry,stop,target,rr,support,resistance,ind,closedCount,reason,time}`. `WAIT` برنامهٔ معتبر است و نباید به Paper trade تبدیل شود. `LONG/SHORT` صرفاً bias پژوهشی روی داده Spot است.

### اسکنر

برای هر قرارداد واجد شرایط یک نتیجه شامل نماد، قیمت/حجم/funding و status ساخته می‌شود. status ممکن است «نامزد بررسی کندل Spot»، «حجم پایین»، «رد/خطا» باشد. نبود کندل futures صریح ثبت می‌شود و به خروجی Long/Short Futures تبدیل نمی‌شود.

### Paper ledger

محلی و غیرقابل ارسال به صرافی است. مقدار ورود/حد ضرر از تحلیل Spot می‌آید؛ خروج با قیمت Spot آخرین مشاهده‌شده و مفروضات هزینه انجام می‌شود. این شبیه‌سازی معادل futures fill نیست.

## 5. نمونه پاسخ‌های عمومی بررسی‌شده

نمونه پاسخ instrument، futures marketData، futures order book، Spot ticker، pairs و K-line در مستندات رسمی/API در زمان پیاده‌سازی مرور شد. جزئیات محیط و محدودیت شبکه در `docs/fa/STATUS.md` آمده است. داده‌های تستی فقط برای تست و با منبع/زمان مشخص هستند؛ در UI به‌عنوان داده زنده تزریق نمی‌شوند.
