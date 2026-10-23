import {readFile} from 'node:fs/promises';
import {writeFile, unlink} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
const html = await readFile(new URL('../assets/web/index.html', import.meta.url), 'utf8');
const match = html.match(/<script>([\s\S]*?)<\/script>/);
if (!match) throw new Error('inline application script missing');
const temp='/tmp/cryptoaitrader-inline-check.js';
await writeFile(temp,match[1]);
const check=spawnSync(process.execPath,['--check',temp],{encoding:'utf8'});
await unlink(temp);
if(check.status!==0) {process.stderr.write(check.stderr||check.stdout);process.exit(check.status||1)}
console.log(`UI syntax OK (${match[1].length} JavaScript characters)`);
