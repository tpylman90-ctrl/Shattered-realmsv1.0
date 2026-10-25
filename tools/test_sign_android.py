import base64
import contextlib
import io
import os
import unittest
from unittest.mock import patch
from sign_android import decode_keystore, check_configuration, SECRET_NAMES


class SigningInputTests(unittest.TestCase):
    def test_wrapped_clipboard_text_restores_identical_bytes(self):
        raw = b'\xfe\xed\xfe\xed' + bytes(range(256))
        encoded = base64.b64encode(raw).decode()
        wrapped = '\r\n'.join(encoded[i:i+48] for i in range(0, len(encoded), 48))
        self.assertEqual(decode_keystore(' \n' + wrapped + '\t '), raw)
        self.assertEqual(decode_keystore(encoded.rstrip('=')), raw)

    def test_pasting_headings_is_rejected(self):
        with self.assertRaises(ValueError):
            decode_keystore('ANDROID_KEYSTORE_BASE64\n```\nAAAA\n```')
        with self.assertRaises(ValueError):
            decode_keystore(base64.b64encode(b'not a keystore').decode())

    def test_missing_values_are_not_reported_as_bad_base64(self):
        with patch.dict(os.environ, {}, clear=True), contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertFalse(check_configuration())
        for name in SECRET_NAMES:
            self.assertIn(name + ': NOT AVAILABLE', output.getvalue())

    def test_partial_configuration_names_missing_fields_without_values(self):
        secret_value = base64.b64encode(b'\xfe\xed\xfe\xedprivate').decode()
        with patch.dict(os.environ, {'ANDROID_KEYSTORE_BASE64': secret_value}, clear=True), contextlib.redirect_stdout(io.StringIO()) as output:
            with self.assertRaisesRegex(ValueError, 'ANDROID_KEYSTORE_PASSWORD'):
                check_configuration()
        self.assertNotIn(secret_value, output.getvalue())


if __name__ == '__main__':
    unittest.main()
