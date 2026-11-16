#!/usr/bin/env python3
"""Regression tests for source-identity normalization in the release content pin."""

from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "i486_release_guard", ROOT / "tools" / "guard-i486-release.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("could not load guard-i486-release.py")
GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GUARD)


class I486ReleaseGuardTests(unittest.TestCase):
    def test_build_identity_and_clock_do_not_move_content_pin(self) -> None:
        first = (
            b"Build a2b2db4a1f22-0123456789ab\n"
            b"Exe: 12:34:56 Nov 16 2026\n"
            b"\x90\x90\xc3"
        )
        second = (
            b"Build 2a965f34217d-99cbf4b72f62\n"
            b"Exe: 08:20:01 Nov 17 2026\n"
            b"\x90\x90\xc3"
        )
        with tempfile.TemporaryDirectory(prefix="nq-release-guard-") as temporary:
            first_path = Path(temporary) / "first.obj"
            second_path = Path(temporary) / "second.obj"
            first_path.write_bytes(first)
            second_path.write_bytes(second)

            first_hash, first_normalized = GUARD.hash_artifact(str(first_path))
            second_hash, second_normalized = GUARD.hash_artifact(str(second_path))

        self.assertTrue(first_normalized)
        self.assertTrue(second_normalized)
        self.assertEqual(first_hash, second_hash)

    def test_code_changes_remain_visible_after_identity_normalization(self) -> None:
        first = b"Build a2b2db4a1f22-0123456789ab\n\x90\xc3"
        changed = b"Build 2a965f34217d-99cbf4b72f62\n\x91\xc3"
        normalized_first, _ = GUARD.normalize_artifact_bytes(first)
        normalized_changed, _ = GUARD.normalize_artifact_bytes(changed)

        self.assertNotEqual(normalized_first, normalized_changed)


if __name__ == "__main__":
    unittest.main()
