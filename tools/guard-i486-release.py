#!/usr/bin/env python3
"""SHA-256 guard on the retained i486 release build.

Why this exists
---------------
Adding a second CPU target to this tree is exactly the kind of change that can
silently move the release artefact.  Every hand-written assembly edit needed for
the i386 target has to be behind `#ifdef TARGET_I386`, and this guard is what
proves it was: if the i486 object bytes are unchanged, the 486 codepath did not
move, whatever else happened.

It is a content pin, not a source pin.  `tools/test-build-dos.py` already pins
the resolved flags, so between the two there is no path by which a release object
changes without someone deciding to change it.

The one wrinkle: `host.c` and `host_cmd.c` print `__TIME__ " " __DATE__` in
their `sysinfo` output, so those two objects and the linked executable embed the
build timestamp and can never hash the same twice.  For those three artefacts the
pin is taken over the file's bytes with the timestamp patterns replaced by
same-length literals, which keeps the comparison meaningful without making it
impossible to pass.  Those entries are marked `normalized` in the golden file so
that the weakening is visible rather than assumed.

Usage
-----
    python tools/guard-i486-release.py            # verify
    python tools/guard-i486-release.py --record   # re-record after a
                                                 # deliberate i486 change

Verification requires a built release tree; run
`tools\\build-dos.ps1 -Clean -NoBootstrap` first.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_SCRIPT = os.path.join(REPO_ROOT, "tools", "build-dos.ps1")
GOLDEN_PATH = os.path.join(REPO_ROOT, "tools", "golden", "i486-release.sha256")

# Same-length replacements, so object section sizes and offsets are untouched
# and the normalized hash is a faithful digest of everything except the clock.
TIMESTAMP_PATTERNS = (
    (re.compile(rb"\d{2}:\d{2}:\d{2}"), b"HH:MM:SS"),
    (re.compile(rb"\d{2}-[A-Za-z]{3}-\d{4}"), b"DD-Mon-YYYY"),
)


def release_root() -> str:
    """Ask build-dos.ps1 where the i486 release lands, rather than repeating its
    profile-suffix arithmetic here and risking the two drifting apart."""
    completed = subprocess.run(
        ["pwsh", "-NoProfile", "-File", BUILD_SCRIPT, "-DumpFlags", "-CpuTarget", "i486"],
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise SystemExit(
            "build-dos.ps1 -DumpFlags failed with exit code %d:\n%s"
            % (completed.returncode, completed.stderr.strip())
        )
    return json.loads(completed.stdout)["outputRoot"]


def digest(path: str, normalize: bool) -> str:
    with open(path, "rb") as handle:
        data = handle.read()
    if normalize:
        for pattern, replacement in TIMESTAMP_PATTERNS:
            data = pattern.sub(replacement, data)
    return hashlib.sha256(data).hexdigest().upper()


def normalize_needed(path: str) -> bool:
    with open(path, "rb") as handle:
        data = handle.read()
    return any(pattern.search(data) for pattern, _ in TIMESTAMP_PATTERNS)


def collect(root: str) -> dict[str, tuple[str, bool]]:
    """Map repo-relative artefact path -> (sha256, was_normalized)."""
    object_dir = os.path.join(root, "obj")
    entries: dict[str, tuple[str, bool]] = {}
    for name in sorted(os.listdir(object_dir)):
        if not name.endswith(".obj"):
            continue
        path = os.path.join(object_dir, name)
        entries["obj/" + name] = (digest(path, normalize_needed(path)), normalize_needed(path))
    exe = os.path.join(root, "quake.exe")
    if not os.path.isfile(exe):
        raise SystemExit(
            "%s does not exist. Build it first: .\\tools\\build-dos.ps1 -Clean -NoBootstrap" % exe
        )
    entries["quake.exe"] = (digest(exe, normalize_needed(exe)), normalize_needed(exe))
    return entries


def load_golden() -> dict[str, str]:
    if not os.path.isfile(GOLDEN_PATH):
        raise SystemExit("missing golden %s; run with --record" % GOLDEN_PATH)
    entries: dict[str, str] = {}
    with open(GOLDEN_PATH, "r", encoding="ascii") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split()
            if len(parts) != 3:
                raise SystemExit("malformed golden line: %r" % line)
            if parts[1] not in ("normal", "normalized"):
                raise SystemExit(
                    "golden line %r: second field must be 'normal' or 'normalized'" % line
                )
            entries[parts[2]] = parts[0]
    return entries


def main() -> int:
    record = "--record" in sys.argv[1:]
    root = release_root()
    entries = collect(root)

    if record:
        lines = [
            "%s  %-10s  %s" % (sha, "normalized" if was_normalized else "normal", name)
            for name, (sha, was_normalized) in sorted(entries.items())
        ]
        with open(GOLDEN_PATH, "w", encoding="ascii") as handle:
            handle.write("\n".join(lines) + "\n")
        normalized = sum(1 for _, was in entries.values() if was)
        print("guard-i486-release: recorded %d artefacts" % len(entries))
        print("  golden           %s" % os.path.relpath(GOLDEN_PATH, REPO_ROOT))
        print("  normalized       %d (embed __DATE__/__TIME__)" % normalized)
        return 0

    golden = load_golden()
    problems: list[str] = []
    for name in sorted(set(golden) | set(entries)):
        if name not in entries:
            problems.append("missing from the build: %s" % name)
        elif name not in golden:
            problems.append("not in the golden:    %s" % name)
        elif golden[name] != entries[name][0]:
            problems.append("changed:             %s" % name)

    if problems:
        print("guard-i486-release: FAIL (%d)" % len(problems))
        for problem in problems:
            print("  - %s" % problem)
        print(
            "\nThe i486 release build has moved. If that was deliberate, re-record\n"
            "with --record and say so in ASM486-HANDOFF.md; otherwise the change\n"
            "leaked out of an #ifdef TARGET_I386 guard."
        )
        return 1

    normalized = sum(1 for _, was in entries.values() if was)
    print("guard-i486-release: PASS")
    print("  artefacts        %d objects + executable" % (len(entries) - 1))
    print("  normalized       %d (embed __DATE__/__TIME__)" % normalized)
    print("  release root     %s" % os.path.basename(root))
    return 0


if __name__ == "__main__":
    sys.exit(main())
