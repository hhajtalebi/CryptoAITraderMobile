import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(new URL('../assets/web/index.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'main app script exists');
const storage = new Map();
const localStorage = {getItem(k){return storage.has(k)?storage.get(k):null},setItem(k,v){storage.set(k,String(v))},removeItem(k){storage.delete(k)}};
const context = vm.createContext({
  console, Date, Math, Number, String, Object, Array, Map, Set, Promise, URL, Blob,
  Intl, JSON, Error, RegExp, NaN, Infinity, isFinite, parseInt, parseFloat,
  document: {addEventListener() {}}, window: {}, localStorage,
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
  const cs=candles({n:240,slope:.16}),h4=candles({n:120,start:Date.now()-121*14400000,step:14400000});
  const result=evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(cs)},${JSON.stringify(h4)})`);
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
  const cs=candles({n:300,slope:.06}),h4=candles({n:140,start:Date.now()-141*14400000,step:14400000});
  const r=evaluate(`backtest(${JSON.stringify(cs)},'1hour',${JSON.stringify(h4)})`);
  assert.ok(Number.isInteger(r.trades));
  if(r.trades) {assert.ok(Number.isFinite(r.win));assert.ok(Number.isFinite(r.exp));assert.ok(Number.isFinite(r.dd));assert.ok(r.dd>=0)}
});


test('live analysis and backtest share the same validated decision rule across supported timeframes', () => {
  const now=Date.now();
  for(const [tf,step] of [['15min',900000],['1hour',3600000],['4hour',14400000],['day1',86400000]]){
    const cs=candles({n:120,start:now-121*step,step,slope:.14});
    const h4=candles({n:120,start:now-121*14400000,step:14400000,slope:.14});
    const higher=step<14400000?h4:[];
    const live=evaluate(`analyzeSpot('BTC/USDT',${JSON.stringify(tf)},${JSON.stringify(cs)},${JSON.stringify(higher)})`);
    const filteredHigher=step<14400000?evaluate(`validateCandleSeries(${JSON.stringify(higher)},'4hour').filter(c=>c.time+TF['4hour'].ms<=${JSON.stringify(cs.at(-1).time+step)})`):[];
    const same=evaluate(`signalDecision(validateCandleSeries(${JSON.stringify(cs)},${JSON.stringify(tf)}),${JSON.stringify(tf)},${JSON.stringify(filteredHigher)})`);
    assert.equal(live.side,same.side);assert.equal(live.entry,same.entry);assert.equal(live.stop,same.stop);assert.equal(live.target,same.target);
    const result=evaluate(`backtest(${JSON.stringify(cs)},${JSON.stringify(tf)},${JSON.stringify(higher)},{now:${now}})`);
    assert.equal(result.tf,tf);assert.equal(result.train.trades+result.outOfSample.trades,result.trades-result.details.filter(x=>x.split==='boundary').length);
    assert.ok(result.details.every(x=>x.entryTime>x.signalTime&&x.exitTime>=x.entryTime));
  }
});

test('candle validation rejects future values and malformed OHLC instead of silently using them', () => {
  const now=Date.now(),cs=candles({n:80,start:now-82*3600000});
  const bad=cs.map(x=>({...x}));bad[30].high=bad[30].low-.1;
  assert.throws(()=>evaluate(`validateCandleSeries(${JSON.stringify(bad)},'1hour')`),/invalid_candle/);
  const future=[...cs,{...cs.at(-1),time:now+3*3600000}];
  assert.throws(()=>evaluate(`validateCandleSeries(${JSON.stringify(future)},'1hour')`),/invalid_candle/);
});

test('barrier resolver is stop-first and models adverse gaps', () => {
  const both=evaluate("resolveBarrierExit('LONG',{open:100,high:112,low:88,close:105},90,110)");
  assert.deepEqual(JSON.parse(JSON.stringify(both)),{reason:'stop',price:90});
  const gap=evaluate("resolveBarrierExit('LONG',{open:85,high:92,low:80,close:87},90,110)");
  assert.deepEqual(JSON.parse(JSON.stringify(gap)),{reason:'stop',price:85});
});

test('shared fill economics charges round-trip commission and adverse slippage', () => {
  const plain=evaluate("tradeEconomics('LONG',1,100,110,0,0)");
  const costed=evaluate("tradeEconomics('LONG',1,100,110,.001,.001)");
  assert.equal(plain.net,10);assert.ok(costed.entryFill>100);assert.ok(costed.exitFill<110);
  assert.ok(costed.fees>0);assert.ok(costed.net<plain.net);
  assert.throws(()=>evaluate("tradeEconomics('BUY',1,100,110,.001,.001)"),/invalid_trade_economics/);
});

test('paper position open/close uses risk sizing and the same fee/slippage model', () => {
  const analysis={symbol:'BTC/USDT',source:'LBank Spot',side:'LONG',entry:100,stop:98,target:104};
  const order=evaluate(`createPaperPosition(${JSON.stringify(analysis)},10000,.005,{feeRate:.001,slippage:.0004},1234)`);
  assert.ok(order.qty>0);assert.ok(Math.abs(order.risk-50)<1e-12);
  const settled=evaluate(`settlePaperPosition(${JSON.stringify(order.position)},104,5678)`);
  assert.equal(settled.closedAt,5678);assert.ok(settled.fees>0);assert.ok(settled.pnl<4*order.qty);
  assert.throws(()=>evaluate(`createPaperPosition(${JSON.stringify({...analysis,side:'SHORT'})},10000,.005)`),/spot_short_not_supported/);
});

test('history survives reload from durable localStorage state', () => {
  evaluate("APP.analysisHistory=[{symbol:'BTC/USDT',side:'LONG',score:70}];APP.history.events=[{kind:'PAPER_OPEN'}];APP.history.logs=[{level:'INFO',message:'saved'}];persistHistory()");
  const saved=evaluate('loadHistoryState()');
  assert.equal(saved.analysis[0].symbol,'BTC/USDT');assert.equal(saved.events[0].kind,'PAPER_OPEN');assert.equal(saved.logs[0].message,'saved');
});

test('backtest result labels train and out-of-sample separately and never enters before signal close', () => {
  const now=Date.now(),step=3600000,cs=candles({n:220,start:now-221*step,slope:.16});
  const h4=candles({n:140,start:now-141*14400000,step:14400000,slope:.16});
  const result=evaluate(`backtest(${JSON.stringify(cs)},'1hour',${JSON.stringify(h4)},{now:${now}})`);
  assert.ok(result.train&&result.outOfSample);assert.ok(result.splitIndex>0&&result.splitIndex<cs.length);
  for(const trade of result.details){assert.ok(trade.signalTime<trade.entryTime);assert.equal(trade.side,'LONG');assert.ok(trade.entry*trade.qty*1.001<=trade.equityBefore+1e-9);assert.ok(Number.isFinite(trade.grossR));assert.ok(Number.isFinite(trade.feesR));assert.ok(Number.isFinite(trade.netR));}
});

test('adding a later candle cannot change a prior rolling signal decision', () => {
  const now=Date.now(),step=3600000,cs=candles({n:180,start:now-181*step,slope:.19}),prefix=cs.slice(0,150),h4=candles({n:120,start:now-481*step,step:14400000,slope:.19});
  const higher=evaluate(`validateCandleSeries(${JSON.stringify(h4)},'4hour').filter(c=>c.time+TF['4hour'].ms<=${JSON.stringify(prefix.at(-1).time+step)})`);
  const before=evaluate(`signalDecision(${JSON.stringify(prefix)},'1hour',${JSON.stringify(higher)})`);
  const after=evaluate(`signalDecision(${JSON.stringify(cs.slice(0,150))},'1hour',${JSON.stringify(higher)})`);
  assert.equal(after.side,before.side);assert.equal(after.entry,before.entry);assert.equal(after.stop,before.stop);assert.equal(after.target,before.target);
});

test('CSV, JSONL and TXT exports serialize selected history records safely', () => {
  const rows=[{recordType:'log',message:'text, with "quotes"',context:{x:1},formula:'=1+1'},{recordType:'log',message:'second'}];
  const csv=evaluate(`serializeHistory('csv',{},${JSON.stringify(rows)})`);
  assert.match(csv.content,/"text, with ""quotes"""/);assert.match(csv.content,/"'=1\+1"/);assert.equal(csv.ext,'csv');
  const jsonl=evaluate(`serializeHistory('jsonl',{},${JSON.stringify(rows)})`);
  assert.equal(jsonl.content.split('\n').length,2);assert.equal(JSON.parse(jsonl.content.split('\n')[0]).context.x,1);
  const txt=evaluate(`serializeHistory('txt',{},${JSON.stringify(rows)})`);assert.match(txt.content,/recordType: log/);
  assert.throws(()=>evaluate("serializeHistory('xml',{},[])"),/unsupported_export_format/);
});

test('lower-timeframe analysis ignores an unclosed 4H candle even if its values are extreme', () => {
  const now=Date.now(),step=3600000,base=candles({n:120,start:now-121*step,step,slope:.12});
  const four=candles({n:100,start:now-401*step,step:14400000,slope:.11});
  const openHigher={...four.at(-1),time:four.at(-1).time+14400000,open:1,high:1e9,low:1,close:1e8,volume:1e12};
  const a=evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(base)},${JSON.stringify(four)})`);
  const b=evaluate(`analyzeSpot('BTC/USDT','1hour',${JSON.stringify(base)},${JSON.stringify([...four,openHigher])})`);
  assert.equal(b.side,a.side);assert.equal(b.score,a.score);assert.equal(b.entry,a.entry);assert.equal(b.stop,a.stop);
});

test('paper size never exceeds available cash after estimated entry costs', () => {
  const signal={symbol:'BTC/USDT',source:'LBank Spot',side:'LONG',entry:100,stop:99.99,target:100.02};
  const order=evaluate(`createPaperPosition(${JSON.stringify(signal)},1000,.01,{feeRate:.001,slippage:.0004},1)`);
  assert.ok(order.position.qty*order.position.entry*(1+order.position.slippage)*(1+order.position.feeRate)<=1000+1e-9);
});

test('epoch normalization accepts seconds and milliseconds', () => {
  const ms=1700000000000;
  assert.equal(evaluate(`epochMillis(${ms/1000})`),ms);assert.equal(evaluate(`epochMillis(${ms})`),ms);
});

test('public API URL allowlist accepts only exact HTTPS read endpoints', () => {
  assert.equal(evaluate("validatePublicApiUrl('https://api.lbkex.com/v2/kline.do?symbol=btc_usdt').hostname"),'api.lbkex.com');
  assert.equal(evaluate("validatePublicApiUrl('https://lbkperp.lbank.com/cfd/openApi/v1/pub/marketData?productGroup=SwapU').hostname"),'lbkperp.lbank.com');
  for(const url of ['http://api.lbkex.com/v2/kline.do','https://api.lbkex.com:444/v2/kline.do','https://api.lbkex.com/v2/private.do','https://evil.example/v2/kline.do']){
    assert.throws(()=>evaluate(`validatePublicApiUrl(${JSON.stringify(url)})`),/blocked_public_api_url/);
  }
});
