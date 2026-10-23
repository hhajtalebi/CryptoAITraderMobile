# لاگ و عیب‌یابی

لاگ‌های وب شامل timestamp، سطح، ماژول و پیام خلاصه است؛ حداکثر 250 رخداد در حافظهٔ نشست نگه‌داری می‌شود. پیام‌ها نباید حاوی URL محرمانه، API key یا اطلاعات کاربری باشند. مسیر History → System logs نمایش می‌دهد و JSON export سوابق قابل خروجی را شامل می‌کند.

در این نسخه rotating log file دائمی یا ارسال crash report وجود ندارد. خطاهای شبکه در UI نشان داده و برای نشست log می‌شوند؛ برای تشخیص بیشتر، network tab مرورگر/Android WebView و `releases/v1.0.0/APK_VERIFICATION.txt` بررسی شود.
