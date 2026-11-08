"""Shared helpers for the Python tools in tools/.

The only thing genuinely duplicated across them is how to ask build-dos.ps1 what a
configuration resolves to. Three tools need that answer and each had its own copy
of the subprocess call, each with its own error handling: test-build-dos.py
recorded a failure and returned {}, guard-i486-release.py raised SystemExit, and
isa-audit-source.py raised SystemExit with different wording. None of them checked
whether `pwsh` was on PATH, so a machine without it produced a bare
FileNotFoundError from deep inside subprocess rather than a sentence naming the
missing prerequisite.

A module named with a leading underscore, so it is clearly not a tool in its own
right and nothing tries to run it.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TOOLS_DIR)
BUILD_SCRIPT = os.path.join(TOOLS_DIR, "build-dos.ps1")


class BuildFlagsError(RuntimeError):
    """build-dos.ps1 -DumpFlags could not be run, or did not answer with JSON."""


def _pwsh() -> str:
    """Locate pwsh, or say what is missing.

    run-tests.ps1 defends against this; the Python tools did not, and a missing
    pwsh surfaced as FileNotFoundError: [WinError 2] with no indication of what
    was being looked for.
    """
    found = shutil.which("pwsh") or shutil.which("powershell")
    if found is None:
        raise BuildFlagsError(
            "neither pwsh nor powershell is on PATH, so build-dos.ps1 cannot be "
            "asked what a configuration resolves to. Install PowerShell, or run "
            "the tools that do not need it."
        )
    return found


def dump_flags(*extra: str) -> dict:
    """Run build-dos.ps1 -DumpFlags and return the resolved configuration.

    Raises BuildFlagsError rather than returning a sentinel, because every caller
    wants to stop on failure and one of them wanted an empty dict that it then
    compared against a golden -- which reports a field count mismatch instead of
    the reason.
    """
    completed = subprocess.run(
        [_pwsh(), "-NoProfile", "-File", BUILD_SCRIPT, "-DumpFlags", *extra],
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise BuildFlagsError(
            "build-dos.ps1 -DumpFlags %s failed with exit code %d:\n%s"
            % (" ".join(extra), completed.returncode, completed.stderr.strip())
        )
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise BuildFlagsError(
            "build-dos.ps1 -DumpFlags %s did not emit JSON: %s\n%s"
            % (" ".join(extra), error, completed.stdout[:400])
        ) from error


def portable(flags: dict) -> dict:
    """Rewrite the machine-specific absolute paths in a resolved configuration.

    The golden files under tools/golden/ are committed and must be comparable
    across checkouts, so the repository root in any string becomes a literal.
    Applied to strings and to lists of strings, which is where outputRoot,
    executable and the -I/-o flag values appear.
    """
    repo = REPO_ROOT

    def rewrite(value):
        if isinstance(value, str):
            return value.replace(repo, "<repo>")
        if isinstance(value, list):
            return [rewrite(item) for item in value]
        if isinstance(value, dict):
            return {key: rewrite(item) for key, item in value.items()}
        return value

    return {key: rewrite(value) for key, value in flags.items()}
