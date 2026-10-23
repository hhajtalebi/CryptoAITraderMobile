import test, {after} from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import net from 'node:net';

let child, base;
async function freePort(){
  const probe=net.createServer();await new Promise((resolve,reject)=>probe.listen(0,'127.0.0.1',resolve).once('error',reject));
  const {port}=probe.address();await new Promise(resolve=>probe.close(resolve));return port;
}
async function start(){
  const port=await freePort();base=`http://127.0.0.1:${port}`;
  child=spawn(process.execPath,['server/portal_server.mjs'],{cwd:new URL('..',import.meta.url),env:{...process.env,PORT:String(port)},stdio:['ignore','pipe','pipe']});
  await new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>reject(new Error('server startup timeout')),5000);
    child.stdout.on('data',chunk=>{if(String(chunk).includes('listening')){clearTimeout(timer);resolve()}});
    child.once('error',e=>{clearTimeout(timer);reject(e)});child.once('exit',code=>{clearTimeout(timer);reject(new Error(`server exited ${code}`))});
  });
}
after(()=>{if(child&&!child.killed)child.kill('SIGTERM')});

test('portal server exposes only the intended public download and sandbox roots',async()=>{
  await start();
  const root=await fetch(base+'/');assert.equal(root.status,200);assert.match(root.headers.get('content-type'),/text\/html/);assert.match(await root.text(),/دانلود نرم‌افزار/);
  const sandbox=await fetch(base+'/sandbox.html');assert.equal(sandbox.status,200);
  const hidden=await fetch(base+'/.git/config');assert.equal(hidden.status,404);
  const source=await fetch(base+'/package.json');assert.equal(source.status,404);
  assert.equal(root.headers.get('x-content-type-options'),'nosniff');
});

test('proxy rejects methods, SSRF hosts, ports and non-public API paths',async()=>{
  const method=await fetch(base+'/api/proxy',{method:'POST'});assert.equal(method.status,405);assert.equal(method.headers.get('allow'),'GET');
  for(const url of ['https://example.com/','http://api.lbkex.com/v2/kline.do','https://api.lbkex.com:444/v2/kline.do','https://api.lbkex.com/private/withdraw.do','https://user@api.lbkex.com/v2/kline.do']){
    const response=await fetch(base+'/api/proxy?url='+encodeURIComponent(url));assert.equal(response.status,400,url);assert.match(await response.text(),/blocked_url/);
  }
});
