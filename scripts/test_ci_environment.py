"""Portable regressions for CI environment selection, not native execution."""
import unittest
from ci_environment import select_simulator, validate_toolchain


class EnvironmentTests(unittest.TestCase):
    def test_accepts_supported_stable_toolchains(self):
        for version, sdk in [('26.3', '26.2'), ('27.1', '27.0')]:
            validate_toolchain(f'Xcode {version}\nBuild version example\n', sdk + '\n')

    def test_rejects_old_beta_or_unreadable_toolchains(self):
        for xcode, sdk in [('Xcode 16.4', '18.5'), ('Xcode 26.3', '18.5'),
                           ('Xcode 26.3 Beta', '26.2'), ('unknown', '26.2'),
                           ('Xcode 26.3', 'unknown')]:
            with self.subTest(xcode=xcode, sdk=sdk), self.assertRaises(ValueError):
                validate_toolchain(xcode, sdk)

    def test_selects_newest_available_ios_iphone(self):
        device = lambda name, identifier, available=True: dict(name=name, udid=identifier, isAvailable=available)
        selected = select_simulator({
            'com.apple.CoreSimulator.SimRuntime.iOS-18-5': [device('iPhone old', 'old')],
            'com.apple.CoreSimulator.SimRuntime.iOS-26-0': [device('iPhone baseline', 'baseline')],
            'com.apple.CoreSimulator.SimRuntime.iOS-26-2': [device('iPad', 'tablet'), device('iPhone unavailable', 'off', False), device('iPhone current', 'current')],
            'com.apple.CoreSimulator.SimRuntime.tvOS-27-0': [device('iPhone misleading', 'wrong-platform')],
        })
        self.assertEqual(selected[2], 'current')

    def test_rejects_missing_or_unsupported_simulators(self):
        for devices in [{}, {'com.apple.CoreSimulator.SimRuntime.iOS-18-5': [dict(name='iPhone old', udid='old', isAvailable=True)]},
                        {'com.apple.CoreSimulator.SimRuntime.iOS-26-2': [dict(name='iPhone offline', udid='offline', isAvailable=False)]}]:
            with self.subTest(devices=devices), self.assertRaises(ValueError):
                select_simulator(devices)
