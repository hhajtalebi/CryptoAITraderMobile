# API contract — CryptoAITrader v1.1.0

This document describes only public endpoints called by the current WebView app. API keys and authenticated endpoints are not used.

## Spot public REST — `https://api.lbkex.com`

- `GET /v2/currencyPairs.do`
- `GET /v2/ticker/24hr.do?symbol=all`
- `GET /v2/kline.do?symbol=btc_usdt&size=<count>&type=<timeframe>&time=<unix-seconds>`

The app normalizes epoch seconds/milliseconds, validates finite positive OHLC, `high >= open/close/low`, `low <= open/close/high`, non-negative volume, ascending unique timestamps and contiguous intervals. Only closed candles feed live decisions. Invalid series, stale candles, future bars or missing history are rejected rather than filled synthetically.

## Futures public REST — `https://lbkperp.lbank.com`

- `GET /cfd/openApi/v1/pub/instrument?productGroup=SwapU`
- `GET /cfd/openApi/v1/pub/marketData?productGroup=SwapU`

These populate the Futures contract/status/funding/turnover scanner only. The source code does not use private endpoints or Futures order routes. A public OHLCV Futures endpoint is not confirmed in the reviewed official docs; Futures candle signals are therefore not generated. Spot candles are not relabelled Futures.

## Web proxy / Android bridge

- Node proxy accepts GET only, HTTPS, exact hostname, default/443 port and exact read-only public paths above; each client is limited to 60 proxy requests/minute, the upstream response body is limited to 2 MiB and fetch times out. Redirects, credentials, fragments and other paths/hosts are blocked.
- Android `PublicApiBridge` accepts GET HTTPS only, exact hosts/paths, no nonstandard port or redirect, with connect/read timeouts and an 8 MiB response cap.
- The browser uses same-origin `/api/proxy`; direct API fetch is reserved for a `file://` sandbox and still validates the URL against the exact allowlist.

## Internal market / signal records

Candle: `{time,open,high,low,close,volume}` with epoch milliseconds. Quote includes exchange timestamp. Signal fields contain `source:'LBank Spot'`, `tf`, bias (`LONG/SHORT/WAIT`), stop/target and a bounded evidence score (not a probability).

## Explicitly out of scope

No live orders, withdrawals, API credentials, exchange wallet, autonomous trading or trained AI inference. Paper trades are local simulator records. Spot short entries are disallowed by the current paper UI.
