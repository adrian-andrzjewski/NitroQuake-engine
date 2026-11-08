"""Offline installer tests: cached archives, split manifests and path containment."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

TOOLS = Path(__file__).resolve().parent


class BootstrapTests(unittest.TestCase):
    def test_game_manifest_only_installs_compiler(self):
        self.assertEqual(set(json.loads((TOOLS/'dos-toolchain.json').read_text())), {'djgpp'})

    def test_cached_archive_install_and_path_rejection(self):
        with tempfile.TemporaryDirectory(prefix='nitro bootstrap ') as directory:
            root = Path(directory)
            downloads = root/'downloads'
            downloads.mkdir()
            archive = downloads/'fixture.zip'
            with zipfile.ZipFile(archive, 'w') as stream:
                stream.writestr('bin/tool.exe', b'fixture tool')
            definition = dict(url='https://invalid.example/fixture.zip',
                              sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                              installDirectory='compiler', archiveRoot='', marker='bin/tool.exe')
            manifest = root/'manifest.json'
            def invoke():
                manifest.write_text(json.dumps({'fixture': definition}))
                return subprocess.run(['pwsh', '-NoProfile', '-File', str(TOOLS/'bootstrap-dos.ps1'),
                                       '-ToolRoot', str(root), '-ManifestPath', str(manifest)],
                                      capture_output=True, text=True)
            result = invoke()
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((root/'compiler/bin/tool.exe').read_bytes(), b'fixture tool')
            self.assertEqual(invoke().returncode, 0)
            outside = root.parent/(root.name+'-outside')
            definition['installDirectory'] = '../'+outside.name
            result = invoke()
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('escapes the tool installation root', result.stderr)
            self.assertFalse(outside.exists())


if __name__ == '__main__':
    unittest.main()
