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
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from _nq import BuildFlagsError, dump_flags  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN_PATH = os.path.join(REPO_ROOT, "tools", "golden", "i486-release.sha256")

# Same-length replacements, so object section sizes and offsets are untouched
# and the normalized hash is a faithful digest of everything except the clock.
#
# The date pattern used to be `\d{2}-[A-Za-z]{3}-\d{4}` ("DD-Mon-YYYY"), which no C
# compiler emits.  C spells __DATE__ as "Mmm dd yyyy" with a space-padded day, so
# DJGPP writes `Oct  4 2026` and the substitution never fired: the calendar date
# stayed in the digest of host.obj, host_cmd.obj and quake.exe, and the guard
# failed on any rebuild on a different day even though it is supposed to be
# blind to the date.  Verified across the 104 pinned artefacts -- the pattern
# below matches exactly those three and no others, so it does not weaken the pin
# on the other 101.
#
# Both halves are one pattern because they are one literal in the artefacts: the
# two __TIME__/__DATE__ users print them from one "Exe: %s %s\n" format, so the
# pair always appears as `<hh:mm:ss> <Mmm dd yyyy>`.  Anchoring on that is what
# keeps the pattern from matching unrelated text in .text.  The bare time
# pattern stays as a fallback for a lone __TIME__.
TIMESTAMP_PATTERNS = (
    (re.compile(rb"\d{2}:\d{2}:\d{2} [A-Z][a-z]{2} [ 0-9][0-9] \d{4}"), b"HH:MM:SS DD-MMM-YYYY"),
    (re.compile(rb"\d{2}:\d{2}:\d{2}"), b"HH:MM:SS"),
)


def release_paths() -> tuple[str, str]:
    """Ask build-dos.ps1 where the i486 executable and objects land.

    Deliberately does not repeat the profile-suffix arithmetic here: three copies of
    that rule is how smoke-dos.ps1 came to look for an executable the builder never
    wrote. Long selector profiles can put objects in a hashed sibling directory,
    so the builder is also the only place that knows the object root.
    """
    try:
        flags = dump_flags("-CpuTarget", "i486")
        return flags["outputRoot"], flags["objectRoot"]
    except BuildFlagsError as error:
        raise SystemExit(str(error)) from error


def digest(path: str, normalize: bool) -> str:
    with open(path, "rb") as handle:
        data = handle.read()
    if normalize:
        for pattern, replacement in TIMESTAMP_PATTERNS:
            data = pattern.sub(replacement, data)
    return hashlib.sha256(data).hexdigest().upper()


def hash_artifact(path: str) -> tuple[str, bool]:
    """Return (sha256, was_normalized) for one artefact, reading it once.

    Deciding whether to normalize requires the bytes, and so does hashing them.
    Asking the filesystem for them separately -- which is what this did, via
    digest(path, normalize_needed(path)) and then normalize_needed(path) again --
    read every one of the 104 artefacts three times.
    """
    with open(path, "rb") as handle:
        data = handle.read()
    normalized = any(pattern.search(data) for pattern, _ in TIMESTAMP_PATTERNS)
    if normalized:
        for pattern, replacement in TIMESTAMP_PATTERNS:
            data = pattern.sub(replacement, data)
    return hashlib.sha256(data).hexdigest().upper(), normalized


def collect(root: str, object_dir: str) -> dict[str, tuple[str, bool]]:
    """Map repo-relative artefact path -> (sha256, was_normalized)."""
    if not os.path.isdir(object_dir):
        raise SystemExit(
            "%s does not exist. Build it first: .\\tools\\build-dos.ps1 -Clean -NoBootstrap"
            % object_dir
        )
    entries: dict[str, tuple[str, bool]] = {}
    for name in sorted(os.listdir(object_dir)):
        if not name.endswith(".obj"):
            continue
        entries["obj/" + name] = hash_artifact(os.path.join(object_dir, name))
    exe = os.path.join(root, "quake.exe")
    if not os.path.isfile(exe):
        raise SystemExit(
            "%s does not exist. Build it first: .\\tools\\build-dos.ps1 -Clean -NoBootstrap" % exe
        )
    entries["quake.exe"] = hash_artifact(exe)
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
    root, object_dir = release_paths()
    entries = collect(root, object_dir)

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
