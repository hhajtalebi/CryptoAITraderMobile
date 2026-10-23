import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(new URL('../assets/web/index.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'main app script exists');
const context = vm.createContext({
  console, Date, Math, Number, String, Object, Array, Map, Set, Promise, URL,
  Intl, JSON, Error, RegExp, NaN, Infinity, isFinite, parseInt, parseFloat,
  document: {addEventListener() {}}, window: {}, localStorage: {getItem(){return null},setItem(){},removeItem(){}},
  setTimeout(){}, setInterval(){}, clearTimeout(){}, clearInterval(){},
});
vm.runInContext(script, context, {timeout: 1000});
const evaluate = expr => vm.runInContext(expr, context, {timeout: 1000});

function candles({n=240, start=Date.now()-n*3600000, step=3600000, slope=0.08, gapAt=-1}={}) {
  return Array.from({length:n}, (_,i)=>{
    const time=start+i*step+(i>=gapAt&&gapAt>0?step:0);
    const close=100+i*slope+Math.sin(i/5)*1.5;
    return {time,open:close-.2,high:close+.8,low:close-.9,close,volume:1000+(i%9)*50};
  });
}

test('EMA is SMA-seeded and remains aligned with source series', () => {
  const got = evaluate('ema([1,2,3,4,5], 3)');
  assert.equal(got.length, 5);
  assert.ok(Number.isNaN(got[0]) && Number.isNaN(got[1]));
  assert.equal(got[2], 2);
  assert.ok(Math.abs(got[3]-3) < 1e-12);
  assert.ok(Math.abs(got[4]-4) < 1e-12);
});

test('RSI handles monotone, flat and invalid warmup series', () => {
  const rise = evaluate('rsi([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15], 14)');
  const flat = evaluate('rsi(Array(20).fill(7), 14)');
  assert.equal(rise.length,15); assert.ok(Number.isNaN(rise[13])); assert.equal(rise[14],100);
  assert.equal(flat.at(-1),50);
});

test('ATR is finite and positive for valid OHLC candles', () => {
  const cs = candles();
  const out = evaluate(`atr(${JSON.stringify(cs)}, 14)`);
  assert.equal(out.length,cs.length);
  assert.ok(Number.isFinite(out.at(-1)) && out.at(-1)>0);
});

test('closed-candle filter never marks the currently open interval confirmed', () => {
  const now = Date.now();
  const cs = [{time:now-3600000,open:1,high:2,low:.5,close:1.5,volume:3},{time:now-60_000,open:1,high:2,low:.5,close:1.5,volume:3}];
  const got = evaluate(`closedCandles(${JSON.stringify(cs)}, '1hour')`);
  assert.equal(got.length,1);
  assert.equal(got[0].time,cs[0].time);
});

test('analysis refuses insufficient candles rather than emitting a fabricated setup', () => {
  const cs=candles({n:35});
  assert.throws(()=>evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(cs)},null)`),/insufficient_closed_candles/);
});

test('analysis rejects discontinuous candles', () => {
  const cs=candles({n:100,gapAt:75});
  assert.throws(()=>evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(cs)},null)`),/candle_gap/);
});

test('analysis rejects stale candle history', () => {
  const cs=candles({n:100,start:Date.now()-200*3600000});
  assert.throws(()=>evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(cs)},null)`),/stale_candles/);
});

test('analysis output, if directional, has valid-side stop and 2R target', () => {
  const cs=candles({n:240,slope:.16});
  const result=evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(cs)},null)`);
  assert.ok(['LONG','SHORT','WAIT'].includes(result.side));
  assert.ok(result.closedCount>=60);
  assert.ok(Number.isFinite(result.ind.ema20));
  if(result.side==='LONG') {assert.ok(result.stop<result.entry);assert.ok(result.target>result.entry);assert.ok(Math.abs((result.target-result.entry)/(result.entry-result.stop)-2)<1e-8)}
  if(result.side==='SHORT') {assert.ok(result.stop>result.entry);assert.ok(result.target<result.entry);assert.ok(Math.abs((result.entry-result.target)/(result.stop-result.entry)-2)<1e-8)}
});

test('API URL construction preserves query parameters safely', () => {
  const got=evaluate("apiURL('https://lbkperp.lbank.com/cfd/openApi/v1/pub/marketData',{productGroup:'SwapU'})");
  assert.equal(got,'https://lbkperp.lbank.com/cfd/openApi/v1/pub/marketData?productGroup=SwapU');
});

test('backtest returns finite metrics or explicit empty metrics', () => {
  const cs=candles({n:300,slope:.06});
  const r=evaluate(`backtest(${JSON.stringify(cs)})`);
  assert.ok(Number.isInteger(r.trades));
  if(r.trades) {assert.ok(Number.isFinite(r.win));assert.ok(Number.isFinite(r.exp));assert.ok(Number.isFinite(r.dd));assert.ok(r.dd>=0)}
});
