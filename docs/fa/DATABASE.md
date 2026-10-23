# ذخیره‌سازی و ماندگاری

نسخهٔ WebView 1.1.0 از localStorage همان origin استفاده می‌کند:
- `cait.watch`: واچ‌لیست.
- `cait.paper`: equity، پوزیشن‌های paper، رویدادهای paper.
- `cait.history`: حداکثر 200 تحلیل، 500 رویداد و 500 لاگ.

آرایه‌ها در زمان بارگذاری sanity-check و محدود می‌شوند. خطا/سقف quota به‌صورت صریح ثبت می‌شود؛ تضمین storage در حالت private browsing یا پاک‌کردن داده وجود ندارد. هیچ اطلاعاتی به cloud یا دیتابیس server ارسال نمی‌شود.

Flutter prototype موجود در `lib/core/data/database.dart` دارای SQLite مستقل است اما جزو APK Java/WebView نیست.
