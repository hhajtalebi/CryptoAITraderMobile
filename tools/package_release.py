#!/usr/bin/env python3
from __future__ import annotations
import os, pathlib, zipfile, hashlib, shutil
ROOT=pathlib.Path(__file__).resolve().parents[1]
VERSION=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
RELEASE=ROOT/'releases'/f'v{VERSION}'
EXCLUDE_DIRS={'.git','node_modules','build','.dart_tool','.gradle','.idea','.vscode','coverage','__pycache__','.pytest_cache','.cache','Pods'}
EXCLUDE_FILES={'CryptoAITrader-mobile-source.zip','package-lock.json.tmp','.DS_Store','local.properties'}
EXCLUDE_SUFFIXES={'.apk','.aab','.idsig','.jks','.keystore','.p12','.pfx','.pem','.key','.p8','.env','.log','.pyc'}

def create_html():
    raw=(ROOT/'assets/web/index.html').read_text(encoding='utf-8')
    raw=raw.replace('src="../brand/logo_mark.png"','src="assets/brand/logo_mark.png"').replace("url('../fonts/","url('assets/fonts/")
    inject=f'''<div style="max-width:900px;margin:14px auto 0;padding:12px 16px;border:1px solid #1d3e55;border-radius:16px;background:linear-gradient(100deg,#0c1d30,#10283a);display:flex;gap:12px;align-items:center;justify-content:space-between;flex-wrap:wrap;font:12px Vazirmatn,system-ui;color:#dff5ff"><span><b>CryptoAITrader v{VERSION}</b> · سندباکس پژوهشی • سفارش واقعی ارسال نمی‌شود</span><span style="display:flex;gap:8px"><a href="releases/v{VERSION}/CryptoAITraderMobile-v{VERSION}.apk" download style="text-decoration:none;padding:8px 13px;border-radius:10px;background:linear-gradient(110deg,#1287f2,#16cfb4);color:#05111b;font-weight:800">⬇ دانلود APK اندروید</a><a href="releases/v{VERSION}/CryptoAITraderMobile-v{VERSION}-Source.zip" download style="text-decoration:none;padding:8px 13px;border-radius:10px;border:1px solid #314760;color:#c4d9ec">دانلود ZIP سورس</a></span></div>'''
    raw=raw.replace('<div class="layout">',inject+'<div class="layout">',1)
    (ROOT/'sandbox.html').write_text(raw,encoding='utf-8')

def zip_source(path):
    path.parent.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=8) as z:
        for base, dirs, files in os.walk(ROOT):
            rel=pathlib.Path(base).relative_to(ROOT)
            dirs[:]=[d for d in dirs if d not in EXCLUDE_DIRS and d!='.git']
            for name in files:
                src=pathlib.Path(base)/name
                rp=src.relative_to(ROOT)
                if any(part in EXCLUDE_DIRS or part=='.git' for part in rp.parts): continue
                if name in EXCLUDE_FILES or name.startswith('.env') or name.lower() in {'credentials.json','secrets.json','keystore.properties','secret.properties'} or src.suffix.lower() in EXCLUDE_SUFFIXES: continue
                if rp.parts and rp.parts[0]=='releases': continue
                if rp == pathlib.Path('CryptoAITrader-mobile-source.zip'): continue
                z.write(src, pathlib.Path('CryptoAITrader')/rp)
    with zipfile.ZipFile(path) as z:
        bad=z.testzip()
        if bad: raise SystemExit(f'ZIP integrity failed at {bad}')
        names=z.namelist()
        needed=['CryptoAITrader/README.md','CryptoAITrader/API.md','CryptoAITrader/sandbox.html','CryptoAITrader/VERSION','CryptoAITrader/package.json','CryptoAITrader/package-lock.json','CryptoAITrader/pubspec.yaml','CryptoAITrader/assets/web/index.html','CryptoAITrader/android-native/src/app/cryptoaitrader/MainActivity.java','CryptoAITrader/tools/build_release.py','CryptoAITrader/tools/package_release.py','CryptoAITrader/tests/market_engine.test.mjs','CryptoAITrader/tests/server_security.test.mjs','CryptoAITrader/docs/fa/INSTALLATION.md']
        missing=[x for x in needed if x not in names]
        if missing: raise SystemExit(f'ZIP missing files: {missing}')
        if any('/.git/' in x or '/node_modules/' in x for x in names): raise SystemExit('ZIP unexpectedly includes excluded directories')
        if any(x.lower().endswith(('.jks','.keystore','.p12','.pfx','.pem','.key','.p8','.env','.apk','.idsig')) or pathlib.PurePosixPath(x).name.lower() in {'credentials.json','secrets.json','keystore.properties','secret.properties'} for x in names): raise SystemExit('ZIP includes a signing key, secret or generated APK artifact')
        if 'CryptoAITrader/.gitignore' not in names: raise SystemExit('ZIP missing repository ignore rules')
    return path.stat().st_size

def main():
    create_html()
    RELEASE.mkdir(parents=True,exist_ok=True)
    apk=RELEASE/f'CryptoAITraderMobile-v{VERSION}.apk'
    if not apk.exists() or apk.stat().st_size<100000: raise SystemExit('Release APK not found or invalid; build it first')
    src=RELEASE/f'CryptoAITraderMobile-v{VERSION}-Source.zip'
    src_size=zip_source(src)
    # Human-friendly self-contained release bundle (APK + sandbox + quickstart + checksums)
    bundle=RELEASE/f'CryptoAITraderMobile-v{VERSION}-Release.zip'
    with zipfile.ZipFile(bundle,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
        for f in [apk,RELEASE/'RELEASE_NOTES.md',RELEASE/'APK_SHA256.txt',RELEASE/'APK_VERIFICATION.txt']:
            if f.exists(): z.write(f, pathlib.Path('releases')/f'v{VERSION}'/f.name)
        for f in [ROOT/'sandbox.html',ROOT/'README.md',ROOT/'API.md']:
            if f.exists(): z.write(f, f.name)
    with zipfile.ZipFile(bundle) as z:
        if z.testzip(): raise SystemExit('release bundle integrity failed')
        if 'sandbox.html' not in z.namelist() or f'releases/v{VERSION}/CryptoAITraderMobile-v{VERSION}.apk' not in z.namelist(): raise SystemExit('release bundle is missing HTML or APK')
    print('SANDBOX_HTML',ROOT/'sandbox.html',(ROOT/'sandbox.html').stat().st_size)
    print('SOURCE_ZIP',src,src_size)
    print('RELEASE_ZIP',bundle,bundle.stat().st_size)
    print('APK',apk,apk.stat().st_size,hashlib.sha256(apk.read_bytes()).hexdigest())
if __name__=='__main__': main()
