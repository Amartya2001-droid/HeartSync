"""Portable documentation and shared-scheme smoke checks (not iOS tests)."""
import pathlib
import json
import plistlib
import struct
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

    def test_app_sources_resolve_and_compile_once(self):
        """Catch broken group paths or missing/duplicate Sources entries after moves."""
        project = (ROOT / 'HeartSync.xcodeproj/project.pbxproj').read_text()
        objects = dict(re.findall(r'([A-F0-9]{24}) /\* [^\n]*? \*/ = \{([^{}]*)\};', project))
        paths = {}

        def visit(identifier, parent):
            body = objects[identifier]
            path = re.search(r'\bpath = ("[^"]+"|[^;]+);', body)
            current = parent / path.group(1).strip('"') if path else parent
            if 'isa = PBXGroup;' in body:
                children = re.search(r'children = \((.*?)\);', body, re.S).group(1)
                for child in re.findall(r'([A-F0-9]{24}) /\*', children):
                    visit(child, current)
            elif current.suffix == '.swift':
                self.assertTrue(current.is_file(), str(current))
                paths[identifier] = current.relative_to(ROOT)

        visit('AEA6048B2C25B4D800CB3983', ROOT)
        self.assertEqual(set(paths.values()), {p.relative_to(ROOT) for p in (ROOT / 'HeartSync').rglob('*.swift')})
        sources = objects['AEA604852C25B4D800CB3983']
        build_ids = re.findall(r'([A-F0-9]{24}) /\*', re.search(r'files = \((.*?)\);', sources, re.S).group(1))
        compiled = [re.search(r'fileRef = ([A-F0-9]{24})', objects[item]).group(1) for item in build_ids]
        self.assertEqual(len(compiled), len(set(compiled)), 'Duplicate compiled source')
        self.assertEqual(set(compiled), set(paths), 'App target must compile every app Swift file')

    def test_launch_assets_and_candidate_copy(self):
        catalog = ROOT / 'HeartSync/Assets.xcassets'
        icon_set = catalog / 'AppIcon.appiconset'
        manifest = json.loads((icon_set / 'Contents.json').read_text())
        for item in manifest['images']:
            data = (icon_set / item['filename']).read_bytes()
            self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
            width, height, depth, color_type = struct.unpack('>IIBB', data[16:26])
            self.assertEqual((width, height), (1024, 1024))
            self.assertEqual((depth, color_type), (8, 2), 'App icon must be RGB without an alpha channel')
        info = plistlib.loads((ROOT / 'HeartSync/Supporting/Info.plist').read_bytes())
        color_name = info['UILaunchScreen']['UIColorName']
        self.assertTrue((catalog / (color_name + '.colorset') / 'Contents.json').is_file())
        project = (ROOT / 'HeartSync.xcodeproj/project.pbxproj').read_text()
        self.assertEqual(project.count('INFOPLIST_FILE = HeartSync/Supporting/Info.plist;'), 2)
        copy = json.loads((ROOT / 'release/APP_STORE_COPY.json').read_text())
        for key, maximum in [('name', 30), ('subtitle', 30), ('promotional_text', 170), ('description', 4000), ('keywords', 100)]:
            self.assertGreater(len(copy[key]), 0, key)
            self.assertLessEqual(len(copy[key]), maximum, key)
        self.assertEqual(copy['status'], 'candidate-not-submitted')
        self.assertIsNone(copy['distribution_url'])

    def test_shared_scheme_includes_app_and_tests(self):
        scheme = ET.parse(ROOT / 'HeartSync.xcodeproj/xcshareddata/xcschemes/HeartSync.xcscheme')
        references = scheme.findall('.//BuildableReference')
        self.assertTrue(any(r.get('BlueprintName') == 'HeartSync' for r in references))
        tests = scheme.findall('.//TestableReference/BuildableReference')
        self.assertEqual([r.get('BlueprintName') for r in tests], ['HeartSyncTests', 'HeartSyncUITests'])


if __name__ == '__main__':
    unittest.main()
