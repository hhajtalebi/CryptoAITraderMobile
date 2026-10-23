# CryptoAITrader v1.1.0 — Research sandbox release

- `versionName`: `1.1.0`; Android `versionCode`: `10100`; package: `app.cryptoaitrader`.
- Android minSdk 21 / targetSdk 34. Built from the Java/WebView Android shell; no Flutter runtime dependency in the APK.
- Spot candle analysis and the rolling backtest share a validated decision rule. Backtests are Spot LONG-only, next-candle-entry, stop-first, cost-aware, and report the first 70% as train and last 30% as out-of-sample. Out-of-sample is chronological evaluation, not proof of predictive performance.
- Assumed backtest fees and slippage are configurable; defaults are 0.1% per side and 0.04% per side respectively. They are not guaranteed exchange costs.
- OHLC, timestamps, intervals, stale/future candles, and higher-timeframe closed-candle confirmation are validated; unsupported/missing data produces an explicit rejection, never synthetic market data.
- Paper mode is local Spot-LONG simulation only. Position size is constrained by available cash after estimated entry fees/slippage; short Spot entries are rejected.
- Analysis/event/log history persists locally and can be exported as JSON, CSV, JSONL, or TXT. CSV text fields are protected against spreadsheet-formula injection.
- Public proxy and Android bridge enforce exact HTTPS LBank host/path allowlists; no private credentials or trading endpoints are used.

## Verification record

- `npm run build:ui`: passed.
- `npm test`: 25/25 passed (Node test suite, including market-engine, regression, persistence/export, and proxy-security tests).
- Android APK build: passed with the local Android SDK toolchain. The APK signature verified with v1, v2, and v3 schemes; manifest reports package `app.cryptoaitrader`, versionCode `10100`, minSdk 21 and targetSdk 34.
- Signer: local non-production evaluation certificate; SHA-256 fingerprint `3967eee3ed539cdc48e717645c007000ac211c5e19e06b2a9b492b7d5539b902`. This is not a Play Store/production signing key.
- APK SHA-256: `16dd5d0c2af3864e227d0a275a950e25227a66115e43fce10c3cf16811d4bd4f`.
- Installation on a physical Android device or emulator was not available in this environment; signature and manifest checks do not establish install/runtime success.
