"""Fail-closed checks for the unsigned iOS submission-build CI environment."""
import argparse
import json
import pathlib
import re
import subprocess


def validate_toolchain(xcode_output, sdk_output):
    version = re.search(r'^Xcode (\d+)(?:\.\d+)*$', xcode_output, re.M)
    sdk = re.fullmatch(r'(\d+)(?:\.\d+)*', sdk_output.strip())
    if not version or int(version[1]) < 26 or not sdk or int(sdk[1]) < 26:
        raise ValueError('Require stable Xcode 26+ and the iPhoneOS 26+ SDK; no older/beta fallback')


def select_simulator(devices):
    candidates = []
    for runtime, entries in devices.items():
        match = re.fullmatch(r'com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+(?:-\d+)*)', runtime)
        if not match:
            continue
        version = tuple(map(int, match[1].split('-')))
        if version[0] < 26:
            continue
        for device in entries:
            if device.get('isAvailable') and device['name'].startswith('iPhone'):
                candidates.append((version, device['name'], device['udid'], runtime))
    if not candidates:
        raise ValueError('No available iPhone simulator running iOS 26+; no older-runtime fallback')
    return max(candidates)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['verify', 'simulator'])
    parser.add_argument('--devices', type=pathlib.Path)
    parser.add_argument('--github-env', type=pathlib.Path)
    args = parser.parse_args()
    if args.action == 'verify':
        xcode = subprocess.check_output(['xcodebuild', '-version'], text=True)
        sdk = subprocess.check_output(['xcrun', '--sdk', 'iphoneos', '--show-sdk-version'], text=True)
        print(xcode.strip())
        print('iPhoneOS SDK: ' + sdk.strip())
        validate_toolchain(xcode, sdk)
    else:
        if not args.devices or not args.github_env:
            parser.error('simulator requires --devices and --github-env')
        version, name, identifier, runtime = select_simulator(json.loads(args.devices.read_text())['devices'])
        with args.github_env.open('a') as env_file:
            env_file.write('SIMULATOR_ID=' + identifier + '\n')
        print(f'Selected {name}, {runtime}, {identifier}')


if __name__ == '__main__':
    main()
