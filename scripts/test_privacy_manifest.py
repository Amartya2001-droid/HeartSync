import copy
import pathlib
import plistlib
import tempfile
import unittest
from check_privacy_manifest import SOURCE, read_manifest, verify_bundle


class PrivacyManifestTests(unittest.TestCase):
    def test_source_manifest_matches_current_api_inventory(self):
        read_manifest(SOURCE)

    def test_release_check_rejects_missing_or_changed_product_manifest(self):
        with tempfile.TemporaryDirectory() as folder:
            bundle = pathlib.Path(folder)
            with self.assertRaises(FileNotFoundError):
                verify_bundle(bundle)
            target = bundle / 'PrivacyInfo.xcprivacy'
            target.write_bytes(SOURCE.read_bytes())
            verify_bundle(bundle)
            modified = read_manifest(SOURCE)
            modified['unexpected'] = True
            target.write_bytes(plistlib.dumps(modified))
            with self.assertRaises(ValueError):
                verify_bundle(bundle)

    def test_rejects_unreviewed_tracking_data_or_api_reason_changes(self):
        original = read_manifest(SOURCE)
        with tempfile.TemporaryDirectory() as folder:
            target = pathlib.Path(folder) / 'PrivacyInfo.xcprivacy'
            changes = [('NSPrivacyTracking', True), ('NSPrivacyTracking', 0),
                       ('NSPrivacyTrackingDomains', ['invalid.example']),
                       ('NSPrivacyCollectedDataTypes', [{}]),
                       ('NSPrivacyAccessedAPITypes', [])]
            for key, value in changes:
                modified = copy.deepcopy(original)
                modified[key] = value
                target.write_bytes(plistlib.dumps(modified))
                with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                    read_manifest(target)
