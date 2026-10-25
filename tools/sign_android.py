"""Validate signing configuration without logging values, then sign the APK."""
import argparse
import base64
import binascii
import os
import subprocess
from pathlib import Path

SECRET_NAMES = ('KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_PASSWORD', 'KEYSTORE_USER')


def decode_keystore(value: str) -> bytes:
    # Clipboard line wrapping and trailing newlines do not change Base64 bytes.
    encoded = ''.join(value.split())
    if not encoded or len(encoded) % 4 == 1:
        raise ValueError('KEYSTORE_BASE64 is not valid Base64; paste only the value, without its heading or other secrets.')
    encoded += '=' * (-len(encoded) % 4)
    try:
        decoded = base64.b64decode(encoded, validate=True)
    except (ValueError, binascii.Error) as exc:
        raise ValueError('KEYSTORE_BASE64 contains non-Base64 text; paste only the value, without headings or code fences.') from exc
    if not (decoded.startswith(b'\xfe\xed\xfe\xed') or decoded.startswith(b'0')):
        raise ValueError('KEYSTORE_BASE64 decoded, but is not a JKS/PKCS12 keystore. Use the original signing backup.')
    return decoded


def check_configuration() -> bool:
    present = {name: bool(os.environ.get(name, '').strip()) for name in SECRET_NAMES}
    print('Signing secret availability (values are never printed):')
    for name, exists in present.items():
        print(f"  {name}: {'available' if exists else 'NOT AVAILABLE'}")
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a') as report:
            report.write('### Android signing\n\n| Repository secret | Available to build |\n|---|---|\n')
            for name, exists in present.items():
                report.write(f"| {name} | {'Yes' if exists else 'No'} |\n")
            if not any(present.values()):
                report.write('\nTemporary debug signing only. Add the four repository Actions secrets in **tpylman90-ctrl/Shattered-realmsv1.0**. A malformed Base64 value would produce a decoding error, not make all four secrets unavailable.\n')
    if any(present.values()) and not all(present.values()):
        missing = ', '.join(name for name, exists in present.items() if not exists)
        raise ValueError('Missing repository Actions secrets: ' + missing)
    if not any(present.values()):
        print('Persistent signing secrets are not configured; keeping test-only debug signing.')
        return False
    decode_keystore(os.environ['KEYSTORE_BASE64'])
    return True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true', help='Check secret availability and Base64 without signing.')
    args = parser.parse_args()
    try:
        configured = check_configuration()
        if not configured or args.check:
            return
        root = Path(__file__).resolve().parents[1]
        key = root / '.tools/release.keystore'
        signed = root / '.build/shattered-realms-stable.apk'
        apk = root / '.build/shattered-realms-debug.apk'
        try:
            key.parent.mkdir(parents=True, exist_ok=True)
            key.write_bytes(decode_keystore(os.environ['KEYSTORE_BASE64']))
            key.chmod(0o600)
            signer = Path(os.environ['ANDROID_HOME']) / 'build-tools/35.0.0/apksigner'
            subprocess.run([str(signer), 'sign', '--ks', str(key), '--ks-key-alias', os.environ['KEYSTORE_USER'].strip(), '--ks-pass', 'env:KEYSTORE_PASSWORD', '--key-pass', 'env:KEY_PASSWORD', '--out', str(signed), str(apk)], check=True)
            subprocess.run([str(signer), 'verify', str(signed)], check=True)
            signed.replace(apk)
            print('Persistent repository signing applied and verified.')
        finally:
            key.unlink(missing_ok=True)
            signed.unlink(missing_ok=True)
    except ValueError as exc:
        raise SystemExit(str(exc)) from None


if __name__ == '__main__':
    main()
