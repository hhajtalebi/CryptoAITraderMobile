import http from 'node:http';
import {readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const allowedHosts = new Set(['api.lbkex.com', 'lbkperp.lbank.com']);
const allowedRoutes = new Map([
  ['api.lbkex.com', new Set(['/v2/currencyPairs.do', '/v2/ticker/24hr.do', '/v2/kline.do'])],
  ['lbkperp.lbank.com', new Set(['/cfd/openApi/v1/pub/instrument', '/cfd/openApi/v1/pub/marketData'])],
]);
const publicRoots = new Set(['download.html', 'sandbox.html', 'assets', 'releases']);
const maxUpstreamBytes = 2 * 1024 * 1024;
const proxyWindows = new Map();
function allowProxy(ip, now=Date.now()) {
  const item=proxyWindows.get(ip);
  if(!item||now-item.start>=60000){proxyWindows.set(ip,{start:now,count:1});return true;}
  item.count++;return item.count<=60;
}
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.json':'application/json; charset=utf-8','.svg':'image/svg+xml','.ttf':'font/ttf','.md':'text/markdown; charset=utf-8','.apk':'application/vnd.android.package-archive','.zip':'application/zip','.txt':'text/plain; charset=utf-8'};
const headers = {
  'x-content-type-options':'nosniff',
  'referrer-policy':'no-referrer',
  'permissions-policy':'camera=(), microphone=(), geolocation=()',
  'content-security-policy':"default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'self' https://api.lbkex.com https://lbkperp.lbank.com; object-src 'none'; base-uri 'self'",
};
function send(res, status, body, extra={}) {
  const bytes = Buffer.isBuffer(body) ? body : Buffer.from(body);
  res.writeHead(status, {...headers, 'content-length':bytes.length, ...extra});
  res.end(bytes);
}
async function readLimited(response) {
  const declared = Number(response.headers.get('content-length'));
  if (Number.isFinite(declared) && declared > maxUpstreamBytes) throw new Error('upstream_response_too_large');
  if (!response.body) return Buffer.alloc(0);
  const reader = response.body.getReader(), chunks=[]; let total=0;
  try {
    while (true) {
      const {done,value}=await reader.read(); if(done) break;
      total += value.byteLength;
      if(total > maxUpstreamBytes) { await reader.cancel(); throw new Error('upstream_response_too_large'); }
      chunks.push(Buffer.from(value));
    }
  } finally { reader.releaseLock(); }
  return Buffer.concat(chunks,total);
}
const server = http.createServer(async (req,res)=>{
  try {
    const u = new URL(req.url, 'http://localhost');
    if (u.pathname === '/api/proxy') {
      if (req.method !== 'GET') return send(res,405,'Method Not Allowed',{'allow':'GET'});
      if (!allowProxy(req.socket.remoteAddress||'unknown')) return send(res,429,JSON.stringify({error:'rate_limited'}),{'content-type':'application/json; charset=utf-8','retry-after':'60'});
      let target;
      try { target = new URL(u.searchParams.get('url') || ''); } catch { return send(res,400,JSON.stringify({error:'invalid_url'}),{'content-type':'application/json; charset=utf-8'}); }
      const routeSet=allowedRoutes.get(target.hostname);
      if (target.protocol !== 'https:' || !allowedHosts.has(target.hostname) || target.port && target.port!=='443' || target.username || target.password || target.hash || !routeSet?.has(target.pathname) || target.search.length>1024) {
        return send(res,400,JSON.stringify({error:'blocked_url'}),{'content-type':'application/json; charset=utf-8'});
      }
      try {
        const upstream=await fetch(target,{method:'GET',redirect:'error',headers:{accept:'application/json','user-agent':'CryptoAITrader/1.1.0 sandbox'},signal:AbortSignal.timeout(12000)});
        const body=await readLimited(upstream);
        return send(res,upstream.status,body,{'content-type':upstream.headers.get('content-type')||'application/json; charset=utf-8','cache-control':'no-store'});
      } catch(error) {
        console.error(`LBank public feed unavailable (${target.hostname}): ${error?.name||error?.message||'network error'}`);
        return send(res,502,JSON.stringify({error:'upstream_unavailable',message:'The LBank public API is not reachable from this environment.'}),{'content-type':'application/json; charset=utf-8','cache-control':'no-store'});
      }
    }
    if(!['GET','HEAD'].includes(req.method)) return send(res,405,'Method Not Allowed',{'allow':'GET, HEAD'});
    const requested=u.pathname==='/'?'/download.html':decodeURIComponent(u.pathname);
    const segments=requested.split('/').filter(Boolean);
    if(!segments.length||segments.some(part=>part.startsWith('.')||part==='node_modules')||!publicRoots.has(segments[0])) return send(res,404,'Not found',{'content-type':'text/plain; charset=utf-8'});
    const target=path.resolve(root,'.'+requested);
    if(!target.startsWith(root+path.sep)) return send(res,404,'Not found',{'content-type':'text/plain; charset=utf-8'});
    const info=await stat(target);if(!info.isFile())return send(res,404,'Not found',{'content-type':'text/plain; charset=utf-8'});
    const extra={'content-type':types[path.extname(target)]||'application/octet-stream','content-length':info.size,'cache-control':'no-store'};
    res.writeHead(200,{...headers,...extra});if(req.method==='HEAD')return res.end();res.end(await readFile(target));
  } catch {
    if(!res.headersSent)send(res,404,'Not found',{'content-type':'text/plain; charset=utf-8'});else res.destroy();
  }
});
const port=Number(process.env.PORT||4173);server.listen(port,'0.0.0.0',()=>console.log(`CryptoAITrader sandbox listening on 0.0.0.0:${port}`));
