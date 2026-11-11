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

    def test_shared_scheme_includes_app_and_tests(self):
        scheme = ET.parse(ROOT / 'HeartSync.xcodeproj/xcshareddata/xcschemes/HeartSync.xcscheme')
        references = scheme.findall('.//BuildableReference')
        self.assertTrue(any(r.get('BlueprintName') == 'HeartSync' for r in references))
        tests = scheme.findall('.//TestableReference/BuildableReference')
        self.assertEqual([r.get('BlueprintName') for r in tests], ['HeartSyncTests'])


if __name__ == '__main__':
    unittest.main()
