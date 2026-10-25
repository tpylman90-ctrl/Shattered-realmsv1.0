"""Apply persistent signing when the four repository secrets are configured."""
import base64, os, subprocess
from pathlib import Path

names = ['KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_PASSWORD', 'KEYSTORE_USER']
present = [bool(os.environ.get(name)) for name in names]
if any(present) and not all(present):
    raise SystemExit('Persistent signing is partially configured: all four signing secrets are required.')
if not any(present):
    print('Persistent signing secrets are not configured; keeping test-only debug signing.')
    raise SystemExit(0)
root = Path(__file__).resolve().parents[1]
key = root/'.tools/release.keystore'
signed = root/'.build/shattered-realms-stable.apk'
apk = root/'.build/shattered-realms-debug.apk'
try:
    key.write_bytes(base64.b64decode(os.environ['KEYSTORE_BASE64'].strip(), validate=True))
    key.chmod(0o600)
    signer = Path(os.environ['ANDROID_HOME'])/'build-tools/35.0.0/apksigner'
    subprocess.run([str(signer), 'sign', '--ks', str(key), '--ks-key-alias', os.environ['KEYSTORE_USER'], '--ks-pass', 'env:KEYSTORE_PASSWORD', '--key-pass', 'env:KEY_PASSWORD', '--out', str(signed), str(apk)], check=True)
    subprocess.run([str(signer), 'verify', str(signed)], check=True)
    signed.replace(apk)
    print('Persistent repository signing applied and verified.')
finally:
    key.unlink(missing_ok=True)
    signed.unlink(missing_ok=True)
