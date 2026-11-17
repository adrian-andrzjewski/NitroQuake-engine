"""History/identity contracts using isolated Git histories, not the user's index."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('history', Path(__file__).with_name('optimization-history.py'))
history = importlib.util.module_from_spec(spec)
spec.loader.exec_module(history)


class HistoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nitroquake-history-')
        self.root = Path(self.temp.name) / 'repo'
        self.root.mkdir()
        self.git('init', '-q')
        self.git('config', 'user.name', 'History test')
        self.git('config', 'user.email', 'history@example.invalid')
        self.git('config', 'core.autocrlf', 'false')
        (self.root / 'tools').mkdir()
        (self.root / 'docs/ledger').mkdir(parents=True)
        self.metadata = dict(schemaVersion=1, records={}, supersededDocuments={})
        self.save_metadata()
        self.write('one-promoted.md', '# Accepted\n')
        self.write('two-rejected.md', '# Rejected\n')
        self.commit()

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.root), *args], check=True,
                              capture_output=True, encoding='utf-8').stdout.strip()

    def commit(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'Fixture decision')

    def save_metadata(self):
        (self.root / 'tools/optimization-history-legacy.json').write_text(json.dumps(self.metadata), encoding='utf-8')

    def write(self, name, text):
        (self.root / 'docs/ledger' / name).write_text(text, encoding='utf-8')

    def result(self):
        return history.inventory(self.root)

    def test_rebuild_and_unrelated_commit(self):
        first = self.result()
        self.assertEqual((first['buildNumber'], first['accepted'], first['rejected']), (2, 1, 1))
        self.assertEqual(first, self.result())
        (self.root / 'unrelated.txt').write_text('unrelated')
        self.commit()
        self.assertEqual(first['inventorySha256'], self.result()['inventorySha256'])

    def test_working_tree_port_and_rejection(self):
        self.write('three-assembly-port.md', '# Correctness acceptance\n')
        self.write('four-rejected.md', '# Wrong output\n')
        self.assertEqual(self.result()['buildNumber'], 4)

    def test_git_only_attempt_requires_reachable_revision(self):
        revision = self.git('rev-parse', 'HEAD')
        self.metadata['gitOnlyAttempts'] = [dict(id='early-port', commit=revision,
            outcome='accepted', description='An early retained port without a report')]
        self.save_metadata()
        self.assertEqual(self.result()['buildNumber'], 3)
        self.metadata['gitOnlyAttempts'][0]['commit'] = '0' * 40
        self.save_metadata()
        self.assertEqual(self.result()['buildNumber'], 2)

    def test_user_git_presentation_settings_do_not_change_identity(self):
        self.metadata['gitOnlyAttempts'] = [dict(id='early-port', commit=self.git('rev-parse', 'HEAD'),
            outcome='accepted', description='Retained historical port')]
        self.save_metadata()
        (self.root / 'docs/ledger/one-promoted.md').unlink()
        self.commit()
        first = self.result()
        self.git('config', 'color.ui', 'always')
        self.git('config', 'log.date', 'relative')
        self.assertEqual(first, self.result())

    def test_repeated_samples_do_not_increment(self):
        self.write('one-promoted.md', '# Accepted\nAnother five benchmark samples.\n')
        self.assertEqual(self.result()['buildNumber'], 2)

    def test_runner_freshness_tracks_inventory_revision_source_and_full_history(self):
        (self.root / 'src').mkdir()
        (self.root / 'src' / 'r_main.c').write_text('void render(void) {}\n', encoding='ascii')
        self.commit()
        common = str(Path(__file__).with_name('common.ps1')).replace("'", "''")
        def fingerprint(repo):
            repo = str(repo).replace("'", "''")
            script = f". '{common}'; function Get-CompatibilityPolicyFingerprint {{ 'fixture' }}; "
            script += "$resolved = [pscustomobject]@{outputRoot='out';profileSuffix='';executable='quake.exe';cFlags=@();asmFlags=@()}; "
            command = script + f"Get-BuildFingerprint -RepoRoot '{repo}' -Resolved $resolved"
            return subprocess.run(['pwsh', '-NoProfile', '-Command', command], check=True,
                                  capture_output=True, encoding='utf-8').stdout.strip()
        first = fingerprint(self.root)
        self.assertTrue(first)
        self.assertEqual(first, fingerprint(self.root))
        self.write('third-promoted.md', '# A newly accepted attempt\n')
        self.assertNotEqual(first, fingerprint(self.root))
        self.assertEqual(3, self.result()['buildNumber'])
        self.commit()
        self.assertNotEqual(first, fingerprint(self.root))

        clone = Path(self.temp.name) / 'full-fingerprint'
        self.git('clone', '-q', '--no-hardlinks', self.root.as_uri(), str(clone))
        self.assertEqual(fingerprint(self.root), fingerprint(clone))

        shallow = Path(self.temp.name) / 'shallow-fingerprint'
        self.git('clone', '-q', '--depth=1', '--no-hardlinks', self.root.as_uri(), str(shallow))
        with self.assertRaises(subprocess.CalledProcessError):
            fingerprint(shallow)

        (self.root / 'src' / 'r_main.c').write_text('void render(void) { int changed; }\n', encoding='ascii')
        self.assertNotEqual(fingerprint(self.root), fingerprint(clone))

    def test_duplicate_and_independent_variants(self):
        markers = '<!-- optimization-attempt: variant-a accepted -->\n<!-- optimization-attempt: variant-b rejected -->\n'
        self.write('multi.md', markers)
        self.write('repeat.md', markers)
        self.assertEqual(self.result()['buildNumber'], 4)

    def test_conflicting_decisions_fail(self):
        self.write('multi.md', '<!-- optimization-attempt: same accepted -->\n<!-- optimization-attempt: same rejected -->\n')
        with self.assertRaisesRegex(ValueError, 'Conflicting outcomes'):
            self.result()

    def test_committed_and_uncommitted_deletions_retain_attempts(self):
        (self.root / 'docs/ledger/one-promoted.md').unlink()
        self.assertEqual(self.result()['buildNumber'], 2)
        self.commit()
        self.assertEqual(self.result()['buildNumber'], 2)

    def test_rename_does_not_add_attempt(self):
        self.git('mv', 'docs/ledger/one-promoted.md', 'docs/ledger/renamed-promoted.md')
        self.commit()
        self.assertEqual(self.result()['buildNumber'], 2)

    def test_legacy_multi_attempt_rename_preserves_classification(self):
        self.metadata['records']['one-promoted.md'] = [dict(id='a', outcome='accepted'), dict(id='b', outcome='rejected')]
        self.save_metadata()
        self.commit()
        self.git('mv', 'docs/ledger/one-promoted.md', 'docs/ledger/renamed.md')
        self.commit()
        self.git('mv', 'docs/ledger/renamed.md', 'docs/ledger/renamed-again.md')
        self.commit()
        self.assertEqual(self.result()['buildNumber'], 3)
        (self.root / 'docs/ledger/renamed-again.md').unlink()
        self.commit()
        self.assertEqual(self.result()['buildNumber'], 3)

    def test_other_branches_do_not_count(self):
        branch = self.git('branch', '--show-current')
        self.git('checkout', '-qb', 'experiment')
        self.write('branch-rejected.md', '# Rejected\n')
        self.commit()
        self.git('checkout', '-q', branch)
        self.assertEqual(self.result()['buildNumber'], 2)

    def test_clone_and_line_endings(self):
        clone = Path(self.temp.name) / 'clone'
        self.git('clone', '-q', '--no-hardlinks', str(self.root), str(clone))
        self.assertEqual(self.result()['inventorySha256'], history.inventory(clone)['inventorySha256'])
        (self.root / 'docs/ledger/one-promoted.md').write_bytes(b'# Accepted\r\n')
        self.assertEqual(self.result()['inventorySha256'], history.inventory(clone)['inventorySha256'])

    def test_incomplete_history_fails(self):
        clone = Path(self.temp.name) / 'shallow'
        self.git('clone', '-q', '--depth=1', self.root.as_uri(), str(clone))
        with self.assertRaisesRegex(ValueError, 'complete Git history'):
            history.inventory(clone)

    def test_archive_does_not_invent_a_number(self):
        archive = Path(self.temp.name) / 'archive'
        archive.mkdir()
        with self.assertRaises(subprocess.CalledProcessError):
            history.inventory(archive)

    def test_unknown_reports_require_outcomes(self):
        self.write('profile.md', '# Profiling\n')
        with self.assertRaisesRegex(ValueError, 'classification'):
            self.result()
        self.write('profile.md', '# Profiling\n<!-- optimization-attempts: none -->\n')
        self.assertEqual(self.result()['buildNumber'], 2)

    def test_legacy_evidence_and_supersession(self):
        self.metadata['records']['one-promoted.md'] = []
        self.metadata['supersededDocuments']['one-promoted.md'] = 'withdrawn.md'
        self.write('withdrawn.md', '# Withdrawal\n<!-- optimization-attempt: old rejected -->\n')
        self.save_metadata()
        self.commit()
        (self.root / 'docs/ledger/one-promoted.md').unlink()
        self.commit()
        self.assertEqual(self.result()['buildNumber'], 2)
        self.metadata['records']['two-rejected.md'] = [dict(id='two', outcome='rejected', heading='Missing')]
        self.save_metadata()
        with self.assertRaisesRegex(ValueError, 'heading no longer exists'):
            self.result()


if __name__ == '__main__':
    unittest.main()
