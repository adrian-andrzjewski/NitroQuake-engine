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
* the resolved i486 suffix and output root stay explicitly pinned, so every
  intentional selector promotion is visible in the release profile and its
  `out\dos-timedemo-*` paths;
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

import hashlib
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from _nq import BuildFlagsError, dump_flags as _dump_flags, portable  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN_DIR = os.path.join(REPO_ROOT, "tools", "golden")

# The current i486 release profile suffix. Duplicated here on purpose:
# build-dos.ps1 computes it from the selector defaults, and this literal is the
# independent check that the computation still produces it.
RELEASE_I486_SUFFIX = (
    "-memasm-fillrectasm-zpointasm-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist"
    "-aliasmatrixasm-aliasgradientasm-aliaslinescanasm-lightmapstylesasm-fusedlightmapasm-dlightasm-dlightpushasm-marklightsasm-bspwalkasm-blobexplosionasm-spriteframeasm-spritedrawasm-spritesetupasm-mathclosureasm-efragstoreasm"
)

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def dump_flags(*extra: str) -> dict:
    """Resolved configuration with repo paths made checkout-portable.

    A failure is recorded rather than raised, because this tool reports every way
    it can disagree with the golden in one summary rather than stopping at the
    first -- but a missing pwsh is recorded too, since that used to surface as a
    FileNotFoundError from inside subprocess.
    """
    try:
        return portable(_dump_flags(*extra))
    except BuildFlagsError as error:
        fail(str(error))
        return {}


def load_golden(target: str) -> dict:
    path = os.path.join(GOLDEN_DIR, "build-flags-%s.json" % target)
    if not os.path.isfile(path):
        fail("missing golden flag file %s" % path)
        return {}
    with open(path, "r", encoding="ascii") as handle:
        expected = json.load(handle)
    # Directory hashes include the physical checkout path. Recompute those
    # paths from the pinned suffix/inventory so isolated worktrees exercise the
    # same golden flags instead of inheriting another checkout's hash.
    paths = expected_paths(expected)
    expected.update(paths)
    expected["linkFlags"] = [
        "-Wl,-Map=" + paths["executable"] + ".map" if flag.startswith("-Wl,-Map=")
        else paths["executable"] if flag.endswith("\\quake.exe") else flag
        for flag in expected["linkFlags"]
    ]
    return expected


def expected_paths(config: dict) -> dict:
    root = os.path.join(REPO_ROOT, "out", "dos" + config["profileSuffix"])
    if max(len(os.path.join(root, "quake.exe")), len(os.path.join(root, "quake.exe.map"))) > 259:
        digest = hashlib.sha256(("profile-output-v1|" + root).encode("utf-8")).hexdigest()[:16]
        root = os.path.join(REPO_ROOT, "out", "profile-" + digest)
    objects = os.path.join(root, "obj")
    sources = config["cSources"] + config["assemblySources"]
    longest = max(sources, key=len)
    if len(os.path.join(objects, os.path.splitext(longest)[0] + ".obj")) > 259:
        digest = hashlib.sha256(("object-root-v1|" + root + "|obj").encode("utf-8")).hexdigest()[:16]
        objects = os.path.join(REPO_ROOT, "out", "obj-" + digest + "-obj")
    return {
        "outputRoot": root.replace(REPO_ROOT, "<repo>"),
        "objectRoot": objects.replace(REPO_ROOT, "<repo>"),
        "executable": os.path.join(root, "quake.exe").replace(REPO_ROOT, "<repo>"),
    }


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
    host_tool_test = subprocess.run(
        [sys.executable, os.path.join(REPO_ROOT, "tools", "test-djgpp-assembler-tool.py")],
        capture_output=True,
        text=True,
    )
    if host_tool_test.returncode:
        fail("the hash-bound DJASM host-helper fallback failed: " + host_tool_test.stderr.strip())
    elif host_tool_test.stdout.strip():
        print(host_tool_test.stdout.strip())

    with open(os.path.join(REPO_ROOT, "tools", "build-dos.ps1"), "r", encoding="utf-8") as handle:
        build_script = handle.read()
    for contract in (
        '"-Wl,-Map=$linkMap"',
        "verify-executable-isa.ps1",
        "linkedInstructionsVerified",
    ):
        if contract not in build_script:
            fail("the normal release build is missing linked ISA contract %r" % contract)

    # The selected hardware contract is an 80486DX with its 387-compatible x87.
    # Keep the emulator profile and its timedemo hash pin aligned so the runtime
    # fixture cannot silently fall back to a 486SX/no-FPU configuration.
    dosbox_profile_path = os.path.join(REPO_ROOT, "tools", "dosbox-x-486-high.conf")
    try:
        with open(dosbox_profile_path, "rb") as handle:
            dosbox_profile_bytes = handle.read()
        dosbox_profile_text = dosbox_profile_bytes.decode("ascii").replace("\r\n", "\n")
        in_cpu_section = False
        cpu_options: dict[str, str] = {}
        for line in dosbox_profile_text.splitlines():
            stripped = line.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                in_cpu_section = stripped.lower() == "[cpu]"
            elif in_cpu_section and stripped and not stripped.startswith("#") and "=" in stripped:
                key, value = stripped.split("=", 1)
                cpu_options[key.strip().lower()] = value.strip().lower()
        if cpu_options.get("cputype") != "486":
            fail("the DOSBox-X compatibility profile must set cputype=486")
        if cpu_options.get("fpu") != "387":
            fail("the DOSBox-X compatibility profile must set fpu=387 for the 486DX x87 contract")

        profile_hash = hashlib.sha256(dosbox_profile_text.encode("ascii")).hexdigest().upper()
        with open(os.path.join(REPO_ROOT, "tools", "timedemo-dos.ps1"), "r", encoding="utf-8") as handle:
            timedemo_script = handle.read()
        hash_match = re.search(
            r"ExpectedProfileSha256\s*=\s*'([0-9A-Fa-f]{64})'", timedemo_script
        )
        if hash_match is None:
            fail("the timedemo DOSBox profile hash pin is missing or malformed")
        elif hash_match.group(1).upper() != profile_hash:
            fail(
                "the DOSBox-X 486 profile hash is %s, but timedemo-dos.ps1 pins %s"
                % (profile_hash, hash_match.group(1).upper())
            )
    except (OSError, UnicodeDecodeError) as error:
        fail("could not verify the DOSBox-X 486DX/x87 profile: %s" % error)

    with open(os.path.join(REPO_ROOT, "tools", "verify-executable-isa.ps1"), "r", encoding="utf-8") as handle:
        verification_script = handle.read()
    for contract in ("isa-audit-linked.ps1", "final-executable-isa-ranges.py", "startup-linked-proof.py",
                     "runtime-source-proofs", "-FailOnViolation"):
        # Runtime reconstruction is delegated by the linked verifier.
        text = verification_script
        if contract == "runtime-source-proofs":
            with open(os.path.join(REPO_ROOT, "tools", "isa-audit-linked.ps1"), "r", encoding="utf-8") as handle:
                text += handle.read()
        if contract not in text:
            fail("the release ISA verifier is missing contract %r" % contract)
    hashed_output_rewrite = build_script.find(
        "$outputRoot = Join-Path $repoOutRoot ('profile-'"
    )
    hashed_map_rewrite = build_script.find(
        "$linkMap = Join-Path $outputRoot ($executableName + '.map')",
        hashed_output_rewrite + 1,
    )
    if hashed_output_rewrite < 0 or hashed_map_rewrite < 0:
        fail("the hashed long-profile output path does not recompute its linker-map path")

    # 1. The default target must be the retained release profile.
    default_dump = dump_flags()
    if default_dump and default_dump.get("cpuTarget") != "i486":
        fail(
            "the default -CpuTarget is %r; it must stay 'i486' so that an "
            "unqualified build keeps producing the release artefact"
            % default_dump.get("cpuTarget")
        )
    if default_dump:
        damage_parse_define = "-DASM486_V_PARSE_DAMAGE"
        if any(
            damage_parse_define in default_dump.get(language, [])
            for language in ("cFlags", "asmFlags")
        ):
            fail("the default damage-parse selector must remain C and leave ASM486_V_PARSE_DAMAGE undefined")
        if "vparsedamageasm" in default_dump.get("profileSuffix", ""):
            fail("the default damage-parse selector must not change the release suffix")
        parse_particle_effect_define = "-DASM486_PARSE_PARTICLE_EFFECT"
        if any(
            parse_particle_effect_define in default_dump.get(language, [])
            for language in ("cFlags", "asmFlags")
        ):
            fail("the default particle-effect parser selector must remain C")
        if "parseparticleeffectasm" in default_dump.get("profileSuffix", ""):
            fail("the default particle-effect parser selector must not change the release suffix")
        blob_explosion_define = "-DASM486_BLOB_EXPLOSION"
        if any(blob_explosion_define not in default_dump.get(language, [])
               for language in ("cFlags", "asmFlags")):
            fail("the default i486 BlobExplosion selector must compile its assembly implementation")
        bsp_walk_define = "-DASM486_BSP_WALK"
        if any(bsp_walk_define not in default_dump.get(language, [])
               for language in ("cFlags", "asmFlags")):
            fail("the default i486 BSP-walk selector must compile its assembly implementation")

    # 2. Keep the release suffix stable and use its descriptive root unless the
    #    executable or linker-map path would exceed the legacy Windows limit.
    if default_dump:
        if default_dump.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail(
                "the i486 profile suffix is %r; it must stay %r"
                % (default_dump.get("profileSuffix"), RELEASE_I486_SUFFIX)
            )
        unhashed_root = os.path.join(REPO_ROOT, "out", "dos" + RELEASE_I486_SUFFIX)
        unhashed_executable = os.path.join(unhashed_root, "quake.exe")
        unhashed_map = unhashed_executable + ".map"
        if max(len(unhashed_executable), len(unhashed_map)) > 259:
            output_hash = hashlib.sha256(
                ("profile-output-v1|" + unhashed_root).encode("utf-8")
            ).hexdigest()[:16]
            expected_root = "<repo>\\out\\profile-" + output_hash
        else:
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
        actual_executable = str(default_dump.get("executable", "")).replace(
            "<repo>", REPO_ROOT
        )
        map_flags = [
            flag for flag in default_dump.get("linkFlags", [])
            if str(flag).startswith("-Wl,-Map=")
        ]
        if len(map_flags) != 1:
            fail("the i486 release must resolve exactly one linker map path")
        else:
            actual_map = str(map_flags[0]).split("=", 1)[1].replace("<repo>", REPO_ROOT)
            if max(len(actual_executable), len(actual_map)) > 259:
                fail("the i486 executable or linker-map path exceeds the legacy Windows limit")

    # 3. Both targets match their golden flag lists.
    i486 = dump_flags("-CpuTarget", "i486")
    i386 = dump_flags("-CpuTarget", "i386")
    compare("i486", i486, load_golden("i486"))
    compare("i386", i386, load_golden("i386"))

    # Do not rely on the goldens alone for the CPU/FPU identity: explicitly
    # assert the hardware choice and GCC's x87 code-generation mode.
    for target_name, target_flags, expected_cpu_model in (
        ("i486", i486, "486DX"),
        ("i386", i386, "386"),
    ):
        if not target_flags:
            continue
        if target_flags.get("cpuModel") != expected_cpu_model:
            fail(
                "%s cpuModel is %r; expected %r"
                % (target_name, target_flags.get("cpuModel"), expected_cpu_model)
            )
        if target_flags.get("fpuModel") != "387-compatible" or target_flags.get("fpuRequired") is not True:
            fail("%s must require a 387-compatible x87 FPU" % target_name)
        if target_flags.get("floatingPointMode") != "387":
            fail("%s floatingPointMode must stay 387" % target_name)
        c_flags = target_flags.get("cFlags", [])
        if c_flags.count("-mfpmath=387") != 1:
            fail("%s must pass exactly one -mfpmath=387 C compiler flag" % target_name)
        if any(flag in c_flags for flag in ("-msoft-float", "-mno-80387", "-mfpmath=sse")):
            fail("%s C flags disable the required 387-compatible x87" % target_name)

    expected_source_flags = {
        "r_main.c": ["-fno-jump-tables"],
        "mathlib.c": ["-fno-jump-tables"],
        "host_cmd.c": ["-fno-jump-tables"],
        "pr_edict.c": ["-fno-delete-null-pointer-checks"],
        "wad.c": ["-fno-delete-null-pointer-checks"],
    }
    for target_name, target_flags in (("i486", i486), ("i386", i386)):
        if target_flags and target_flags.get("cSourceExtraFlags") != expected_source_flags:
            fail(
                "%s per-source compatibility flags are %r; expected %r"
                % (target_name, target_flags.get("cSourceExtraFlags"), expected_source_flags)
            )

    # Benchmark-only assembly diagnostics call C helpers, so both compiler
    # frontends must receive the same build switch. Release assembly stays free
    # of those calls.
    benchmark = dump_flags("-Benchmark")
    if benchmark and i486:
        if "-DBENCH486" not in benchmark.get("cFlags", []):
            fail("the benchmark C flags omit -DBENCH486")
        if "-DBENCH486" not in benchmark.get("asmFlags", []):
            fail("the benchmark assembly flags omit -DBENCH486")
        if "-DBENCH486" in i486.get("cFlags", []) or "-DBENCH486" in i486.get("asmFlags", []):
            fail("the release i486 flags include benchmark-only -DBENCH486")

    # Visual-only renderer comparisons use an isolated output directory so a
    # -SkipIsaAudit build cannot replace a normal profile's strict manifest.
    visual_output = os.path.join(REPO_ROOT, "out", "visual-parity-test-profile")
    visual = dump_flags(
        "-Benchmark", "-CpuTarget", "i486", "-SkipIsaAudit",
        "-DiagnosticOutputRoot", visual_output,
    )
    if visual:
        expected_visual_root = "<repo>\\out\\visual-parity-test-profile"
        if visual.get("outputRoot") != expected_visual_root:
            fail(
                "the visual-only output root is %r; expected isolated path %r"
                % (visual.get("outputRoot"), expected_visual_root)
            )
        if visual.get("executable") != expected_visual_root + "\\qbench.exe":
            fail("the visual-only benchmark executable did not stay under its isolated output root")
    try:
        _dump_flags("-Benchmark", "-CpuTarget", "i486", "-DiagnosticOutputRoot", visual_output)
        fail("the isolated visual output accepted a build without explicit -SkipIsaAudit")
    except BuildFlagsError:
        pass
    outside_output = os.path.join(os.path.dirname(REPO_ROOT), "nq-visual-parity-outside")
    try:
        _dump_flags(
            "-Benchmark", "-CpuTarget", "i486", "-SkipIsaAudit",
            "-DiagnosticOutputRoot", outside_output,
        )
        fail("the visual-only output accepted a path outside this checkout's out directory")
    except BuildFlagsError:
        pass

    # 4. The two targets are genuinely separated by architecture plus the
    #    promoted i486-only renderer selectors.
    if i486 and i386:
        if i486.get("outputRoot") == i386.get("outputRoot"):
            fail("both targets resolve to %r" % i486.get("outputRoot"))
        if i486.get("objectRoot") == i386.get("objectRoot"):
            fail("both targets resolve to the object root %r" % i486.get("objectRoot"))
        if i386.get("outputRoot") != expected_paths(load_golden("i386"))["outputRoot"]:
            fail(
                "the i386 output root must match its independent target profile; it is %r"
                % i386.get("outputRoot")
            )

        # The i386 flag lists may omit the i486-default MarkLights and
        # R_PushDlights paths; their C references remain the i386 defaults.
        # Anything else means the codepaths have drifted unexpectedly.
        for list_name in ("cFlags", "asmFlags", "linkFlags"):
            i486_flags = i486.get(list_name, [])
            i386_flags = i386.get(list_name, [])
            allowed = {
                "-march=i486",
                "-march=i386",
                "-mtune=i486",
                "-mtune=i386",
                "-DTARGET_I386",
                "-DASM486_MARK_LIGHTS",
                "-DASM486_DYNAMIC_LIGHT_PUSH",
                "-DASM486_SPRITE_SETUP",
                "-DASM486_SPRITE_DRAW",
                "-DASM486_SPRITE_FRAME",
                "-DASM486_BLOB_EXPLOSION",
                "-DASM486_BSP_WALK",
                "-DASM486_MATH_CLOSURE",
                "-DASM486_EFRAG_STORE",
            }
            # Paths differ between the targets by design, and the link list
            # carries the output executable as its last argument.
            is_path = lambda flag: "<repo>" in flag or flag == "<objects>"
            only_i386 = [f for f in i386_flags if f not in i486_flags and not is_path(f)]
            only_i486 = [f for f in i486_flags if f not in i386_flags and not is_path(f)]
            stray = [f for f in only_i386 + only_i486 if f not in allowed]
            if stray:
                fail(
                    "%s differs between targets by more than architecture, "
                    "TARGET_I386, and the promoted i486 renderer defaults: %r"
                    % (list_name, stray)
                )

        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_MARK_LIGHTS" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted -DASM486_MARK_LIGHTS" % flags_name)
            if "-DASM486_MARK_LIGHTS" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted MarkLights assembly" % flags_name)
            if "-DASM486_DYNAMIC_LIGHT_PUSH" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted R_PushDlights assembly" % flags_name)
            if "-DASM486_DYNAMIC_LIGHT_PUSH" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted R_PushDlights assembly" % flags_name)
            if "-DASM486_SPRITE_SETUP" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted sprite-setup assembly" % flags_name)
            if "-DASM486_SPRITE_SETUP" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted sprite setup" % flags_name)
            if "-DASM486_SPRITE_DRAW" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted sprite-draw assembly" % flags_name)
            if "-DASM486_SPRITE_DRAW" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted sprite draw" % flags_name)
            if "-DASM486_SPRITE_FRAME" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted sprite-frame assembly" % flags_name)
            if "-DASM486_SPRITE_FRAME" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted sprite frame" % flags_name)
            if "-DASM486_MATH_CLOSURE" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted math-closure assembly" % flags_name)
            if "-DASM486_MATH_CLOSURE" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted math-closure assembly" % flags_name)
            if "-DASM486_EFRAG_STORE" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted efrag-store assembly" % flags_name)
            if "-DASM486_EFRAG_STORE" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted efrag-store assembly" % flags_name)
            if "-DASM486_BLOB_EXPLOSION" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted R_BlobExplosion assembly" % flags_name)
            if "-DASM486_BLOB_EXPLOSION" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted R_BlobExplosion assembly" % flags_name)
            if "-DASM486_BSP_WALK" not in i486.get(flags_name, []):
                fail("the i486 release %s omit promoted R_RecursiveWorldNode assembly" % flags_name)
            if "-DASM486_BSP_WALK" in i386.get(flags_name, []):
                fail("the separate i386 %s enable i486-promoted R_RecursiveWorldNode assembly" % flags_name)

        if "-DTARGET_I386" not in i386.get("asmFlags", []):
            fail("the i386 build does not pass -DTARGET_I386 to the assembler")
        if "-DTARGET_I386" in i486.get("asmFlags", []):
            fail("the i486 build passes -DTARGET_I386 to the assembler")
        if "-DTARGET_I386" in i486.get("cFlags", []):
            fail("the i486 build passes -DTARGET_I386 to the C compiler")

    # 5. The active sky-span helper is selectable, and C remains the default
    #    until its full-render performance clears the project's promotion gate.
    sky_span_c = dump_flags("-SkySpanImplementation", "c")
    sky_span_asm = dump_flags("-SkySpanImplementation", "asm")
    if sky_span_c and sky_span_asm:
        if sky_span_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sky-span C selector changes the retained i486 profile suffix")
        if "-skyasm" not in sky_span_asm.get("profileSuffix", ""):
            fail("the sky-span assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SKY_SPAN" in sky_span_c.get(flags_name, []):
                fail("the sky-span C selector enables ASM486_SKY_SPAN in %s" % flags_name)
            if "-DASM486_SKY_SPAN" not in sky_span_asm.get(flags_name, []):
                fail("the sky-span assembly selector omits ASM486_SKY_SPAN from %s" % flags_name)

    warp_c = dump_flags("-WarpScreenImplementation", "c")
    warp_asm = dump_flags("-WarpScreenImplementation", "asm")
    if warp_c and warp_asm:
        if warp_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the warp-screen C selector changes the retained i486 profile suffix")
        if "-warpasm" not in warp_asm.get("profileSuffix", ""):
            fail("the warp-screen assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_WARP_SCREEN" in warp_c.get(flags_name, []):
                fail("the warp-screen C selector enables ASM486_WARP_SCREEN in %s" % flags_name)
            if "-DASM486_WARP_SCREEN" not in warp_asm.get(flags_name, []):
                fail("the warp-screen assembly selector omits ASM486_WARP_SCREEN from %s" % flags_name)

    solid_surface_c = dump_flags("-SolidSurfaceImplementation", "c")
    solid_surface_asm = dump_flags("-SolidSurfaceImplementation", "asm")
    if solid_surface_c and solid_surface_asm:
        if solid_surface_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the solid-surface C selector changes the retained i486 profile suffix")
        if "-solidasm" not in solid_surface_asm.get("profileSuffix", ""):
            fail("the solid-surface assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SOLID_SURFACE" in solid_surface_c.get(flags_name, []):
                fail("the solid-surface C selector enables ASM486_SOLID_SURFACE in %s" % flags_name)
            if "-DASM486_SOLID_SURFACE" not in solid_surface_asm.get(flags_name, []):
                fail("the solid-surface assembly selector omits ASM486_SOLID_SURFACE from %s" % flags_name)

    turbulent_scan_c = dump_flags("-TurbulentScanImplementation", "c")
    turbulent_scan_asm = dump_flags("-TurbulentScanImplementation", "asm")
    if turbulent_scan_c and turbulent_scan_asm:
        if turbulent_scan_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the turbulent-scan C selector changes the retained i486 profile suffix")
        if "-turbscan" not in turbulent_scan_asm.get("profileSuffix", ""):
            fail("the turbulent-scan assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_TURBULENT_SCAN" in turbulent_scan_c.get(flags_name, []):
                fail("the turbulent-scan C selector enables ASM486_TURBULENT_SCAN in %s" % flags_name)
            if "-DASM486_TURBULENT_SCAN" not in turbulent_scan_asm.get(flags_name, []):
                fail("the turbulent-scan assembly selector omits ASM486_TURBULENT_SCAN from %s" % flags_name)

    turbulent_inner_c = dump_flags("-TurbulentImplementation", "c")
    if turbulent_inner_c:
        if "-DASM486_TURBULENT_C" not in turbulent_inner_c.get("asmFlags", []):
            fail("the turbulent C inner-loop selector is not visible to assembly callers")

    lightmap_build_c = dump_flags("-LightMapBuildImplementation", "c")
    lightmap_build_asm = dump_flags("-LightMapBuildImplementation", "asm")
    if lightmap_build_c and lightmap_build_asm:
        if lightmap_build_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the lightmap-build C selector changes the retained i486 profile suffix")
        if "lightmapbuildasm" not in lightmap_build_asm.get("profileSuffix", ""):
            fail("the lightmap-build assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_LIGHTMAP_BUILD" in lightmap_build_c.get(flags_name, []):
                fail("the lightmap-build C selector enables ASM486_LIGHTMAP_BUILD in %s" % flags_name)
            if "-DASM486_LIGHTMAP_BUILD" not in lightmap_build_asm.get(flags_name, []):
                fail("the lightmap-build assembly selector omits ASM486_LIGHTMAP_BUILD from %s" % flags_name)

    surface_cache_c = dump_flags("-SurfaceCacheImplementation", "c")
    surface_cache_asm = dump_flags("-SurfaceCacheImplementation", "asm")
    if surface_cache_c and surface_cache_asm:
        if surface_cache_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the surface-cache C selector changes the retained i486 profile suffix")
        if "surfaceasm" not in surface_cache_asm.get("profileSuffix", ""):
            fail("the surface-cache assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SURFACE_CACHE_CHECK" in surface_cache_c.get(flags_name, []):
                fail("the surface-cache C selector enables ASM486_SURFACE_CACHE_CHECK in %s" % flags_name)
            if "-DASM486_SURFACE_CACHE_CHECK" not in surface_cache_asm.get(flags_name, []):
                fail("the surface-cache assembly selector omits ASM486_SURFACE_CACHE_CHECK from %s" % flags_name)

    surface_draw_c = dump_flags("-SurfaceDrawImplementation", "c")
    surface_draw_asm = dump_flags("-SurfaceDrawImplementation", "asm")
    if surface_draw_c and surface_draw_asm:
        if surface_draw_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the surface-draw C selector changes the retained i486 profile suffix")
        if "surfacedrawasm" not in surface_draw_asm.get("profileSuffix", ""):
            fail("the surface-draw assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SURFACE_DRAW" in surface_draw_c.get(flags_name, []):
                fail("the surface-draw C selector enables ASM486_SURFACE_DRAW in %s" % flags_name)
            if "-DASM486_SURFACE_DRAW" not in surface_draw_asm.get(flags_name, []):
                fail("the surface-draw assembly selector omits ASM486_SURFACE_DRAW from %s" % flags_name)

    surface_zgradient_c = dump_flags("-SurfaceZGradientImplementation", "c")
    surface_zgradient_asm = dump_flags("-SurfaceZGradientImplementation", "asm")
    if surface_zgradient_c and surface_zgradient_asm:
        if surface_zgradient_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the surface Z-gradient C selector changes the retained i486 profile suffix")
        if "surfacezasm" not in surface_zgradient_asm.get("profileSuffix", ""):
            fail("the surface Z-gradient assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SURFACE_ZGRADIENTS" in surface_zgradient_c.get(flags_name, []):
                fail("the surface Z-gradient C selector enables ASM486_SURFACE_ZGRADIENTS in %s" % flags_name)
            if "-DASM486_SURFACE_ZGRADIENTS" not in surface_zgradient_asm.get(flags_name, []):
                fail("the surface Z-gradient assembly selector omits ASM486_SURFACE_ZGRADIENTS from %s" % flags_name)

    surface_gradient_c = dump_flags("-SurfaceGradientImplementation", "c")
    surface_gradient_asm = dump_flags("-SurfaceGradientImplementation", "asm")
    if surface_gradient_c and surface_gradient_asm:
        if surface_gradient_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the surface-gradient C selector changes the retained i486 profile suffix")
        if "surfacegradasm" not in surface_gradient_asm.get("profileSuffix", ""):
            fail("the surface-gradient assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SURFACE_GRADIENTS" in surface_gradient_c.get(flags_name, []):
                fail("the surface-gradient C selector enables ASM486_SURFACE_GRADIENTS in %s" % flags_name)
            if "-DASM486_SURFACE_GRADIENTS" not in surface_gradient_asm.get(flags_name, []):
                fail("the surface-gradient assembly selector omits ASM486_SURFACE_GRADIENTS from %s" % flags_name)

    surface_dispatch_c = dump_flags("-SurfaceDispatcherImplementation", "c")
    surface_dispatch_asm = dump_flags("-SurfaceDispatcherImplementation", "asm")
    if surface_dispatch_c and surface_dispatch_asm:
        if surface_dispatch_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the surface-dispatch C selector changes the retained i486 profile suffix")
        if "surfacesasm" not in surface_dispatch_asm.get("profileSuffix", ""):
            fail("the surface-dispatch assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SURFACE_DISPATCH" in surface_dispatch_c.get(flags_name, []):
                fail("the surface-dispatch C selector enables ASM486_SURFACE_DISPATCH in %s" % flags_name)
            if "-DASM486_SURFACE_DISPATCH" not in surface_dispatch_asm.get(flags_name, []):
                fail("the surface-dispatch assembly selector omits ASM486_SURFACE_DISPATCH from %s" % flags_name)

    bsp_walk_c = dump_flags("-BspWalkImplementation", "c")
    bsp_walk_asm = dump_flags("-BspWalkImplementation", "asm")
    if bsp_walk_c and bsp_walk_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-bspwalkasm", "", 1)
        if bsp_walk_c.get("profileSuffix") != c_reference_suffix:
            fail("the BSP-walk C selector does not isolate the C reference profile")
        if bsp_walk_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the BSP-walk assembly selector does not match the i486 release profile")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_BSP_WALK" in bsp_walk_c.get(flags_name, []):
                fail("the BSP-walk C selector enables ASM486_BSP_WALK in %s" % flags_name)
            if "-DASM486_BSP_WALK" not in bsp_walk_asm.get(flags_name, []):
                fail("the BSP-walk assembly selector omits ASM486_BSP_WALK from %s" % flags_name)

    sprite_beam_c = dump_flags("-SpriteBeamImplementation", "c")
    sprite_beam_asm = dump_flags("-SpriteBeamImplementation", "asm")
    if sprite_beam_c and sprite_beam_asm:
        if sprite_beam_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-beam C selector changes the retained i486 profile suffix")
        if "spritebeamasm" not in sprite_beam_asm.get("profileSuffix", ""):
            fail("the sprite-beam assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_BEAM" in sprite_beam_c.get(flags_name, []):
                fail("the sprite-beam C selector enables ASM486_SPRITE_BEAM in %s" % flags_name)
            if "-DASM486_SPRITE_BEAM" not in sprite_beam_asm.get(flags_name, []):
                fail("the sprite-beam assembly selector omits ASM486_SPRITE_BEAM from %s" % flags_name)

    sprite_clip_c = dump_flags("-SpriteClipImplementation", "c")
    sprite_clip_asm = dump_flags("-SpriteClipImplementation", "asm")
    if sprite_clip_c and sprite_clip_asm:
        if sprite_clip_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-clip C selector changes the retained i486 profile suffix")
        if "spriteclipasm" not in sprite_clip_asm.get("profileSuffix", ""):
            fail("the sprite-clip assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_CLIP" in sprite_clip_c.get(flags_name, []):
                fail("the sprite-clip C selector enables ASM486_SPRITE_CLIP in %s" % flags_name)
            if "-DASM486_SPRITE_CLIP" not in sprite_clip_asm.get(flags_name, []):
                fail("the sprite-clip assembly selector omits ASM486_SPRITE_CLIP from %s" % flags_name)

    sprite_frame_c = dump_flags("-SpriteFrameImplementation", "c")
    sprite_frame_asm = dump_flags("-SpriteFrameImplementation", "asm")
    if sprite_frame_c and sprite_frame_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-spriteframeasm", "")
        if sprite_frame_c.get("profileSuffix") != c_reference_suffix:
            fail("the sprite-frame C selector does not restore the C-reference suffix")
        if sprite_frame_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-frame assembly selector changes the promoted i486 suffix")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_FRAME" in sprite_frame_c.get(flags_name, []):
                fail("the sprite-frame C selector enables ASM486_SPRITE_FRAME in %s" % flags_name)
            if "-DASM486_SPRITE_FRAME" not in sprite_frame_asm.get(flags_name, []):
                fail("the sprite-frame assembly selector omits ASM486_SPRITE_FRAME from %s" % flags_name)

    sprite_gradient_c = dump_flags("-SpriteGradientImplementation", "c")
    sprite_gradient_asm = dump_flags("-SpriteGradientImplementation", "asm")
    if sprite_gradient_c and sprite_gradient_asm:
        if sprite_gradient_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-gradient C selector changes the retained i486 profile suffix")
        if "spritegradientasm" not in sprite_gradient_asm.get("profileSuffix", ""):
            fail("the sprite-gradient assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_GRADIENTS" in sprite_gradient_c.get(flags_name, []):
                fail("the sprite-gradient C selector enables ASM486_SPRITE_GRADIENTS in %s" % flags_name)
            if "-DASM486_SPRITE_GRADIENTS" not in sprite_gradient_asm.get(flags_name, []):
                fail("the sprite-gradient assembly selector omits ASM486_SPRITE_GRADIENTS from %s" % flags_name)

    sprite_scan_left_c = dump_flags("-SpriteScanLeftImplementation", "c")
    sprite_scan_left_asm = dump_flags("-SpriteScanLeftImplementation", "asm")
    if sprite_scan_left_c and sprite_scan_left_asm:
        if sprite_scan_left_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-scan-left C selector changes the retained i486 profile suffix")
        if "spritescanleftasm" not in sprite_scan_left_asm.get("profileSuffix", ""):
            fail("the sprite-scan-left assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_SCAN_LEFT" in sprite_scan_left_c.get(flags_name, []):
                fail("the sprite-scan-left C selector enables ASM486_SPRITE_SCAN_LEFT in %s" % flags_name)
            if "-DASM486_SPRITE_SCAN_LEFT" not in sprite_scan_left_asm.get(flags_name, []):
                fail("the sprite-scan-left assembly selector omits ASM486_SPRITE_SCAN_LEFT from %s" % flags_name)

    sprite_scan_right_c = dump_flags("-SpriteScanRightImplementation", "c")
    sprite_scan_right_asm = dump_flags("-SpriteScanRightImplementation", "asm")
    if sprite_scan_right_c and sprite_scan_right_asm:
        if sprite_scan_right_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-scan-right C selector changes the retained i486 profile suffix")
        if "spritescanrightasm" not in sprite_scan_right_asm.get("profileSuffix", ""):
            fail("the sprite-scan-right assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_SCAN_RIGHT" in sprite_scan_right_c.get(flags_name, []):
                fail("the sprite-scan-right C selector enables ASM486_SPRITE_SCAN_RIGHT in %s" % flags_name)
            if "-DASM486_SPRITE_SCAN_RIGHT" not in sprite_scan_right_asm.get(flags_name, []):
                fail("the sprite-scan-right assembly selector omits ASM486_SPRITE_SCAN_RIGHT from %s" % flags_name)

    sprite_draw_c = dump_flags("-SpriteDrawImplementation", "c")
    sprite_draw_asm = dump_flags("-SpriteDrawImplementation", "asm")
    if sprite_draw_c and sprite_draw_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-spritedrawasm", "")
        if sprite_draw_c.get("profileSuffix") != c_reference_suffix:
            fail("the sprite-draw C selector does not restore the C-reference suffix")
        if sprite_draw_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-draw assembly selector changes the promoted i486 suffix")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_DRAW" in sprite_draw_c.get(flags_name, []):
                fail("the sprite-draw C selector enables ASM486_SPRITE_DRAW in %s" % flags_name)
            if "-DASM486_SPRITE_DRAW" not in sprite_draw_asm.get(flags_name, []):
                fail("the sprite-draw assembly selector omits ASM486_SPRITE_DRAW from %s" % flags_name)

    sprite_setup_c = dump_flags("-SpriteSetupImplementation", "c")
    sprite_setup_asm = dump_flags("-SpriteSetupImplementation", "asm")
    if sprite_setup_c and sprite_setup_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-spritesetupasm", "")
        if sprite_setup_c.get("profileSuffix") != c_reference_suffix:
            fail("the sprite-setup C selector does not restore the C-reference suffix")
        if sprite_setup_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the sprite-setup assembly selector changes the promoted i486 suffix")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SPRITE_SETUP" in sprite_setup_c.get(flags_name, []):
                fail("the sprite-setup C selector enables ASM486_SPRITE_SETUP in %s" % flags_name)
            if "-DASM486_SPRITE_SETUP" not in sprite_setup_asm.get(flags_name, []):
                fail("the sprite-setup assembly selector omits ASM486_SPRITE_SETUP from %s" % flags_name)

    for selector, define, token in (
        ("SpriteOrientationImplementation", "ASM486_SPRITE_ORIENTATION", "spriteorientationasm"),
        ("RenderMathImplementation", "ASM486_RENDER_MATH", "rendermathasm"),
        ("AnimatedLightImplementation", "ASM486_ANIMATED_LIGHT", "animatedlightasm"),
        ("PointLightImplementation", "ASM486_POINT_LIGHT", "pointlightasm"),
        ("FrameControlImplementation", "ASM486_FRAME_CONTROL", "framecontrolasm"),
        ("PaletteImplementation", "ASM486_PALETTE", "paletteasm"),
        ("MathClosureImplementation", "ASM486_MATH_CLOSURE", "mathclosureasm"),
        ("VisibilityImplementation", "ASM486_VISIBILITY", "visibilityasm"),
        ("PublicBindingsImplementation", "ASM486_PUBLIC_BINDINGS", "bindingsasm"),
        ("SkyImplementation", "ASM486_SKY", "skyasm"),
        ("RenderDispatchImplementation", "ASM486_RENDER_DISPATCH", "dispatchasm"),
        ("DrawingDriverImplementation", "ASM486_DRAWING_DRIVER", "driverasm"),
        ("ViewControlImplementation", "ASM486_VIEW_CONTROL", "viewcontrolasm"),
        ("DamageParseImplementation", "ASM486_V_PARSE_DAMAGE", "vparsedamageasm"),
        ("DrawingImplementation", "ASM486_DRAWING", "drawingasm"),
        ("ConsoleImplementation", "ASM486_CONSOLE_INPUT", "consoleinputasm"),
        ("ScreenNotifyImplementation", "ASM486_SCREEN_NOTIFY", "screennotifyasm"),
        ("ScreenCenterStringImplementation", "ASM486_SCREEN_CENTER_STRING", "screencenterasm"),
        ("ScreenEraseCenterStringImplementation", "ASM486_SCREEN_ERASE_CENTER_STRING", "screeneraseasm"),
        ("ScreenConsoleSetupImplementation", "ASM486_SCREEN_CONSOLE_SETUP", "screenconsolesetupasm"),
        ("ChaseImplementation", "ASM486_CHASE", "chaseasm"),
    ):
        reference = dump_flags("-" + selector, "c")
        candidate = dump_flags("-" + selector, "asm")
        if reference and candidate:
            reference_suffix = reference.get("profileSuffix", "")
            candidate_suffix = candidate.get("profileSuffix", "")
            token_suffix = "-" + token
            if candidate_suffix.count(token_suffix) != 1 or candidate_suffix.replace(token_suffix, "", 1) != reference_suffix:
                fail(selector + " does not isolate its assembly profile")
            for language in ("cFlags", "asmFlags"):
                if "-D" + define in reference.get(language, []):
                    fail(selector + " leaks its assembly define into C selection")
                if "-D" + define not in candidate.get(language, []):
                    fail(selector + " omits its assembly define from " + language)

    for value_name, value in (("C", "c"), ("assembly", "asm")):
        view_control = dump_flags("-ViewControlImplementation", value)
        if view_control and "screen_fovasm.s" not in view_control.get("assemblySources", []):
            fail("the view-control %s selector omits screen_fovasm.s from the source inventory" % value_name)

    console_input_reference = dump_flags("-ConsoleImplementation", "c")
    console_input_candidate = dump_flags("-ConsoleImplementation", "asm")
    for name, dump in (("C", console_input_reference), ("assembly", console_input_candidate)):
        if dump and "con_inputasm.s" not in dump.get("assemblySources", []):
            fail("the Con_DrawInput %s selector omits con_inputasm.s from the source inventory" % name)

    screen_notify_reference = dump_flags("-ScreenNotifyImplementation", "c")
    screen_notify_candidate = dump_flags("-ScreenNotifyImplementation", "asm")
    for name, dump in (("C", screen_notify_reference), ("assembly", screen_notify_candidate)):
        if dump and "screen_notifyasm.s" not in dump.get("assemblySources", []):
            fail("the SCR_DrawNotifyString %s selector omits screen_notifyasm.s from the source inventory" % name)

    screen_center_reference = dump_flags("-ScreenCenterStringImplementation", "c")
    screen_center_candidate = dump_flags("-ScreenCenterStringImplementation", "asm")
    for name, dump in (("C", screen_center_reference), ("assembly", screen_center_candidate)):
        if dump and "screen_centerasm.s" not in dump.get("assemblySources", []):
            fail("the SCR_DrawCenterString %s selector omits screen_centerasm.s from the source inventory" % name)

    screen_erase_reference = dump_flags("-ScreenEraseCenterStringImplementation", "c")
    screen_erase_candidate = dump_flags("-ScreenEraseCenterStringImplementation", "asm")
    for name, dump in (("C", screen_erase_reference), ("assembly", screen_erase_candidate)):
        if dump and "screen_eraseasm.s" not in dump.get("assemblySources", []):
            fail("the SCR_EraseCenterString %s selector omits screen_eraseasm.s from the source inventory" % name)

    screen_console_setup_reference = dump_flags("-ScreenConsoleSetupImplementation", "c")
    screen_console_setup_candidate = dump_flags("-ScreenConsoleSetupImplementation", "asm")
    for name, dump in (("C", screen_console_setup_reference), ("assembly", screen_console_setup_candidate)):
        if dump and "screen_consolesetupasm.s" not in dump.get("assemblySources", []):
            fail("the SCR_SetUpToDrawConsole %s selector omits screen_consolesetupasm.s from the source inventory" % name)

    for value_name, value in (("C", "c"), ("assembly", "asm")):
        damage_parse = dump_flags("-DamageParseImplementation", value)
        if damage_parse and "v_damageparse.s" not in damage_parse.get("assemblySources", []):
            fail("the damage-parse %s selector omits v_damageparse.s from the source inventory" % value_name)

    alias_control_args = ["-AliasPrepareImplementation", "asm", "-AliasBBoxProjectImplementation", "asm", "-AliasMatrixCompositionImplementation", "asm", "-AliasSetupLightingImplementation", "asm", "-AliasSetupFrameImplementation", "asm", "-AliasSetupSkinImplementation", "asm"]
    alias_control_reference = dump_flags(*alias_control_args, "-AliasControlImplementation", "c")
    alias_control_candidate = dump_flags(*alias_control_args, "-AliasControlImplementation", "asm")
    if alias_control_reference and alias_control_candidate:
        reference_suffix = alias_control_reference.get("profileSuffix", "")
        candidate_suffix = alias_control_candidate.get("profileSuffix", "")
        token_suffix = "-aliascontrolasm"
        if candidate_suffix.count(token_suffix) != 1 or candidate_suffix.replace(token_suffix, "", 1) != reference_suffix:
            fail("alias control assembly does not isolate its profile")
        for language in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_CONTROL" in alias_control_reference[language] or "-DASM486_ALIAS_CONTROL" not in alias_control_candidate[language]:
                fail("alias control definition does not follow selection")
    world_control_c = dump_flags("-WorldControlImplementation", "c")
    world_control_asm = dump_flags("-WorldControlImplementation", "asm")
    if world_control_c and world_control_asm:
        reference_suffix = world_control_c.get("profileSuffix", "")
        candidate_suffix = world_control_asm.get("profileSuffix", "")
        token_suffix = "-worldcontrolasm"
        if candidate_suffix.count(token_suffix) != 1 or candidate_suffix.replace(token_suffix, "", 1) != reference_suffix:
            fail("world control assembly does not isolate its profile")
        for language in ("cFlags", "asmFlags"):
            if "-DASM486_WORLD_CONTROL" in world_control_c[language] or "-DASM486_WORLD_CONTROL" not in world_control_asm[language]:
                fail("world control definition does not follow selection")

    render_world_c = dump_flags("-RenderWorldImplementation", "c")
    render_world_asm = dump_flags("-RenderWorldImplementation", "asm")
    if render_world_c and render_world_asm:
        if render_world_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the render-world C selector changes the retained i486 profile suffix")
        if "renderworldasm" not in render_world_asm.get("profileSuffix", ""):
            fail("the render-world assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_RENDER_WORLD" in render_world_c.get(flags_name, []):
                fail("the render-world C selector enables ASM486_RENDER_WORLD in %s" % flags_name)
            if "-DASM486_RENDER_WORLD" not in render_world_asm.get(flags_name, []):
                fail("the render-world assembly selector omits ASM486_RENDER_WORLD from %s" % flags_name)

    render_face_c = dump_flags("-RenderFaceImplementation", "c")
    render_face_asm = dump_flags("-RenderFaceImplementation", "asm")
    if render_face_c and render_face_asm:
        if render_face_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the render-face C selector changes the retained i486 profile suffix")
        if "renderfaceasm" not in render_face_asm.get("profileSuffix", ""):
            fail("the render-face assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_RENDER_FACE" in render_face_c.get(flags_name, []):
                fail("the render-face C selector enables ASM486_RENDER_FACE in %s" % flags_name)
            if "-DASM486_RENDER_FACE" not in render_face_asm.get(flags_name, []):
                fail("the render-face assembly selector omits ASM486_RENDER_FACE from %s" % flags_name)

    render_bmodel_face_c = dump_flags("-RenderBmodelFaceImplementation", "c")
    render_bmodel_face_asm = dump_flags("-RenderBmodelFaceImplementation", "asm")
    if render_bmodel_face_c and render_bmodel_face_asm:
        if render_bmodel_face_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the bmodel render-face C selector changes the retained i486 profile suffix")
        if "bmodelasm" not in render_bmodel_face_asm.get("profileSuffix", ""):
            fail("the bmodel render-face assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_RENDER_BMODEL_FACE" in render_bmodel_face_c.get(flags_name, []):
                fail("the bmodel render-face C selector enables ASM486_RENDER_BMODEL_FACE in %s" % flags_name)
            if "-DASM486_RENDER_BMODEL_FACE" not in render_bmodel_face_asm.get(flags_name, []):
                fail("the bmodel render-face assembly selector omits ASM486_RENDER_BMODEL_FACE from %s" % flags_name)

    alias_prepare_control = dump_flags("-AliasPrepareImplementation", "control")
    alias_prepare_local = dump_flags("-AliasPrepareImplementation", "local")
    alias_prepare_asm = dump_flags("-AliasPrepareImplementation", "asm")
    if alias_prepare_control and alias_prepare_local and alias_prepare_asm:
        if alias_prepare_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the default alias-prepare assembly selector changes the retained i486 profile suffix")
        if alias_prepare_control.get("profileSuffix") != RELEASE_I486_SUFFIX.replace(
            "-aliasmatrixasm", "-aliaspreparecontrol-aliasmatrixasm"
        ):
            fail("the alias-prepare control selector does not add its reference profile token")
        if "aliaslocal" not in alias_prepare_local.get("profileSuffix", ""):
            fail("the alias-prepare local selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_PREPARE" in alias_prepare_control.get(flags_name, []):
                fail("the alias-prepare control selector enables ASM486_ALIAS_PREPARE in %s" % flags_name)
            if "-DASM486_ALIAS_PREPARE" in alias_prepare_local.get(flags_name, []):
                fail("the alias-prepare local selector enables ASM486_ALIAS_PREPARE in %s" % flags_name)
            if "-DASM486_ALIAS_PREPARE" not in alias_prepare_asm.get(flags_name, []):
                fail("the alias-prepare assembly selector omits ASM486_ALIAS_PREPARE from %s" % flags_name)
            if "-DASM486_ALIAS_PREPARE_LOCAL" in alias_prepare_asm.get(flags_name, []):
                fail("the alias-prepare assembly selector enables ASM486_ALIAS_PREPARE_LOCAL in %s" % flags_name)
        if "-DASM486_ALIAS_PREPARE_LOCAL" not in alias_prepare_local.get("cFlags", []):
            fail("the alias-prepare local selector omits ASM486_ALIAS_PREPARE_LOCAL from cFlags")
        if "-DASM486_ALIAS_PREPARE_LOCAL" in alias_prepare_local.get("asmFlags", []):
            fail("the alias-prepare local selector enables ASM486_ALIAS_PREPARE_LOCAL in asmFlags")

    alias_clip_c = dump_flags("-AliasClipImplementation", "c")
    alias_clip_asm = dump_flags("-AliasClipImplementation", "asm")
    alias_clip_z_c = dump_flags("-AliasClipZImplementation", "c")
    alias_clip_z_asm = dump_flags(
        "-AliasClipImplementation", "asm",
        "-AliasClipZImplementation", "asm",
    )
    if alias_clip_c and alias_clip_asm:
        if alias_clip_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the alias-clip C selector changes the retained i486 profile suffix")
        if "aliasclipasm" not in alias_clip_asm.get("profileSuffix", ""):
            fail("the alias-clip assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_CLIP" in alias_clip_c.get(flags_name, []):
                fail("the alias-clip C selector enables ASM486_ALIAS_CLIP in %s" % flags_name)
            if "-DASM486_ALIAS_CLIP" not in alias_clip_asm.get(flags_name, []):
                fail("the alias-clip assembly selector omits ASM486_ALIAS_CLIP from %s" % flags_name)

    if alias_clip_z_c and alias_clip_z_asm:
        if alias_clip_z_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the alias Z-clip C selector changes the retained i486 profile suffix")
        if "aliasclipasm" not in alias_clip_z_asm.get("profileSuffix", ""):
            fail("the alias Z-clip assembly selector omits the generic alias-clip token")
        if "aliasclipzasm" not in alias_clip_z_asm.get("profileSuffix", ""):
            fail("the alias Z-clip assembly selector does not add its profile token")
        if "-DASM486_ALIAS_CLIP_Z" in alias_clip_z_c.get("asmFlags", []):
            fail("the alias Z-clip C selector enables ASM486_ALIAS_CLIP_Z")
        if "-DASM486_ALIAS_CLIP_Z" not in alias_clip_z_asm.get("asmFlags", []):
            fail("the alias Z-clip assembly selector omits ASM486_ALIAS_CLIP_Z")
        if "-DASM486_ALIAS_CLIP_Z" in alias_clip_z_asm.get("cFlags", []):
            fail("the alias Z-clip assembly selector leaks ASM486_ALIAS_CLIP_Z into cFlags")

    try:
        _dump_flags("-AliasClipZImplementation", "asm")
        fail("the alias Z-clip assembly selector is accepted without the alias-clip assembly path")
    except BuildFlagsError:
        pass

    alias_project_c = dump_flags("-AliasProjectImplementation", "c")
    alias_project_asm = dump_flags("-AliasProjectImplementation", "asm")
    if alias_project_c and alias_project_asm:
        if "-DASM486_ALIAS_PROJECT" in alias_project_c.get("asmFlags", []):
            fail("the alias-project C selector enables ASM486_ALIAS_PROJECT in asmFlags")
        if "-DASM486_ALIAS_PROJECT" not in alias_project_asm.get("asmFlags", []):
            fail("the alias-project assembly selector omits ASM486_ALIAS_PROJECT from asmFlags")

    alias_matrix_c = dump_flags("-AliasMatrixCompositionImplementation", "c")
    alias_matrix_asm = dump_flags("-AliasMatrixCompositionImplementation", "asm")
    if alias_matrix_c and alias_matrix_asm:
        if "aliasmatrixc" not in alias_matrix_c.get("profileSuffix", ""):
            fail("the alias-matrix C selector does not name its implementation profile")
        if "aliasmatrixasm" not in alias_matrix_asm.get("profileSuffix", ""):
            fail("the alias-matrix assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_MATRIX_COMPOSE_ASM" in alias_matrix_c.get(flags_name, []):
                fail("the alias-matrix C selector enables the assembly path in %s" % flags_name)
            if "-DASM486_ALIAS_MATRIX_COMPOSE_ASM" not in alias_matrix_asm.get(flags_name, []):
                fail("the alias-matrix assembly selector omits its macro from %s" % flags_name)

    alias_setup_lighting_c = dump_flags("-AliasSetupLightingImplementation", "c")
    alias_setup_lighting_asm = dump_flags("-AliasSetupLightingImplementation", "asm")
    if alias_setup_lighting_c and alias_setup_lighting_asm:
        if alias_setup_lighting_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the alias-lighting C selector changes the retained i486 profile suffix")
        if "aliaslightingasm" not in alias_setup_lighting_asm.get("profileSuffix", ""):
            fail("the alias-lighting assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_SETUP_LIGHTING" in alias_setup_lighting_c.get(flags_name, []):
                fail("the alias-lighting C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_SETUP_LIGHTING" not in alias_setup_lighting_asm.get(flags_name, []):
                fail("the alias-lighting assembly selector omits its macro from %s" % flags_name)

    alias_setup_frame_c = dump_flags("-AliasSetupFrameImplementation", "c")
    alias_setup_frame_asm = dump_flags("-AliasSetupFrameImplementation", "asm")
    if alias_setup_frame_c and alias_setup_frame_asm:
        if alias_setup_frame_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the alias-frame C selector changes the retained i486 profile suffix")
        if "aliasframeasm" not in alias_setup_frame_asm.get("profileSuffix", ""):
            fail("the alias-frame assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_SETUP_FRAME" in alias_setup_frame_c.get(flags_name, []):
                fail("the alias-frame C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_SETUP_FRAME" not in alias_setup_frame_asm.get(flags_name, []):
                fail("the alias-frame assembly selector omits its macro from %s" % flags_name)

    alias_setup_skin_c = dump_flags("-AliasSetupSkinImplementation", "c")
    alias_setup_skin_asm = dump_flags("-AliasSetupSkinImplementation", "asm")
    if alias_setup_skin_c and alias_setup_skin_asm:
        if alias_setup_skin_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the alias-skin C selector changes the retained i486 profile suffix")
        if "aliaskinasm" not in alias_setup_skin_asm.get("profileSuffix", ""):
            fail("the alias-skin assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_SETUP_SKIN" in alias_setup_skin_c.get(flags_name, []):
                fail("the alias-skin C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_SETUP_SKIN" not in alias_setup_skin_asm.get(flags_name, []):
                fail("the alias-skin assembly selector omits its macro from %s" % flags_name)

    alias_gradient_c = dump_flags("-AliasGradientImplementation", "c")
    alias_gradient_asm = dump_flags("-AliasGradientImplementation", "asm")
    if alias_gradient_c and alias_gradient_asm:
        if "aliasgradientc" not in alias_gradient_c.get("profileSuffix", ""):
            fail("the alias-gradient C selector does not add its profile token")
        if "aliasgradientasm" not in alias_gradient_asm.get("profileSuffix", ""):
            fail("the alias-gradient assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_GRADIENTS" in alias_gradient_c.get(flags_name, []):
                fail("the alias-gradient C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_GRADIENTS" not in alias_gradient_asm.get(flags_name, []):
                fail("the alias-gradient assembly selector omits its macro from %s" % flags_name)

    alias_line_scan_c = dump_flags("-AliasLineScanImplementation", "c")
    alias_line_scan_asm = dump_flags("-AliasLineScanImplementation", "asm")
    if alias_line_scan_c and alias_line_scan_asm:
        if alias_line_scan_c.get("profileSuffix") != RELEASE_I486_SUFFIX.replace(
            "-aliaslinescanasm", ""
        ):
            fail("the alias-line-scan C selector changes more than its own profile token")
        if "aliaslinescanasm" not in alias_line_scan_asm.get("profileSuffix", ""):
            fail("the alias-line-scan assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_LINE_SCAN" in alias_line_scan_c.get(flags_name, []):
                fail("the alias-line-scan C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_LINE_SCAN" not in alias_line_scan_asm.get(flags_name, []):
                fail("the alias-line-scan assembly selector omits its macro from %s" % flags_name)

    alias_edge_table_c = dump_flags("-AliasEdgeTableImplementation", "c")
    alias_edge_table_asm = dump_flags("-AliasEdgeTableImplementation", "asm")
    if alias_edge_table_c and alias_edge_table_asm:
        if alias_edge_table_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the default alias-edge-table assembly selector changes the retained i486 release suffix")
        if alias_edge_table_c.get("profileSuffix") != RELEASE_I486_SUFFIX.replace(
            "-lightmapstylesasm", "-aliasedgetablec-lightmapstylesasm"
        ):
            fail("the alias-edge-table C selector does not add its reference profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_EDGE_TABLE" in alias_edge_table_c.get(flags_name, []):
                fail("the alias-edge-table C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_EDGE_TABLE" not in alias_edge_table_asm.get(flags_name, []):
                fail("the alias-edge-table assembly selector omits its macro from %s" % flags_name)

    alias_skin_table_c = dump_flags("-AliasSkinTableImplementation", "c")
    alias_skin_table_asm = dump_flags("-AliasSkinTableImplementation", "asm")
    if alias_skin_table_c and alias_skin_table_asm:
        if alias_skin_table_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the default alias skin-table assembly selector changes the retained i486 release suffix")
        if alias_skin_table_c.get("profileSuffix") != RELEASE_I486_SUFFIX.replace(
            "-lightmapstylesasm", "-aliasskintablec-lightmapstylesasm"
        ):
            fail("the alias skin-table C selector does not add its reference profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_SKIN_TABLE" in alias_skin_table_c.get(flags_name, []):
                fail("the alias skin-table C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_SKIN_TABLE" not in alias_skin_table_asm.get(flags_name, []):
                fail("the alias skin-table assembly selector omits its macro from %s" % flags_name)

    alias_rasterize_c = dump_flags("-AliasRasterizeImplementation", "c")
    alias_rasterize_asm = dump_flags("-AliasRasterizeImplementation", "asm")
    if alias_rasterize_c and alias_rasterize_asm:
        if alias_rasterize_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the default alias rasterization assembly selector changes the retained i486 release suffix")
        if alias_rasterize_c.get("profileSuffix") != RELEASE_I486_SUFFIX.replace(
            "-lightmapstylesasm", "-aliasrasterizec-lightmapstylesasm"
        ):
            fail("the alias rasterization C selector does not add its reference profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_RASTERIZE" in alias_rasterize_c.get(flags_name, []):
                fail("the alias rasterization C selector enables assembly in %s" % flags_name)
            if "-DASM486_ALIAS_RASTERIZE" not in alias_rasterize_asm.get(flags_name, []):
                fail("the alias rasterization assembly selector omits its macro from %s" % flags_name)

    bmodel_polygon_clip_c = dump_flags("-BmodelPolygonClipImplementation", "c")
    bmodel_polygon_clip_asm = dump_flags("-BmodelPolygonClipImplementation", "asm")
    if bmodel_polygon_clip_c and bmodel_polygon_clip_asm:
        if bmodel_polygon_clip_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the brush-model polygon C selector changes the retained i486 profile suffix")
        if "bmodelclipasm" not in bmodel_polygon_clip_asm.get("profileSuffix", ""):
            fail("the brush-model polygon assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_BMODEL_POLYGON_CLIP" in bmodel_polygon_clip_c.get(flags_name, []):
                fail("the brush-model polygon C selector enables ASM486_BMODEL_POLYGON_CLIP in %s" % flags_name)
            if "-DASM486_BMODEL_POLYGON_CLIP" not in bmodel_polygon_clip_asm.get(flags_name, []):
                fail("the brush-model polygon assembly selector omits ASM486_BMODEL_POLYGON_CLIP from %s" % flags_name)

    solid_bmodel_polygons_c = dump_flags("-SolidClippedSubmodelPolygonsImplementation", "c")
    solid_bmodel_polygons_asm = dump_flags("-SolidClippedSubmodelPolygonsImplementation", "asm")
    if solid_bmodel_polygons_c and solid_bmodel_polygons_asm:
        if solid_bmodel_polygons_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the solid brush-model polygon C selector changes the retained i486 profile suffix")
        if "bmodelsetupasm" not in solid_bmodel_polygons_asm.get("profileSuffix", ""):
            fail("the solid brush-model polygon assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS" in solid_bmodel_polygons_c.get(flags_name, []):
                fail("the solid brush-model polygon C selector enables ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS in %s" % flags_name)
            if "-DASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS" not in solid_bmodel_polygons_asm.get(flags_name, []):
                fail("the solid brush-model polygon assembly selector omits ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS from %s" % flags_name)

    submodel_polygons_c = dump_flags("-SubmodelPolygonsImplementation", "c")
    submodel_polygons_asm = dump_flags("-SubmodelPolygonsImplementation", "asm")
    if submodel_polygons_c and submodel_polygons_asm:
        if submodel_polygons_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the submodel-polygons C selector changes the retained i486 profile suffix")
        if "submodelpolysasm" not in submodel_polygons_asm.get("profileSuffix", ""):
            fail("the submodel-polygons assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_DRAW_SUBMODEL_POLYGONS" in submodel_polygons_c.get(flags_name, []):
                fail("the submodel-polygons C selector enables ASM486_DRAW_SUBMODEL_POLYGONS in %s" % flags_name)
            if "-DASM486_DRAW_SUBMODEL_POLYGONS" not in submodel_polygons_asm.get(flags_name, []):
                fail("the submodel-polygons assembly selector omits ASM486_DRAW_SUBMODEL_POLYGONS from %s" % flags_name)

    z_submodel_polygons_c = dump_flags("-ZSubmodelPolygonsImplementation", "c")
    z_submodel_polygons_asm = dump_flags("-ZSubmodelPolygonsImplementation", "asm")
    if z_submodel_polygons_c and z_submodel_polygons_asm:
        if z_submodel_polygons_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the Z-submodel C selector changes the retained i486 profile suffix")
        if "zsubmodelpolysasm" not in z_submodel_polygons_asm.get("profileSuffix", ""):
            fail("the Z-submodel assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_DRAW_Z_SUBMODEL_POLYS" in z_submodel_polygons_c.get(flags_name, []):
                fail("the Z-submodel C selector enables ASM486_DRAW_Z_SUBMODEL_POLYS in %s" % flags_name)
            if "-DASM486_DRAW_Z_SUBMODEL_POLYS" not in z_submodel_polygons_asm.get(flags_name, []):
                fail("the Z-submodel assembly selector omits ASM486_DRAW_Z_SUBMODEL_POLYS from %s" % flags_name)

    frustum_transform_c = dump_flags("-TransformFrustumImplementation", "c")
    frustum_transform_asm = dump_flags("-TransformFrustumImplementation", "asm")
    if frustum_transform_c and frustum_transform_asm:
        if frustum_transform_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the frustum-transform C selector changes the retained i486 profile suffix")
        if "frustumasm" not in frustum_transform_asm.get("profileSuffix", ""):
            fail("the frustum-transform assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_TRANSFORM_FRUSTUM" in frustum_transform_c.get(flags_name, []):
                fail("the frustum-transform C selector enables ASM486_TRANSFORM_FRUSTUM in %s" % flags_name)
            if "-DASM486_TRANSFORM_FRUSTUM" not in frustum_transform_asm.get(flags_name, []):
                fail("the frustum-transform assembly selector omits ASM486_TRANSFORM_FRUSTUM from %s" % flags_name)

    edge_drawing_c = dump_flags("-EdgeDrawingImplementation", "c")
    edge_drawing_asm = dump_flags("-EdgeDrawingImplementation", "asm")
    if edge_drawing_c and edge_drawing_asm:
        if edge_drawing_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the edge-drawing C selector changes the retained i486 profile suffix")
        if "edgedrawasm" not in edge_drawing_asm.get("profileSuffix", ""):
            fail("the edge-drawing assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_EDGE_DRAWING" in edge_drawing_c.get(flags_name, []):
                fail("the edge-drawing C selector enables ASM486_EDGE_DRAWING in %s" % flags_name)
            if "-DASM486_EDGE_DRAWING" not in edge_drawing_asm.get(flags_name, []):
                fail("the edge-drawing assembly selector omits ASM486_EDGE_DRAWING from %s" % flags_name)

    scan_edges_c = dump_flags("-ScanEdgesImplementation", "c")
    scan_edges_asm = dump_flags("-ScanEdgesImplementation", "asm")
    if scan_edges_c and scan_edges_asm:
        if scan_edges_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the edge-scan C selector changes the retained i486 profile suffix")
        if "scanedgesasm" not in scan_edges_asm.get("profileSuffix", ""):
            fail("the edge-scan assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_SCAN_EDGES" in scan_edges_c.get(flags_name, []):
                fail("the edge-scan C selector enables ASM486_SCAN_EDGES in %s" % flags_name)
            if "-DASM486_SCAN_EDGES" not in scan_edges_asm.get(flags_name, []):
                fail("the edge-scan assembly selector omits ASM486_SCAN_EDGES from %s" % flags_name)

    edge_list_legacy = dump_flags("-EdgeListMaintenanceImplementation", "legacy")
    edge_list_c = dump_flags("-EdgeListMaintenanceImplementation", "c")
    edge_list_asm = dump_flags("-EdgeListMaintenanceImplementation", "asm")
    if edge_list_legacy and edge_list_c and edge_list_asm:
        if edge_list_legacy.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the edge-list legacy default changes the retained i486 profile suffix")
        if "edgelistc" not in edge_list_c.get("profileSuffix", ""):
            fail("the edge-list C selector does not add its profile token")
        if "edgelistasm" not in edge_list_asm.get("profileSuffix", ""):
            fail("the edge-list assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_EDGE_LIST_C" in edge_list_legacy.get(flags_name, []):
                fail("the edge-list legacy default enables ASM486_EDGE_LIST_C in %s" % flags_name)
            if "-DASM486_EDGE_LIST" in edge_list_legacy.get(flags_name, []):
                fail("the edge-list legacy default enables ASM486_EDGE_LIST in %s" % flags_name)
            if "-DASM486_EDGE_LIST_C" not in edge_list_c.get(flags_name, []):
                fail("the edge-list C selector omits ASM486_EDGE_LIST_C from %s" % flags_name)
            if "-DASM486_EDGE_LIST" in edge_list_c.get(flags_name, []):
                fail("the edge-list C selector enables ASM486_EDGE_LIST in %s" % flags_name)
            if "-DASM486_EDGE_LIST_C" in edge_list_asm.get(flags_name, []):
                fail("the edge-list assembly selector enables ASM486_EDGE_LIST_C in %s" % flags_name)
            if "-DASM486_EDGE_LIST" not in edge_list_asm.get(flags_name, []):
                fail("the edge-list assembly selector omits ASM486_EDGE_LIST from %s" % flags_name)

    backward_spans_c = dump_flags("-BackwardSpansImplementation", "c")
    backward_spans_asm = dump_flags("-BackwardSpansImplementation", "asm")
    if backward_spans_c and backward_spans_asm:
        if backward_spans_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the backward-span C selector changes the retained i486 profile suffix")
        if "backspansasm" not in backward_spans_asm.get("profileSuffix", ""):
            fail("the backward-span assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_BACKWARD_SPANS" in backward_spans_c.get(flags_name, []):
                fail("the backward-span C selector enables ASM486_BACKWARD_SPANS in %s" % flags_name)
            if "-DASM486_BACKWARD_SPANS" not in backward_spans_asm.get(flags_name, []):
                fail("the backward-span assembly selector omits ASM486_BACKWARD_SPANS from %s" % flags_name)

    efrag_store_c = dump_flags("-EfragStoreImplementation", "c")
    efrag_store_asm = dump_flags("-EfragStoreImplementation", "asm")
    if efrag_store_c and efrag_store_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-efragstoreasm", "", 1)
        if efrag_store_c.get("profileSuffix") != c_reference_suffix:
            fail("the efrag-store C selector does not isolate the C reference profile")
        if efrag_store_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the efrag-store assembly selector does not match the i486 release profile")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_EFRAG_STORE" in efrag_store_c.get(flags_name, []):
                fail("the efrag-store C selector enables ASM486_EFRAG_STORE in %s" % flags_name)
            if "-DASM486_EFRAG_STORE" not in efrag_store_asm.get(flags_name, []):
                fail("the efrag-store assembly selector omits ASM486_EFRAG_STORE from %s" % flags_name)

    emit_cached_edge_c = dump_flags("-EmitCachedEdgeImplementation", "c")
    emit_cached_edge_asm = dump_flags("-EmitCachedEdgeImplementation", "asm")
    if emit_cached_edge_c and emit_cached_edge_asm:
        if emit_cached_edge_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the cached-edge C selector changes the retained i486 profile suffix")
        if "emitcachedasm" not in emit_cached_edge_asm.get("profileSuffix", ""):
            fail("the cached-edge assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_EMIT_CACHED_EDGE" in emit_cached_edge_c.get(flags_name, []):
                fail("the cached-edge C selector enables ASM486_EMIT_CACHED_EDGE in %s" % flags_name)
            if "-DASM486_EMIT_CACHED_EDGE" not in emit_cached_edge_asm.get(flags_name, []):
                fail("the cached-edge assembly selector omits ASM486_EMIT_CACHED_EDGE from %s" % flags_name)

    render_poly_c = dump_flags("-RenderPolyImplementation", "c")
    render_poly_asm = dump_flags("-RenderPolyImplementation", "asm")
    if render_poly_c and render_poly_asm:
        if render_poly_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the render-poly C selector changes the retained i486 profile suffix")
        if "renderpolyasm" not in render_poly_asm.get("profileSuffix", ""):
            fail("the render-poly assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_RENDER_POLY" in render_poly_c.get(flags_name, []):
                fail("the render-poly C selector enables ASM486_RENDER_POLY in %s" % flags_name)
            if "-DASM486_RENDER_POLY" not in render_poly_asm.get(flags_name, []):
                fail("the render-poly assembly selector omits ASM486_RENDER_POLY from %s" % flags_name)

    long_renderer_profile = dump_flags(
        "-Benchmark",
        "-BspWalkImplementation", "asm",
        "-RenderWorldImplementation", "asm",
        "-RenderFaceImplementation", "asm",
        "-RenderBmodelFaceImplementation", "asm",
        "-BmodelPolygonClipImplementation", "asm",
        "-SolidClippedSubmodelPolygonsImplementation", "asm",
        "-SubmodelPolygonsImplementation", "asm",
        "-EdgeDrawingImplementation", "asm",
        "-ScanEdgesImplementation", "asm",
        "-EdgeListMaintenanceImplementation", "asm",
        "-BackwardSpansImplementation", "asm",
        "-EfragStoreImplementation", "asm",
        "-EmitCachedEdgeImplementation", "asm",
        "-RenderPolyImplementation", "asm",
    )
    if long_renderer_profile:
        object_root = str(long_renderer_profile.get("objectRoot", ""))
        object_root = object_root.replace("<repo>", REPO_ROOT)
        object_path = os.path.join(object_root, "asm486_experiments.obj")
        if "renderpolyasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the render-poly selector token")
        if "renderworldasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the render-world selector token")
        if "submodelpolysasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the submodel-polygons selector token")
        if "bmodelclipasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the brush-model polygon selector token")
        if "bmodelsetupasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the solid brush-model polygon selector token")
        if "scanedgesasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the edge-scan selector token")
        if "edgelistasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the edge-list selector token")
        if "backspansasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the backward-span selector token")
        if "emitcachedasm" not in long_renderer_profile.get("profileSuffix", ""):
            fail("the long renderer profile suffix omits the cached-edge selector token")
        if len(object_path) > 259:
            fail("the long renderer profile object path exceeds the legacy Windows MAX_PATH boundary")
        unhashed_object_root = os.path.join(
            str(long_renderer_profile.get("outputRoot", "")).replace("<repo>", REPO_ROOT),
            "obj-bench",
        )
        unhashed_object_path = os.path.join(unhashed_object_root, "asm486_experiments.obj")
        if len(unhashed_object_path) > 259:
            if os.path.normcase(os.path.dirname(object_root)) != os.path.normcase(
                os.path.join(REPO_ROOT, "out")
            ):
                fail("the long renderer profile did not move its object cache to the short out sibling")
        elif os.path.normcase(object_root) != os.path.normcase(unhashed_object_root):
            fail("the renderer profile changed its object cache path before reaching the MAX_PATH boundary")

    long_executable_profile = dump_flags(
        "-Benchmark",
        "-BspWalkImplementation", "asm",
        "-RenderFaceImplementation", "asm",
        "-RenderBmodelFaceImplementation", "asm",
        "-BmodelPolygonClipImplementation", "asm",
        "-SolidClippedSubmodelPolygonsImplementation", "asm",
        "-SubmodelPolygonsImplementation", "asm",
        "-ZSubmodelPolygonsImplementation", "asm",
        "-EfragStoreImplementation", "asm",
        "-EmitCachedEdgeImplementation", "asm",
        "-RenderPolyImplementation", "asm",
        "-SurfaceDispatcherImplementation", "asm",
    )
    if long_executable_profile:
        output_root = str(long_executable_profile.get("outputRoot", "")).replace(
            "<repo>", REPO_ROOT
        )
        executable = str(long_executable_profile.get("executable", "")).replace(
            "<repo>", REPO_ROOT
        )
        link_map = os.path.join(output_root, os.path.basename(executable) + ".map")
        if len(executable) > 259:
            fail("the long renderer profile executable path exceeds the legacy Windows MAX_PATH boundary")
        if not os.path.basename(output_root).startswith("profile-"):
            fail("the long executable profile did not use the hashed short output directory")
        if len(link_map) > 259 or os.path.dirname(link_map) != output_root:
            fail("the long executable profile linker map is not under the hashed short output directory")

    instrumented_cache_draw = dump_flags(
        "-Benchmark", "-Instrumentation",
        "-SurfaceCacheImplementation", "asm",
        "-SurfaceDrawImplementation", "asm",
    )
    if instrumented_cache_draw:
        if instrumented_cache_draw.get("manifest") != "build-manifest-profile.json":
            fail("the instrumented build must own a separate manifest")
        if not str(instrumented_cache_draw.get("executable", "")).endswith(
            "\\qprof.exe"
        ):
            fail("the instrumented cache/draw selector does not resolve qprof.exe")
        object_root = str(instrumented_cache_draw.get("objectRoot", ""))
        if not object_root.endswith(("\\obj-bp", "-obj-bp")):
            fail("the instrumented benchmark does not use the compact obj-bp directory")
    if benchmark and benchmark.get("manifest") != "build-manifest-bench.json":
        fail("the benchmark build did not retain its own manifest")
    if i486 and i486.get("manifest") != "build-manifest.json":
        fail("the release build did not retain its own manifest")

    dlight_orchestration_c = dump_flags(
        "-DynamicLightOrchestrationImplementation", "c"
    )
    dlight_orchestration_asm = dump_flags(
        "-DynamicLightOrchestrationImplementation", "asm"
    )
    if dlight_orchestration_c and dlight_orchestration_asm:
        if dlight_orchestration_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the dynamic-light orchestration C selector changes the retained i486 profile suffix")
        if "dlightorchestrationasm" not in dlight_orchestration_asm.get("profileSuffix", ""):
            fail("the dynamic-light orchestration assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            for macro in ("ASM486_DYNAMIC_LIGHT_ORCHESTRATION", "ASM486_DYNAMIC_LIGHT_PROJECTION"):
                if "-D" + macro in dlight_orchestration_c.get(flags_name, []):
                    fail("the dynamic-light orchestration C selector enables %s in %s" % (macro, flags_name))
                if "-D" + macro not in dlight_orchestration_asm.get(flags_name, []):
                    fail("the dynamic-light orchestration assembly selector omits %s from %s" % (macro, flags_name))

    dlight_contributes_c = dump_flags("-DlightContributesImplementation", "c")
    dlight_contributes_asm = dump_flags("-DlightContributesImplementation", "asm")
    if dlight_contributes_c and dlight_contributes_asm:
        if dlight_contributes_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the dynamic-light predicate C selector changes the retained i486 profile suffix")
        if "dlightcontribasm" not in dlight_contributes_asm.get("profileSuffix", ""):
            fail("the dynamic-light predicate assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            for macro in ("ASM486_DLIGHT_CONTRIBUTES", "ASM486_DYNAMIC_LIGHT_PROJECTION"):
                if "-D" + macro in dlight_contributes_c.get(flags_name, []):
                    fail("the dynamic-light predicate C selector enables %s in %s" % (macro, flags_name))
                if "-D" + macro not in dlight_contributes_asm.get(flags_name, []):
                    fail("the dynamic-light predicate assembly selector omits %s from %s" % (macro, flags_name))

    mark_lights_c = dump_flags("-MarkLightsImplementation", "c")
    mark_lights_asm = dump_flags("-MarkLightsImplementation", "asm")
    mark_lights_only = dump_flags(
        "-MarkLightsImplementation", "asm",
        "-LightMapBuildImplementation", "c",
    )
    if mark_lights_c and mark_lights_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-marklightsasm", "")
        if mark_lights_c.get("profileSuffix") != c_reference_suffix:
            fail("the MarkLights C selector does not restore the C-reference profile suffix")
        if "marklightsasm" not in mark_lights_asm.get("profileSuffix", ""):
            fail("the MarkLights assembly selector does not add its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_MARK_LIGHTS" in mark_lights_c.get(flags_name, []):
                fail("the MarkLights C selector enables ASM486_MARK_LIGHTS in %s" % flags_name)
            if "-DASM486_MARK_LIGHTS" not in mark_lights_asm.get(flags_name, []):
                fail("the MarkLights assembly selector omits ASM486_MARK_LIGHTS from %s" % flags_name)
    if mark_lights_only:
        if "marklightsasm" not in mark_lights_only.get("profileSuffix", ""):
            fail("MarkLights assembly with the C lightmap dispatcher lacks its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_MARK_LIGHTS" not in mark_lights_only.get(flags_name, []):
                fail("MarkLights-only assembly omits ASM486_MARK_LIGHTS from %s" % flags_name)
            if "-DASM486_LIGHTMAP_BUILD" in mark_lights_only.get(flags_name, []):
                fail("MarkLights-only assembly unexpectedly enables ASM486_LIGHTMAP_BUILD in %s" % flags_name)

    dlight_push_c = dump_flags("-DynamicLightPushImplementation", "c")
    dlight_push_asm = dump_flags("-DynamicLightPushImplementation", "asm")
    if dlight_push_c and dlight_push_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-dlightpushasm", "")
        if dlight_push_c.get("profileSuffix") != c_reference_suffix:
            fail("the R_PushDlights C selector does not restore the C-reference suffix")
        if dlight_push_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_PushDlights assembly selector changes the promoted i486 suffix")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_DYNAMIC_LIGHT_PUSH" in dlight_push_c.get(flags_name, []):
                fail("the R_PushDlights C selector enables ASM486_DYNAMIC_LIGHT_PUSH in %s" % flags_name)
            if "-DASM486_DYNAMIC_LIGHT_PUSH" not in dlight_push_asm.get(flags_name, []):
                fail("the R_PushDlights assembly selector omits ASM486_DYNAMIC_LIGHT_PUSH from %s" % flags_name)

    line_graph_c = dump_flags("-LineGraphImplementation", "c")
    line_graph_asm = dump_flags("-LineGraphImplementation", "asm")
    if line_graph_c and line_graph_asm:
        if line_graph_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_LineGraph C selector changes the promoted i486 suffix")
        if "linegraphasm" not in line_graph_asm.get("profileSuffix", ""):
            fail("the R_LineGraph assembly selector lacks its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_LINE_GRAPH" in line_graph_c.get(flags_name, []):
                fail("the R_LineGraph C selector enables ASM486_LINE_GRAPH in %s" % flags_name)
            if "-DASM486_LINE_GRAPH" not in line_graph_asm.get(flags_name, []):
                fail("the R_LineGraph assembly selector omits ASM486_LINE_GRAPH from %s" % flags_name)
        for dump_name, dump in (("C", line_graph_c), ("assembly", line_graph_asm)):
            if "r_linegraphasm.s" not in dump.get("assemblySources", []):
                fail("the R_LineGraph %s selector omits r_linegraphasm.s from the source inventory" % dump_name)

    time_graph_c = dump_flags("-TimeGraphImplementation", "c")
    time_graph_asm = dump_flags("-TimeGraphImplementation", "asm")
    if time_graph_c and time_graph_asm:
        if time_graph_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_TimeGraph C selector changes the promoted i486 suffix")
        if "timegraphasm" not in time_graph_asm.get("profileSuffix", ""):
            fail("the R_TimeGraph assembly selector lacks its profile token")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_TIME_GRAPH" in time_graph_c.get(flags_name, []):
                fail("the R_TimeGraph C selector enables ASM486_TIME_GRAPH in %s" % flags_name)
            if "-DASM486_TIME_GRAPH" not in time_graph_asm.get(flags_name, []):
                fail("the R_TimeGraph assembly selector omits ASM486_TIME_GRAPH from %s" % flags_name)
        for dump_name, dump in (("C", time_graph_c), ("assembly", time_graph_asm)):
            if "r_timegraphasm.s" not in dump.get("assemblySources", []):
                fail("the R_TimeGraph %s selector omits r_timegraphasm.s from the source inventory" % dump_name)

    alias_stats_c = dump_flags("-AliasStatsImplementation", "c")
    alias_stats_asm = dump_flags("-AliasStatsImplementation", "asm")
    if alias_stats_c and alias_stats_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-aliasstatsasm", "")
        if alias_stats_c.get("profileSuffix") != c_reference_suffix:
            fail("the R_PrintAliasStats C selector changes the promoted i486 suffix")
        asm_suffix = alias_stats_asm.get("profileSuffix", "")
        if asm_suffix.count("-aliasstatsasm") != 1:
            fail("the R_PrintAliasStats assembly selector lacks its profile token")
        elif asm_suffix.replace("-aliasstatsasm", "") != alias_stats_c.get("profileSuffix"):
            fail("the R_PrintAliasStats assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ALIAS_STATS" in alias_stats_c.get(flags_name, []):
                fail("the R_PrintAliasStats C selector enables ASM486_ALIAS_STATS in %s" % flags_name)
            if "-DASM486_ALIAS_STATS" not in alias_stats_asm.get(flags_name, []):
                fail("the R_PrintAliasStats assembly selector omits ASM486_ALIAS_STATS from %s" % flags_name)
        for macro in ("-DASM486_DYNAMIC_LIGHT_PUSH", "-DASM486_MARK_LIGHTS"):
            for flags_name in ("cFlags", "asmFlags"):
                if macro not in alias_stats_c.get(flags_name, []):
                    fail("the promoted default %s is missing from AliasStats C %s" % (macro, flags_name))
                if macro not in alias_stats_asm.get(flags_name, []):
                    fail("the AliasStats selector drops promoted default %s from %s" % (macro, flags_name))
        for dump_name, dump in (("C", alias_stats_c), ("assembly", alias_stats_asm)):
            if "r_aliasstatsasm.s" not in dump.get("assemblySources", []):
                fail("the R_PrintAliasStats %s selector omits r_aliasstatsasm.s from the source inventory" % dump_name)

    print_times_c = dump_flags("-PrintTimesImplementation", "c")
    print_times_asm = dump_flags("-PrintTimesImplementation", "asm")
    if print_times_c and print_times_asm:
        if print_times_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_PrintTimes C selector changes the promoted i486 suffix")
        asm_suffix = print_times_asm.get("profileSuffix", "")
        if asm_suffix.count("-printtimesasm") != 1:
            fail("the R_PrintTimes assembly selector lacks its profile token")
        elif asm_suffix.replace("-printtimesasm", "") != print_times_c.get("profileSuffix"):
            fail("the R_PrintTimes assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_PRINT_TIMES" in print_times_c.get(flags_name, []):
                fail("the R_PrintTimes C selector enables ASM486_PRINT_TIMES in %s" % flags_name)
            if "-DASM486_PRINT_TIMES" not in print_times_asm.get(flags_name, []):
                fail("the R_PrintTimes assembly selector omits ASM486_PRINT_TIMES from %s" % flags_name)
        for dump_name, dump in (("C", print_times_c), ("assembly", print_times_asm)):
            if "r_printtimesasm.s" not in dump.get("assemblySources", []):
                fail("the R_PrintTimes %s selector omits r_printtimesasm.s from the source inventory" % dump_name)

    particle_draw_c = dump_flags("-ParticleDrawImplementation", "c")
    particle_draw_asm = dump_flags("-ParticleDrawImplementation", "asm")
    if particle_draw_c and particle_draw_asm:
        if particle_draw_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the D_DrawParticle assembly default changes the promoted i486 suffix")
        c_suffix = particle_draw_c.get("profileSuffix", "")
        if c_suffix.count("-particledrawc") != 1:
            fail("the D_DrawParticle C oracle lacks its isolated profile token")
        elif c_suffix.replace("-particledrawc", "") != particle_draw_asm.get("profileSuffix"):
            fail("the D_DrawParticle C oracle changes unrelated promoted suffix tokens")
        if particle_draw_c.get("outputRoot") == particle_draw_asm.get("outputRoot"):
            fail("the D_DrawParticle C oracle shares the assembly output root")
        for flags_name in ("cFlags", "asmFlags"):
            c_flags = particle_draw_c.get(flags_name, [])
            asm_flags = particle_draw_asm.get(flags_name, [])
            if "-DASM486_PARTICLE_DRAW_C" not in c_flags:
                fail("the D_DrawParticle C selector omits ASM486_PARTICLE_DRAW_C from %s" % flags_name)
            if "-DASM486_PARTICLE_DRAW" in c_flags:
                fail("the D_DrawParticle C selector enables ASM486_PARTICLE_DRAW in %s" % flags_name)
            if "-DASM486_PARTICLE_DRAW" not in asm_flags:
                fail("the D_DrawParticle assembly selector omits ASM486_PARTICLE_DRAW from %s" % flags_name)
            if "-DASM486_PARTICLE_DRAW_C" in asm_flags:
                fail("the D_DrawParticle assembly selector enables ASM486_PARTICLE_DRAW_C in %s" % flags_name)
        if "d_parta.s" not in particle_draw_c.get("assemblySources", []):
            fail("the D_DrawParticle C oracle omits d_parta.s from the assembly source inventory")
        if "d_parta.s" not in particle_draw_asm.get("assemblySources", []):
            fail("the D_DrawParticle assembly path omits d_parta.s from the assembly source inventory")

    focused_particle_profiles = {}
    for value in ("c", "asm"):
        profile_path = os.path.join(
            REPO_ROOT, "tools", "renderer-profiles", "i486-particledraw-%s.json" % value
        )
        if not os.path.isfile(profile_path):
            fail("missing focused D_DrawParticle %s profile %s" % (value, profile_path))
            continue
        try:
            with open(profile_path, "r", encoding="utf-8") as handle:
                focused_particle_profiles[value] = json.load(handle)
        except (OSError, json.JSONDecodeError) as error:
            fail("could not read focused D_DrawParticle %s profile: %s" % (value, error))

    if len(focused_particle_profiles) == 2:
        particle_c_profile = focused_particle_profiles["c"]
        particle_asm_profile = focused_particle_profiles["asm"]
        c_selectors = particle_c_profile.get("selectors", {})
        asm_selectors = particle_asm_profile.get("selectors", {})
        if particle_c_profile.get("id") != "i486-particledraw-c":
            fail("the focused D_DrawParticle C profile has an unexpected id")
        if particle_asm_profile.get("id") != "i486-particledraw-asm":
            fail("the focused D_DrawParticle assembly profile has an unexpected id")
        if c_selectors.get("ParticleDrawImplementation") != "c":
            fail("the focused D_DrawParticle C profile does not select the C oracle")
        if asm_selectors.get("ParticleDrawImplementation") != "asm":
            fail("the focused D_DrawParticle assembly profile does not select assembly")
        selector_differences = {
            key for key in set(c_selectors) | set(asm_selectors)
            if c_selectors.get(key) != asm_selectors.get(key)
        }
        if selector_differences != {"ParticleDrawImplementation"}:
            fail(
                "focused D_DrawParticle profiles differ in selectors %r; expected only ParticleDrawImplementation"
                % sorted(selector_differences)
            )
        c_reference_path = os.path.join(
            REPO_ROOT, "tools", "renderer-profiles", "i486-c-reference.json"
        )
        try:
            with open(c_reference_path, "r", encoding="utf-8") as handle:
                c_reference_selectors = json.load(handle).get("selectors", {})
            if c_selectors != c_reference_selectors:
                fail("the focused D_DrawParticle C profile has drifted from the shared C-reference selectors")
        except (OSError, json.JSONDecodeError) as error:
            fail("could not read the shared C-reference selector profile: %s" % error)
        for profile in (particle_c_profile, particle_asm_profile):
            if "render-scenarios-runparticleeffect.json" not in profile.get("description", ""):
                fail("a focused D_DrawParticle profile does not name its exact event scenario")

    particle_scenario_path = os.path.join(REPO_ROOT, "tools", "render-scenarios-runparticleeffect.json")
    if not os.path.isfile(particle_scenario_path):
        fail("the exact R_RunParticleEffect event scenario manifest is missing")
    else:
        try:
            with open(particle_scenario_path, "r", encoding="utf-8") as handle:
                particle_scenario_manifest = json.load(handle)
            particle_scenarios = particle_scenario_manifest.get("scenarios", [])
            if len(particle_scenarios) != 1:
                fail("the R_RunParticleEffect event scenario manifest must contain exactly one scenario")
            else:
                scene = particle_scenarios[0]
                exact_tolerance = {"channel": 0, "maxChangedPixelFraction": 0, "maxMeanAbsoluteError": 0}
                if scene.get("id") != "demo2-wizspike-event":
                    fail("the D_DrawParticle parity scenario is not the known demo2 particle event")
                if "R_RunParticleEffect" not in scene.get("description", ""):
                    fail("the D_DrawParticle parity scenario does not route its event through R_RunParticleEffect")
                if scene.get("requiredBenchEvents") != ["runParticleEffect"]:
                    fail("the D_DrawParticle parity scenario does not require the R_RunParticleEffect event")
                if scene.get("expectedBenchEventFrames") != {"runParticleEffect": [10]}:
                    fail("the D_DrawParticle parity scenario does not pin its particle event to frame 10")
                if scene.get("expectedFrames") != 10 or scene.get("captureFrame") != 10:
                    fail("the D_DrawParticle parity scenario no longer captures the exact 10-frame event")
                if scene.get("tolerance") != exact_tolerance:
                    fail("the D_DrawParticle event scenario is no longer an exact pixel comparison")
        except (OSError, json.JSONDecodeError) as error:
            fail("could not read the D_DrawParticle event scenario manifest: %s" % error)

    parity_source_path = os.path.join(REPO_ROOT, "tools", "render-parity-dos.ps1")
    try:
        with open(parity_source_path, "r", encoding="utf-8") as handle:
            parity_source = handle.read()
        if "[string]$ScenarioFile" not in parity_source or "'-ScenarioFile', $pairScenarioFile" not in parity_source:
            fail("the paired render harness does not accept and forward the exact event scenario file")
    except OSError as error:
        fail("could not read the paired render harness source: %s" % error)

    particle_explosion2_c = dump_flags("-ParticleExplosion2Implementation", "c")
    particle_explosion2_asm = dump_flags("-ParticleExplosion2Implementation", "asm")
    if particle_explosion2_c and particle_explosion2_asm:
        if particle_explosion2_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_ParticleExplosion2 C selector changes the promoted i486 suffix")
        asm_suffix = particle_explosion2_asm.get("profileSuffix", "")
        if asm_suffix.count("-particleexplosion2asm") != 1:
            fail("the R_ParticleExplosion2 assembly selector lacks its profile token")
        elif asm_suffix.replace("-particleexplosion2asm", "") != particle_explosion2_c.get("profileSuffix"):
            fail("the R_ParticleExplosion2 assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_PARTICLE_EXPLOSION2" in particle_explosion2_c.get(flags_name, []):
                fail("the R_ParticleExplosion2 C selector enables ASM486_PARTICLE_EXPLOSION2 in %s" % flags_name)
            if "-DASM486_PARTICLE_EXPLOSION2" not in particle_explosion2_asm.get(flags_name, []):
                fail("the R_ParticleExplosion2 assembly selector omits ASM486_PARTICLE_EXPLOSION2 from %s" % flags_name)
        for dump_name, dump in (("C", particle_explosion2_c), ("assembly", particle_explosion2_asm)):
            if "r_particleexplosion2asm.s" not in dump.get("assemblySources", []):
                fail("the R_ParticleExplosion2 %s selector omits r_particleexplosion2asm.s from the source inventory" % dump_name)

    rocket_trail_c = dump_flags("-RocketTrailImplementation", "c")
    rocket_trail_asm = dump_flags("-RocketTrailImplementation", "asm")
    if rocket_trail_c and rocket_trail_asm:
        if rocket_trail_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_RocketTrail C selector changes the promoted i486 suffix")
        asm_suffix = rocket_trail_asm.get("profileSuffix", "")
        if asm_suffix.count("-rockettrailasm") != 1:
            fail("the R_RocketTrail assembly selector lacks its profile token")
        elif asm_suffix.replace("-rockettrailasm", "") != rocket_trail_c.get("profileSuffix"):
            fail("the R_RocketTrail assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ROCKET_TRAIL" in rocket_trail_c.get(flags_name, []):
                fail("the R_RocketTrail C selector enables ASM486_ROCKET_TRAIL in %s" % flags_name)
            if "-DASM486_ROCKET_TRAIL" not in rocket_trail_asm.get(flags_name, []):
                fail("the R_RocketTrail assembly selector omits ASM486_ROCKET_TRAIL from %s" % flags_name)
        for dump_name, dump in (("C", rocket_trail_c), ("assembly", rocket_trail_asm)):
            if "r_rockettrailasm.s" not in dump.get("assemblySources", []):
                fail("the R_RocketTrail %s selector omits r_rockettrailasm.s from the source inventory" % dump_name)

    particle_explosion_c = dump_flags("-ParticleExplosionImplementation", "c")
    particle_explosion_asm = dump_flags("-ParticleExplosionImplementation", "asm")
    if particle_explosion_c and particle_explosion_asm:
        if particle_explosion_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_ParticleExplosion C selector changes the promoted i486 suffix")
        asm_suffix = particle_explosion_asm.get("profileSuffix", "")
        if asm_suffix.count("-particleexplosionasm") != 1:
            fail("the R_ParticleExplosion assembly selector lacks its profile token")
        elif asm_suffix.replace("-particleexplosionasm", "") != particle_explosion_c.get("profileSuffix"):
            fail("the R_ParticleExplosion assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_PARTICLE_EXPLOSION" in particle_explosion_c.get(flags_name, []):
                fail("the R_ParticleExplosion C selector enables ASM486_PARTICLE_EXPLOSION in %s" % flags_name)
            if "-DASM486_PARTICLE_EXPLOSION" not in particle_explosion_asm.get(flags_name, []):
                fail("the R_ParticleExplosion assembly selector omits ASM486_PARTICLE_EXPLOSION from %s" % flags_name)
        for dump_name, dump in (("C", particle_explosion_c), ("assembly", particle_explosion_asm)):
            if "r_particleexplosionasm.s" not in dump.get("assemblySources", []):
                fail("the R_ParticleExplosion %s selector omits r_particleexplosionasm.s from the source inventory" % dump_name)

    run_particle_effect_c = dump_flags("-RunParticleEffectImplementation", "c")
    run_particle_effect_asm = dump_flags("-RunParticleEffectImplementation", "asm")
    if run_particle_effect_c and run_particle_effect_asm:
        if run_particle_effect_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_RunParticleEffect C selector changes the promoted i486 suffix")
        asm_suffix = run_particle_effect_asm.get("profileSuffix", "")
        if asm_suffix.count("-runparticleeffectasm") != 1:
            fail("the R_RunParticleEffect assembly selector lacks its profile token")
        elif asm_suffix.replace("-runparticleeffectasm", "") != run_particle_effect_c.get("profileSuffix"):
            fail("the R_RunParticleEffect assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_RUN_PARTICLE_EFFECT" in run_particle_effect_c.get(flags_name, []):
                fail("the R_RunParticleEffect C selector enables ASM486_RUN_PARTICLE_EFFECT in %s" % flags_name)
            if "-DASM486_RUN_PARTICLE_EFFECT" not in run_particle_effect_asm.get(flags_name, []):
                fail("the R_RunParticleEffect assembly selector omits ASM486_RUN_PARTICLE_EFFECT from %s" % flags_name)
        for dump_name, dump in (("C", run_particle_effect_c), ("assembly", run_particle_effect_asm)):
            if "r_runparticleeffectasm.s" not in dump.get("assemblySources", []):
                fail("the R_RunParticleEffect %s selector omits r_runparticleeffectasm.s from the source inventory" % dump_name)

    parse_particle_effect_c = dump_flags("-ParseParticleEffectImplementation", "c")
    parse_particle_effect_asm = dump_flags("-ParseParticleEffectImplementation", "asm")
    if parse_particle_effect_c and parse_particle_effect_asm:
        if parse_particle_effect_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_ParseParticleEffect C selector changes the promoted i486 suffix")
        asm_suffix = parse_particle_effect_asm.get("profileSuffix", "")
        if asm_suffix.count("-parseparticleeffectasm") != 1:
            fail("the R_ParseParticleEffect assembly selector lacks its profile token")
        elif asm_suffix.replace("-parseparticleeffectasm", "") != parse_particle_effect_c.get("profileSuffix"):
            fail("the R_ParseParticleEffect assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_PARSE_PARTICLE_EFFECT" in parse_particle_effect_c.get(flags_name, []):
                fail("the R_ParseParticleEffect C selector enables ASM486_PARSE_PARTICLE_EFFECT in %s" % flags_name)
            if "-DASM486_PARSE_PARTICLE_EFFECT" not in parse_particle_effect_asm.get(flags_name, []):
                fail("the R_ParseParticleEffect assembly selector omits ASM486_PARSE_PARTICLE_EFFECT from %s" % flags_name)
            for dump_name, dump in (("C", parse_particle_effect_c), ("assembly", parse_particle_effect_asm)):
                if "-DASM486_RUN_PARTICLE_EFFECT" in dump.get(flags_name, []):
                    fail("the R_ParseParticleEffect %s selector unexpectedly enables the separate R_RunParticleEffect assembly implementation in %s" % (dump_name, flags_name))
        for dump_name, dump in (("C", parse_particle_effect_c), ("assembly", parse_particle_effect_asm)):
            if "r_parseparticleeffectasm.s" not in dump.get("assemblySources", []):
                fail("the R_ParseParticleEffect %s selector omits r_parseparticleeffectasm.s from the source inventory" % dump_name)

    entity_particles_c = dump_flags("-EntityParticlesImplementation", "c")
    entity_particles_asm = dump_flags("-EntityParticlesImplementation", "asm")
    if entity_particles_c and entity_particles_asm:
        if entity_particles_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_EntityParticles C selector changes the promoted i486 suffix")
        asm_suffix = entity_particles_asm.get("profileSuffix", "")
        if asm_suffix.count("-entityparticlesasm") != 1:
            fail("the R_EntityParticles assembly selector lacks its profile token")
        elif asm_suffix.replace("-entityparticlesasm", "") != entity_particles_c.get("profileSuffix"):
            fail("the R_EntityParticles assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_ENTITY_PARTICLES" in entity_particles_c.get(flags_name, []):
                fail("the R_EntityParticles C selector enables ASM486_ENTITY_PARTICLES in %s" % flags_name)
            if "-DASM486_ENTITY_PARTICLES" not in entity_particles_asm.get(flags_name, []):
                fail("the R_EntityParticles assembly selector omits ASM486_ENTITY_PARTICLES from %s" % flags_name)
        for dump_name, dump in (("C", entity_particles_c), ("assembly", entity_particles_asm)):
            if "r_entityparticlesasm.s" not in dump.get("assemblySources", []):
                fail("the R_EntityParticles %s selector omits r_entityparticlesasm.s from the source inventory" % dump_name)

    blob_explosion_c = dump_flags("-BlobExplosionImplementation", "c")
    blob_explosion_asm = dump_flags("-BlobExplosionImplementation", "asm")
    if blob_explosion_c and blob_explosion_asm:
        c_reference_suffix = RELEASE_I486_SUFFIX.replace("-blobexplosionasm", "", 1)
        if blob_explosion_c.get("profileSuffix") != c_reference_suffix:
            fail("the R_BlobExplosion C selector does not isolate the C reference profile")
        if blob_explosion_asm.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_BlobExplosion assembly selector does not match the i486 release profile")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_BLOB_EXPLOSION" in blob_explosion_c.get(flags_name, []):
                fail("the R_BlobExplosion C selector enables ASM486_BLOB_EXPLOSION in %s" % flags_name)
            if "-DASM486_BLOB_EXPLOSION" not in blob_explosion_asm.get(flags_name, []):
                fail("the R_BlobExplosion assembly selector omits ASM486_BLOB_EXPLOSION from %s" % flags_name)
        for dump_name, dump in (("C", blob_explosion_c), ("assembly", blob_explosion_asm)):
            if "r_blobexplosionasm.s" not in dump.get("assemblySources", []):
                fail("the R_BlobExplosion %s selector omits r_blobexplosionasm.s from the source inventory" % dump_name)

    lava_splash_c = dump_flags("-LavaSplashImplementation", "c")
    lava_splash_asm = dump_flags("-LavaSplashImplementation", "asm")
    if lava_splash_c and lava_splash_asm:
        if lava_splash_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_LavaSplash C selector changes the promoted i486 suffix")
        asm_suffix = lava_splash_asm.get("profileSuffix", "")
        if asm_suffix.count("-lavasplashasm") != 1:
            fail("the R_LavaSplash assembly selector lacks its profile token")
        elif asm_suffix.replace("-lavasplashasm", "") != lava_splash_c.get("profileSuffix"):
            fail("the R_LavaSplash assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_LAVA_SPLASH" in lava_splash_c.get(flags_name, []):
                fail("the R_LavaSplash C selector enables ASM486_LAVA_SPLASH in %s" % flags_name)
            if "-DASM486_LAVA_SPLASH" not in lava_splash_asm.get(flags_name, []):
                fail("the R_LavaSplash assembly selector omits ASM486_LAVA_SPLASH from %s" % flags_name)
        for dump_name, dump in (("C", lava_splash_c), ("assembly", lava_splash_asm)):
            if "r_lavasplashasm.s" not in dump.get("assemblySources", []):
                fail("the R_LavaSplash %s selector omits r_lavasplashasm.s from the source inventory" % dump_name)

    teleport_splash_c = dump_flags("-TeleportSplashImplementation", "c")
    teleport_splash_asm = dump_flags("-TeleportSplashImplementation", "asm")
    if teleport_splash_c and teleport_splash_asm:
        if teleport_splash_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_TeleportSplash C selector changes the promoted i486 suffix")
        asm_suffix = teleport_splash_asm.get("profileSuffix", "")
        if asm_suffix.count("-teleportsplashasm") != 1:
            fail("the R_TeleportSplash assembly selector lacks its profile token")
        elif asm_suffix.replace("-teleportsplashasm", "") != teleport_splash_c.get("profileSuffix"):
            fail("the R_TeleportSplash assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_TELEPORT_SPLASH" in teleport_splash_c.get(flags_name, []):
                fail("the R_TeleportSplash C selector enables ASM486_TELEPORT_SPLASH in %s" % flags_name)
            if "-DASM486_TELEPORT_SPLASH" not in teleport_splash_asm.get(flags_name, []):
                fail("the R_TeleportSplash assembly selector omits ASM486_TELEPORT_SPLASH from %s" % flags_name)
        for dump_name, dump in (("C", teleport_splash_c), ("assembly", teleport_splash_asm)):
            if "r_teleportsplashasm.s" not in dump.get("assemblySources", []):
                fail("the R_TeleportSplash %s selector omits r_teleportsplashasm.s from the source inventory" % dump_name)

    transform_plane_c = dump_flags("-TransformPlaneImplementation", "c")
    transform_plane_asm = dump_flags("-TransformPlaneImplementation", "asm")
    if transform_plane_c and transform_plane_asm:
        if transform_plane_c.get("profileSuffix") != RELEASE_I486_SUFFIX:
            fail("the R_TransformPlane C selector changes the promoted i486 suffix")
        asm_suffix = transform_plane_asm.get("profileSuffix", "")
        if asm_suffix.count("-transformplaneasm") != 1:
            fail("the R_TransformPlane assembly selector lacks its profile token")
        elif asm_suffix.replace("-transformplaneasm", "") != transform_plane_c.get("profileSuffix"):
            fail("the R_TransformPlane assembly selector changes unrelated promoted suffix tokens")
        for flags_name in ("cFlags", "asmFlags"):
            if "-DASM486_TRANSFORM_PLANE" in transform_plane_c.get(flags_name, []):
                fail("the R_TransformPlane C selector enables ASM486_TRANSFORM_PLANE in %s" % flags_name)
            if "-DASM486_TRANSFORM_PLANE" not in transform_plane_asm.get(flags_name, []):
                fail("the R_TransformPlane assembly selector omits ASM486_TRANSFORM_PLANE from %s" % flags_name)
        for dump_name, dump in (("C", transform_plane_c), ("assembly", transform_plane_asm)):
            if "r_transformplaneasm.s" not in dump.get("assemblySources", []):
                fail("the R_TransformPlane %s selector omits r_transformplaneasm.s from the source inventory" % dump_name)

    # 6. Source inventory is pinned: 83 retained C (82 standalone, net_comx.c
    #    included by another unit), 62 assembly sources (one is omitted only
    #    when no assembly renderer is selected).
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
        if dump.get("allAssemblySourceCount") != 62:
            fail(
                "%s: expected 62 assembly sources, got %r"
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
