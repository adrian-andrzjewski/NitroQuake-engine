#!/usr/bin/env python3
"""Host-side guard on the DOS build script's resolved flags.

Why this exists
---------------
The 486 build in this tree is the project's release artefact.  Adding a second
CPU target is exactly the kind of change that can silently move it: one flag
order, one `-falign` value or one path in the wrong place and the release
objects change without anybody deciding to change them.  This test pins the
resolved flag lists, the output paths and the source counts for both targets, so
that such a drift fails instead of landing.

It also pins the things the 486 path must *not* acquire:

* the default `-CpuTarget` must stay `i486`;
* the i486 profile suffix and output root must keep their historical values, so
  no release artefact, benchmark baseline or `out\dos-timedemo-*` directory
  stops matching;
* the two targets must resolve to different output roots, because `-Clean`
  removes the directory it is handed.

It does not need a bootstrapped toolchain: `build-dos.ps1 -DumpFlags` skips the
compiler and objdump lookup and prints this script's own arithmetic.

Usage
-----
    python tools/test-build-dos.py

Exits 0 when every check passes, 1 otherwise, printing one line per failure.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_SCRIPT = os.path.join(REPO_ROOT, "tools", "build-dos.ps1")
GOLDEN_DIR = os.path.join(REPO_ROOT, "tools", "golden")

# The i486 release profile suffix as it has stood since the retained build was
# established.  Duplicated here on purpose: build-dos.ps1 computes it from the
# selector defaults, and this literal is the independent check that the
# computation still produces it.
RELEASE_I486_SUFFIX = (
    "-memasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist"
    "-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm"
)

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def dump_flags(*extra: str) -> dict:
    """Run build-dos.ps1 -DumpFlags and return its JSON, with repo paths made
    machine-independent so the golden files are portable across checkouts."""
    command = [
        "pwsh",
        "-NoProfile",
        "-File",
        BUILD_SCRIPT,
        "-DumpFlags",
        *extra,
    ]
    completed = subprocess.run(command, capture_output=True, text=True)
    if completed.returncode != 0:
        fail(
            "build-dos.ps1 -DumpFlags %s failed with exit code %d:\n%s"
            % (" ".join(extra), completed.returncode, completed.stderr.strip())
        )
        return {}
    try:
        parsed = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        fail("build-dos.ps1 -DumpFlags %s did not emit JSON: %s" % (" ".join(extra), error))
        return {}

    def normalize(value):
        if isinstance(value, str):
            return value.replace(REPO_ROOT, "<repo>")
        if isinstance(value, list):
            return [normalize(item) for item in value]
        return value

    return {key: normalize(value) for key, value in parsed.items()}


def load_golden(target: str) -> dict:
    path = os.path.join(GOLDEN_DIR, "build-flags-%s.json" % target)
    if not os.path.isfile(path):
        fail("missing golden flag file %s" % path)
        return {}
    with open(path, "r", encoding="ascii") as handle:
        return json.load(handle)


def compare(target: str, actual: dict, expected: dict) -> None:
    if not actual or not expected:
        return
    for key in sorted(set(expected) | set(actual)):
        if key not in actual:
            fail("%s: resolved flags are missing '%s'" % (target, key))
        elif key not in expected:
            fail("%s: resolved flags contain unexpected key '%s'" % (target, key))
        elif actual[key] != expected[key]:
            fail(
                "%s: '%s' changed.\n      golden: %r\n      actual: %r"
                % (target, key, expected[key], actual[key])
            )


def main() -> int:
    # 1. The default target must be the retained release profile.
    default_dump = dump_flags()
    if default_dump and default_dump.get("cpuTarget") != "i486":
        fail(
            "the default -CpuTarget is %r; it must stay 'i486' so that an "
            "unqualified build keeps producing the release artefact"
            % default_dump.get("cpuTarget")
        )

    # 2. The i486 release paths must be exactly what they have always been.
    if default_dump:
        if default_dump.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail(
                "the i486 profile suffix is %r; it must stay %r"
                % (default_dump.get("profileSuffix"), RELEASE_I486_SUFFIX)
            )
        expected_root = "<repo>\\out\\dos" + RELEASE_I486_SUFFIX
        if default_dump.get("outputRoot") != expected_root:
            fail(
                "the i486 output root is %r; it must stay %r"
                % (default_dump.get("outputRoot"), expected_root)
            )
        if default_dump.get("executable") != expected_root + "\\quake.exe":
            fail(
                "the i486 executable is %r; it must stay under the release root"
                % default_dump.get("executable")
            )

    # 3. Both targets match their golden flag lists.
    i486 = dump_flags("-CpuTarget", "i486")
    i386 = dump_flags("-CpuTarget", "i386")
    compare("i486", i486, load_golden("i486"))
    compare("i386", i386, load_golden("i386"))

    # 4. The two targets are genuinely separated, and only in the architecture.
    if i486 and i386:
        if i486.get("outputRoot") == i386.get("outputRoot"):
            fail("both targets resolve to %r" % i486.get("outputRoot"))
        if i486.get("objectRoot") == i386.get("objectRoot"):
            fail("both targets resolve to the object root %r" % i486.get("objectRoot"))
        if not str(i386.get("outputRoot", "")).startswith(
            "<repo>\\out\\dos-i386-"
        ):
            fail(
                "the i386 output root must live under out\\dos-i386-; it is %r"
                % i386.get("outputRoot")
            )

        # The i386 flag lists must differ from i486 only in the architecture
        # entries and the TARGET_I386 switch.  Anything else means the two
        # codepaths have drifted apart in a way nobody asked for.
        for list_name in ("cFlags", "asmFlags", "linkFlags"):
            i486_flags = i486.get(list_name, [])
            i386_flags = i386.get(list_name, [])
            allowed = {
                "-march=i486",
                "-march=i386",
                "-mtune=i486",
                "-mtune=i386",
                "-DTARGET_I386",
            }
            # Paths differ between the targets by design, and the link list
            # carries the output executable as its last argument.
            is_path = lambda flag: "<repo>" in flag or flag == "<objects>"
            only_i386 = [f for f in i386_flags if f not in i486_flags and not is_path(f)]
            only_i486 = [f for f in i486_flags if f not in i386_flags and not is_path(f)]
            stray = [f for f in only_i386 + only_i486 if f not in allowed]
            if stray:
                fail(
                    "%s differs between targets by more than the architecture "
                    "flags and TARGET_I386: %r" % (list_name, stray)
                )

        if "-DTARGET_I386" not in i386.get("asmFlags", []):
            fail("the i386 build does not pass -DTARGET_I386 to the assembler")
        if "-DTARGET_I386" in i486.get("asmFlags", []):
            fail("the i486 build passes -DTARGET_I386 to the assembler")
        if "-DTARGET_I386" in i486.get("cFlags", []):
            fail("the i486 build passes -DTARGET_I386 to the C compiler")

    # 5. Source inventory is unchanged: 83 retained C (82 standalone, net_comx.c
    #    included by another unit), 21 assembly sources.
    for target, dump in (("i486", i486), ("i386", i386)):
        if not dump:
            continue
        if dump.get("cSourceCount") != 83:
            fail("%s: expected 83 retained C sources, got %r" % (target, dump.get("cSourceCount")))
        if dump.get("standaloneCSourceCount") != 82:
            fail(
                "%s: expected 82 standalone C sources, got %r"
                % (target, dump.get("standaloneCSourceCount"))
            )
        if dump.get("allAssemblySourceCount") != 21:
            fail(
                "%s: expected 21 assembly sources, got %r"
                % (target, dump.get("allAssemblySourceCount"))
            )

    if failures:
        print("test-build-dos: FAIL (%d)" % len(failures))
        for message in failures:
            print("  - %s" % message)
        return 1

    print("test-build-dos: PASS")
    print("  default target          i486")
    print("  i486 profile suffix     %s" % RELEASE_I486_SUFFIX)
    print("  i386 profile suffix     %s" % i386.get("profileSuffix", "<unavailable>"))
    print("  i486 flag list          golden-pinned (%d C, %d asm flags)"
          % (len(i486.get("cFlags", [])), len(i486.get("asmFlags", []))))
    print("  i386 flag list          golden-pinned (%d C, %d asm flags)"
          % (len(i386.get("cFlags", [])), len(i386.get("asmFlags", []))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
