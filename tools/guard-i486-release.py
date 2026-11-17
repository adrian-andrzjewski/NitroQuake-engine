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

`host.c` embeds the displayed build identity, which changes when the source
revision changes. `host.c` and `host_cmd.c` also print `__TIME__ " " __DATE__`
in their `sysinfo` output. The two objects and linked executable therefore
contain revision/configuration or clock data that can change without changing
the i486 code being pinned. Those exact fixed-format strings are replaced with
same-length literals before hashing. The build manifest and resolved-flags
checks retain the product identity and configuration. Affected entries are
marked `normalized` in the golden file so the exclusion is visible.

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

# Same-length replacements, so object section sizes and offsets are untouched.
# The product build ID is also present in host.obj and quake.exe. That ID is
# expected to change across source revisions and resolved configurations; the
# build manifest records it, while this content pin checks the emitted code.
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
NORMALIZATION_PATTERNS = (
    (re.compile(rb"Build [0-9a-f]{12}-[0-9a-f]{12}", re.IGNORECASE),
     b"Build 000000000000-000000000000"),
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
        data, _ = normalize_artifact_bytes(data)
    return hashlib.sha256(data).hexdigest().upper()


def normalize_artifact_bytes(data: bytes) -> tuple[bytes, bool]:
    """Normalize generated build identity and clock fields without hiding code."""
    normalized = any(pattern.search(data) for pattern, _ in NORMALIZATION_PATTERNS)
    if normalized:
        for pattern, replacement in NORMALIZATION_PATTERNS:
            data = pattern.sub(replacement, data)
    return data, normalized


def hash_artifact(path: str) -> tuple[str, bool]:
    """Return (sha256, was_normalized) for one artefact, reading it once.

    Deciding whether to normalize requires the bytes, and so does hashing them.
    Asking the filesystem for them separately -- which is what this did, via
    digest(path, normalize_needed(path)) and then normalize_needed(path) again --
    read every one of the 104 artefacts three times.
    """
    with open(path, "rb") as handle:
        data = handle.read()
    data, normalized = normalize_artifact_bytes(data)
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
        print("  normalized       %d (build identity or __DATE__/__TIME__)" % normalized)
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
            "with --record and document the reason in the release review; record it in the\n"
            "optimization ledger when it is an optimization attempt. Otherwise the change\n"
            "leaked out of an #ifdef TARGET_I386 guard."
        )
        return 1

    normalized = sum(1 for _, was in entries.values() if was)
    print("guard-i486-release: PASS")
    print("  artefacts        %d objects + executable" % (len(entries) - 1))
    print("  normalized       %d (build identity or __DATE__/__TIME__)" % normalized)
    print("  release root     %s" % os.path.basename(root))
    return 0


if __name__ == "__main__":
    sys.exit(main())
