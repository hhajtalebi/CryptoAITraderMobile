import http from 'node:http';
import {readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const allowed = new Set(['api.lbkex.com', 'lbkperp.lbank.com']);
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.json':'application/json; charset=utf-8','.svg':'image/svg+xml','.ttf':'font/ttf','.md':'text/markdown; charset=utf-8','.apk':'application/vnd.android.package-archive','.zip':'application/zip'};
const server = http.createServer(async (req,res)=>{
  try {
    const u = new URL(req.url, 'http://localhost');
    if (u.pathname === '/api/proxy') {
      const target = new URL(u.searchParams.get('url') || '');
      if (target.protocol !== 'https:' || !allowed.has(target.hostname) || target.username || target.password || target.hash) {
        res.writeHead(400, {'content-type':'application/json'}); res.end(JSON.stringify({error:'blocked_url'})); return;
      }
      try {
        const upstream = await fetch(target, {headers:{accept:'application/json','user-agent':'CryptoAITrader/1.0.2 sandbox'}, signal:AbortSignal.timeout(15000)});
        const body = await upstream.arrayBuffer();
        res.writeHead(upstream.status, {'content-type':upstream.headers.get('content-type')||'application/json','cache-control':'no-store','access-control-allow-origin':'*'}); res.end(Buffer.from(body)); return;
      } catch (error) {
        console.error(`LBank public feed unavailable (${target.hostname}): ${error?.name || 'network error'}`);
        res.writeHead(502, {'content-type':'application/json; charset=utf-8','cache-control':'no-store'});
        res.end(JSON.stringify({error:'upstream_unavailable', message:'The LBank public API is not reachable from this environment.'}));
        return;
      }
    }
    const requested = u.pathname === '/' ? '/download.html' : decodeURIComponent(u.pathname);
    const target = path.resolve(root, '.' + requested);
    if (!target.startsWith(root + path.sep) && target !== root) { res.writeHead(403); res.end('Forbidden'); return; }
    const info = await stat(target);
    if (!info.isFile()) throw new Error('not_file');
    const body = await readFile(target);
    res.writeHead(200, {'content-type':types[path.extname(target)]||'application/octet-stream','content-length':body.length,'cache-control':'no-store','x-content-type-options':'nosniff'}); res.end(body);
  } catch (e) { res.writeHead(404, {'content-type':'text/plain; charset=utf-8'}); res.end('Not found'); }
});
const port=Number(process.env.PORT||4173); server.listen(port,'0.0.0.0',()=>console.log(`CryptoAITrader sandbox listening on 0.0.0.0:${port}`));
