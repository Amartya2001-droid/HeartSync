"""Portable documentation and shared-scheme smoke checks (not iOS tests)."""
import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def test_readme_links_resolve(self):
        readme = (ROOT / 'README.md').read_text()
        for target in re.findall(r'\]\(([^)]+)\)', readme):
            if '://' not in target:
                self.assertTrue((ROOT / target).is_file(), target)
        self.assertIn('Not live yet', readme)
        self.assertIn('Demo-ready acceptance criteria', readme)

    def test_shared_scheme_includes_app_and_tests(self):
        scheme = ET.parse(ROOT / 'HeartSync.xcodeproj/xcshareddata/xcschemes/HeartSync.xcscheme')
        references = scheme.findall('.//BuildableReference')
        self.assertTrue(any(r.get('BlueprintName') == 'HeartSync' for r in references))
        tests = scheme.findall('.//TestableReference/BuildableReference')
        self.assertEqual([r.get('BlueprintName') for r in tests], ['HeartSyncTests'])


if __name__ == '__main__':
    unittest.main()
