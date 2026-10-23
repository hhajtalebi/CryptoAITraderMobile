# قواعد استراتژی نسخهٔ 1.1.0

این نسخه یک rule-based پژوهشی است، نه AI آموزش‌دیده یا توصیهٔ مالی. قواعد از EMA20/50، RSI14، ATR14، MACD histogram، شکست range و (در 15m/1h) توافق روند 4H استفاده می‌کنند. نسبت هدف اولیه 2R و stop بر پایهٔ ATR/range است؛ ممکن است سیگنال WAIT باشد.

بک‌تست همان `signalDecision` را روی prefix candle استفاده می‌کند؛ ورود در کندل بعد، stop-first در برخورد مبهم، adverse gap، commission و slippage. Dataset عمومی کوتاه است، نرخ‌ها فرضی‌اند و نتایج گذشته آینده را پیش‌بینی نمی‌کنند.
