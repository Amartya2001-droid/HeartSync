"""Check technical declarations and the actual Release product's copied manifest."""
import argparse
import pathlib
import plistlib

SOURCE = pathlib.Path(__file__).resolve().parents[1] / 'HeartSync/Supporting/PrivacyInfo.xcprivacy'


def read_manifest(path):
    with path.open('rb') as file:
        value = plistlib.load(file)
    if not isinstance(value, dict) or value.get('NSPrivacyTracking') is not False:
        raise ValueError('Current app must declare no tracking')
    for key in ['NSPrivacyTrackingDomains', 'NSPrivacyCollectedDataTypes']:
        if value.get(key) != []:
            raise ValueError(f'Re-audit source behavior before changing {key}')
    if value.get('NSPrivacyAccessedAPITypes') != [{
        'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
        'NSPrivacyAccessedAPITypeReasons': ['CA92.1'],
    }]:
        raise ValueError('Current inventory requires only app-owned UserDefaults (CA92.1)')
    return value


def verify_bundle(bundle, source=SOURCE):
    if read_manifest(bundle / 'PrivacyInfo.xcprivacy') != read_manifest(source):
        raise ValueError('Bundled manifest differs from reviewed source')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('bundle', type=pathlib.Path)
    args = parser.parse_args()
    verify_bundle(args.bundle)
    print('Verified PrivacyInfo.xcprivacy in unsigned Release app; no upload/approval implied')
