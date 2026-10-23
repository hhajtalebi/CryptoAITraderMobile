# وضعیت تحویل v1.0.0

## انجام‌شده

- فایل HTML واقعی sandbox، UI RTL/English و گرافیک اختصاصی پیوست کاربر.
- APK Android ARM64-independent Java/WebView shell با min SDK 24، target 35، Java bridge محدود.
- فید public LBank Spot tickers/pairs/kline و Contract Futures instrument/marketData/orderbook/time طبق مستندات رسمی بررسی‌شده.
- جدا بودن Spot/Futures در UI و داده.
- جستجو، sort، واچ‌لیست، اسکن قراردادها، نمودار، اندیکاتورها، سیگنال Spot پژوهشی، Paper ledger local، history/log export و backtest نمونه.
- 10 تست واحد Node سبز و بررسی امضای APK/manifest.
- README و مستندات فارسی/API/version changelog.

## تکمیل‌نشده/محدودیت

- endpoint public futures candles تأیید نشد؛ تحلیل کندلی futures و اسکن سیگنال futures در دسترس نیست.
- سفارش واقعی، برداشت، اتصال private key، funding/liq simulation و background monitor نیست.
- Paper Trading آموزشی است و full execution simulator نیست.
- AI inference داخلی یا ادعای ML وجود ندارد.
- بک‌تست به بازه کندل‌های عمومی محدود و اندیکاتور ثابت است؛ performance validation کافی نیست.
- UI تاریخچه/log در v1.0.0 تا reload session-limited است؛ Paper/watchlist در localStorage است.
- شبکهٔ sandbox developer تنها برخی hostهای خروجی را اجازه می‌دهد؛ API live از محیط اجرای فعلی end-to-end قابل تضمین نیست.
- APK روی گوشی یا emulator فیزیکی نصب/اجرا نشده است؛ خود امضای فایل و manifest اعتبارسنجی شدند.
- فایل‌های Flutter/Dart prototype قبلی در سورس نگه داشته شده‌اند اما APK تحویلی آن کد را اجرا نمی‌کند.
