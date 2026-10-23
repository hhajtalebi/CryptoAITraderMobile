#!/usr/bin/env python3
"""Build, sign, verify and stage a reproducible web-shell Android APK."""
from __future__ import annotations
import hashlib, os, pathlib, shutil, subprocess, sys, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'releases' / 'v1.0.0'
TMP = pathlib.Path('/tmp/cryptoaitrader-build')
APKTOOL = pathlib.Path('/opt/android-sdk/tools')
JAVA = pathlib.Path('/opt/android-sdk/jdk/bin/java')
KEYTOOL = pathlib.Path('/opt/android-sdk/jdk/bin/keytool')
AAPT = APKTOOL / 'aapt'
ANDROID_JAR = APKTOOL / 'android.jar'
ECJ = APKTOOL / 'ecj.jar'
D8 = APKTOOL / 'd8.jar'
APKSIGNER = APKTOOL / 'apksigner.jar'


def run(args: list[str], **kwargs) -> str:
    print('+', ' '.join(map(str, args)))
    p = subprocess.run(list(map(str, args)), cwd=ROOT, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **kwargs)
    if p.stdout:
        print(p.stdout.strip())
    return p.stdout


def main() -> None:
    version = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    if version != '1.0.0':
        raise SystemExit(f'Unexpected release version: {version}')
    for tool in [JAVA, KEYTOOL, AAPT, ANDROID_JAR, ECJ, D8, APKSIGNER]:
        if not tool.exists():
            raise SystemExit(f'Required Android build tool missing: {tool}')
    shutil.rmtree(TMP, ignore_errors=True)
    (TMP / 'classes').mkdir(parents=True)
    (TMP / 'dex').mkdir()
    OUT.mkdir(parents=True, exist_ok=True)
    unsigned = TMP / 'CryptoAITrader-v1.0.0-unsigned.apk'
    signed = OUT / 'CryptoAITrader-v1.0.0.apk'
    run([AAPT, 'package', '-f', '-M', ROOT / 'android-native/AndroidManifest.xml', '-S', ROOT / 'android-native/res', '-A', ROOT / 'assets', '-I', ANDROID_JAR, '--min-sdk-version', '24', '--target-sdk-version', '35', '--version-code', '10000', '--version-name', version, '-F', unsigned])
    run([JAVA, '-jar', ECJ, '-source', '8', '-target', '8', '-bootclasspath', ANDROID_JAR, '-d', TMP / 'classes', ROOT / 'android-native/src/app/cryptoaitrader/MainActivity.java'])
    run([JAVA, '-cp', D8, 'com.android.tools.r8.D8', '--min-api', '24', '--lib', ANDROID_JAR, '--output', TMP / 'dex', TMP / 'classes/app/cryptoaitrader/MainActivity.class'])
    with zipfile.ZipFile(unsigned, 'a', compression=zipfile.ZIP_DEFLATED) as z:
        z.write(TMP / 'dex/classes.dex', 'classes.dex')
    keystore = TMP / 'sandbox-release.jks'
    run([KEYTOOL, '-genkeypair', '-keystore', keystore, '-storepass', 'changeit', '-keypass', 'changeit', '-alias', 'cryptoaitrader-sandbox', '-dname', 'CN=CryptoAITrader Sandbox, OU=Evaluation, O=CryptoAITrader, L=Frankfurt, ST=Hesse, C=DE', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '3650'])
    run([JAVA, '-jar', APKSIGNER, 'sign', '--ks', keystore, '--ks-pass', 'pass:changeit', '--key-pass', 'pass:changeit', '--out', signed, unsigned])
    verification = run([JAVA, '-jar', APKSIGNER, 'verify', '--verbose', '--print-certs', signed])
    badging = run([AAPT, 'dump', 'badging', signed])
    if "package: name='app.cryptoaitrader'" not in badging or "versionName='1.0.0'" not in badging or "sdkVersion:'24'" not in badging or "targetSdkVersion:'35'" not in badging:
        raise SystemExit('APK manifest validation failed')
    if 'Verifies' not in verification:
        raise SystemExit('APK signature verification failed')
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
