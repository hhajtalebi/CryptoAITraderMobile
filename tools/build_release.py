#!/usr/bin/env python3
"""Build, sign, verify and stage a reproducible web-shell Android APK."""
from __future__ import annotations
import hashlib, os, pathlib, shutil, subprocess, sys, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
VERSION = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
OUT = ROOT / 'releases' / f'v{VERSION}'
TMP = pathlib.Path('/tmp/cryptoaitrader-build')
KEYSTORE = pathlib.Path(os.environ.get('CRYPTOAI_KEYSTORE', '/opt/android-sdk/cryptoaitrader-release.jks'))
KEY_ALIAS = os.environ.get('CRYPTOAI_KEY_ALIAS', 'cryptoaitrader-sandbox')
VERSION_CODE = int(VERSION.split('.')[0]) * 10000 + int(VERSION.split('.')[1]) * 100 + int(VERSION.split('.')[2])
APKTOOL = pathlib.Path('/opt/android-sdk/tools')
JAVA = pathlib.Path('/opt/android-sdk/jdk/bin/java')
KEYTOOL = pathlib.Path('/opt/android-sdk/jdk/bin/keytool')
AAPT = APKTOOL / 'aapt'
ANDROID_JAR = APKTOOL / 'android.jar'
ECJ = APKTOOL / 'ecj.jar'
D8 = APKTOOL / 'd8.jar'
APKSIGNER = APKTOOL / 'apksigner.jar'


def run(args: list[str], **kwargs) -> str:
    print('+', ' '.join('pass:<redacted>' if str(arg).startswith('pass:') else str(arg) for arg in args))
    p = subprocess.run(list(map(str, args)), cwd=ROOT, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **kwargs)
    if p.stdout:
        print(p.stdout.strip())
    return p.stdout


def main() -> None:
    version = VERSION
    if len(version.split('.')) != 3 or not all(part.isdigit() for part in version.split('.')):
        raise SystemExit(f'Invalid semantic release version: {version}')
    for tool in [JAVA, KEYTOOL, AAPT, ANDROID_JAR, ECJ, D8, APKSIGNER]:
        if not tool.exists():
            raise SystemExit(f'Required Android build tool missing: {tool}')
    shutil.rmtree(TMP, ignore_errors=True)
    (TMP / 'classes').mkdir(parents=True)
    (TMP / 'dex').mkdir()
    OUT.mkdir(parents=True, exist_ok=True)
    unsigned = TMP / f'CryptoAITraderMobile-v{version}-unsigned.apk'
    signed = OUT / f'CryptoAITraderMobile-v{version}.apk'
    run([AAPT, 'package', '-f', '-M', ROOT / 'android-native/AndroidManifest.xml', '-S', ROOT / 'android-native/res', '-A', ROOT / 'assets', '-I', ANDROID_JAR, '--min-sdk-version', '21', '--target-sdk-version', '34', '--version-code', str(VERSION_CODE), '--version-name', version, '-F', unsigned])
    run([JAVA, '-jar', ECJ, '-source', '8', '-target', '8', '-bootclasspath', ANDROID_JAR, '-d', TMP / 'classes', ROOT / 'android-native/src/app/cryptoaitrader/MainActivity.java'])
    run([JAVA, '-cp', D8, 'com.android.tools.r8.D8', '--min-api', '21', '--lib', ANDROID_JAR, '--output', TMP / 'dex', TMP / 'classes/app/cryptoaitrader/MainActivity.class'])
    with zipfile.ZipFile(unsigned, 'a', compression=zipfile.ZIP_DEFLATED) as z:
        z.write(TMP / 'dex/classes.dex', 'classes.dex')
    keystore = KEYSTORE
    store_password = os.environ.get('CRYPTOAI_STORE_PASSWORD')
    key_password = os.environ.get('CRYPTOAI_KEY_PASSWORD')
    if not keystore.is_file(): raise SystemExit(f'Signing keystore is not present outside the repository: {keystore}')
    if not store_password or not key_password: raise SystemExit('Set CRYPTOAI_STORE_PASSWORD and CRYPTOAI_KEY_PASSWORD in the local build environment; never commit them.')
    idsig = signed.with_name(signed.name + '.idsig')
    idsig.unlink(missing_ok=True)
    run([JAVA, '-jar', APKSIGNER, 'sign', '--v1-signing-enabled', 'true', '--v2-signing-enabled', 'true', '--v3-signing-enabled', 'true', '--v4-signing-enabled', 'false', '--ks', keystore, '--ks-key-alias', KEY_ALIAS, '--ks-pass', f'pass:{store_password}', '--key-pass', f'pass:{key_password}', '--out', signed, unsigned])
    verification = run([JAVA, '-jar', APKSIGNER, 'verify', '--verbose', '--print-certs', signed])
    badging = run([AAPT, 'dump', 'badging', signed])
    if "package: name='app.cryptoaitrader'" not in badging or f"versionName='{version}'" not in badging or f"versionCode='{VERSION_CODE}'" not in badging or "sdkVersion:'21'" not in badging or "targetSdkVersion:'34'" not in badging:
        raise SystemExit('APK manifest validation failed')
    required_schemes = ['Verified using v1 scheme (JAR signing): true', 'Verified using v2 scheme (APK Signature Scheme v2): true', 'Verified using v3 scheme (APK Signature Scheme v3): true']
    if any(marker not in verification for marker in required_schemes):
        raise SystemExit('APK must verify for v1/v2/v3 on its declared minimum Android API')
    size = signed.stat().st_size
    if size <= 100_000:
        raise SystemExit(f'APK unexpectedly small: {size}')
    digest = hashlib.sha256(signed.read_bytes()).hexdigest()
    (OUT / 'APK_SHA256.txt').write_text(f'{digest}  {signed.name}\n', encoding='utf-8')
    (OUT / 'APK_VERIFICATION.txt').write_text(verification + '\n\n' + badging, encoding='utf-8')
    shutil.copy2(ROOT / 'RELEASE_NOTES.md', OUT / 'RELEASE_NOTES.md')
    print(f'APK_OK path={signed} size={size} sha256={digest}')

if __name__ == '__main__':
    main()
