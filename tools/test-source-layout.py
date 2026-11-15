#!/usr/bin/env python3
"""Check the grouped source tree and its compatibility migration map."""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
LAYOUT = json.loads((ROOT / "docs" / "source-layout-map.json").read_text(encoding="utf-8"))

expected_groups = {
    "assets", "audio", "client", "collision", "core", "memory",
    "network", "platform", "renderer", "server", "video",
}
expected_map_groups = (expected_groups - {"platform"}) | {"platform/dos", "tests/bench486"}
if set(LAYOUT["groups"]) != expected_map_groups:
    raise SystemExit("source-layout-map.json has an unexpected subsystem inventory")

seen_from = set()
seen_to = set()
for entry in LAYOUT["migrations"]:
    old = entry["from"]
    new = entry["to"]
    if old in seen_from or new in seen_to:
        raise SystemExit(f"duplicate source-layout mapping: {old} -> {new}")
    seen_from.add(old)
    seen_to.add(new)
    if (ROOT / new).is_file() is False:
        raise SystemExit(f"mapped source is missing: {new}")
    if (ROOT / old).exists():
        raise SystemExit(f"legacy flat path still exists: {old}")

flat_joins = [
    (
        old,
        re.compile(rb"[\"']src[\"']\s*,\s*[\"']" + re.escape(Path(old).name.encode("ascii")) + rb"[\"']"),
    )
    for old in seen_from
]

for base in (ROOT / "src", ROOT / "tools", ROOT / "docs"):
    for path in base.rglob("*"):
        if (not path.is_file() or path.suffix.lower() not in
                {".c", ".h", ".inc", ".s", ".ps1", ".py", ".md", ".json", ".txt", ".csv"} or
                path == ROOT / "docs" / "source-layout-map.json"):
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative.startswith("docs/ledger/"):
            continue
        data = path.read_bytes()
        for old in seen_from:
            old_slash = old.encode("ascii")
            old_backslash = old.replace("/", "\\").encode("ascii")
            if old_slash in data or old_backslash in data:
                raise SystemExit(f"active source reference still uses the flat path {old}: {relative}")
        if path.suffix.lower() in {".py", ".ps1"}:
            for old, flat_join in flat_joins:
                if flat_join.search(data):
                    raise SystemExit(f"active source reference still joins a moved file from src/: {old} in {relative}")

production_groups = expected_groups
sources = [p for p in SOURCE.rglob("*") if p.is_file() and p.suffix.lower() in {".c", ".s"}]
for source in sources:
    relative = source.relative_to(SOURCE).as_posix()
    first = relative.split("/", 1)[0]
    if first == "tests":
        raise SystemExit(f"test source is part of the production inventory: {relative}")
    if first not in production_groups:
        raise SystemExit(f"production source is not grouped by subsystem: {relative}")

fixtures = SOURCE / "tests" / "bench486"
if not fixtures.is_dir():
    raise SystemExit("BENCH486 fixture subtree is missing")
fixture_files = [
    p for p in fixtures.iterdir()
    if p.is_file() and p.name != "bench486_profile.h"
]
if len(fixture_files) != 108:
    raise SystemExit(f"expected 108 BENCH486 fixture files, found {len(fixture_files)}")
if any(not (p.name.startswith("bench486_") or p.name.endswith("_bench_hooks.inc")) for p in fixture_files):
    raise SystemExit("unexpected file in the BENCH486 fixture subtree")
if any(SOURCE.glob("bench486_*")):
    raise SystemExit("BENCH486 fixtures remain beside production sources")

interfaces = {
    "console.h": {"common.h"},
    "draw.h": {"wad.h"},
    "render.h": {"common.h", "mathlib.h", "protocol.h", "vid.h"},
    "vid.h": {"q_types.h"},
    "zone.h": {"q_types.h"},
    "client.h": {"common.h", "cvar.h", "mathlib.h", "protocol.h", "q_shared.h", "render.h", "sound.h", "vid.h"},
    "server.h": {"client.h", "common.h", "cvar.h", "mathlib.h", "progs.h", "q_shared.h"},
    "host.h": {"cvar.h", "q_types.h"},
    "net.h": {"common.h", "cvar.h"},
    "net_loop.h": {"net.h"},
    "wad.h": {"q_types.h"},
    "input.h": {"client.h"},
    "keys.h": {"q_types.h"},
    "d_iface.h": {"render.h"},
    "renderer/r_shared.h": {"vid.h"},
    "video/vid_dos.h": {"cvar.h", "vid.h"},
    "video/vid_vesa.h": {"vid.h"},
}
for name, dependencies in interfaces.items():
    text = (SOURCE / name).read_text(encoding="utf-8")
    actual = {line.split('"')[1] for line in text.splitlines() if line.lstrip().startswith("#include ") and '"' in line}
    missing = dependencies - actual
    if missing:
        raise SystemExit(f"{name} is missing direct interface dependencies: {sorted(missing)}")

host_text = (SOURCE / "host.h").read_text(encoding="utf-8")
for declaration in (
        "extern quakeparms_t host_parms;",
        "extern double realtime;",
        "extern double host_frametime;",
        "extern int host_framecount;",
        "extern byte *host_colormap;",
        "extern int minimum_memory;",
        "extern cvar_t sys_ticrate;",
        "extern cvar_t sys_nostdout;",
        "extern cvar_t developer;"):
    if declaration not in host_text:
        raise SystemExit(f"host.h is missing its owned declaration: {declaration}")

bench_console_text = (
    SOURCE / "tests" / "bench486" / "bench486_console.h"
).read_text(encoding="utf-8")
for declaration in (
        "void Con_CheckResize_C (void);",
        "int Bench486ConsoleResizeCases (void);",
        "void Bench486ConPrintSound (char *sample);",
        "int Bench486ConsoleOutputOpen (char *file, int flags, int mode);",
        "int Bench486ConsoleOutputWrite (int fd, char *data, unsigned count);",
        "int Bench486ConsoleOutputClose (int fd);",
        "void Bench486ConsoleOutputSysPrintf (char *format, ...);",
        "void Bench486ConsoleOutputUpdateScreen (void);"):
    if declaration not in bench_console_text:
        raise SystemExit(f"bench486_console.h is missing its test-only declaration: {declaration}")
for relative in (
        "client/asm_consolecheckresize.h",
        "client/asm_consoleinput.h",
        "client/asm_consoleoutput.h"):
    text = (SOURCE / relative).read_text(encoding="utf-8")
    if "Bench486" in text or "Con_CheckResize_C" in text:
        raise SystemExit(f"{relative} contains declarations owned by the BENCH interface")

video_text = (SOURCE / "vid.h").read_text(encoding="utf-8")
for declaration in ("#define MAXHEIGHT", "#define MAXWIDTH"):
    if declaration not in video_text:
        raise SystemExit(f"vid.h is missing its owned dimension: {declaration}")

render_text = (SOURCE / "render.h").read_text(encoding="utf-8")
for declaration in (
        "#define WARP_WIDTH",
        "#define WARP_HEIGHT",
        "#define SURFCACHE_SIZE_AT_320X200",
        "extern short *d_pzbuffer;"):
    if declaration not in render_text:
        raise SystemExit(f"render.h is missing its owned declaration: {declaration}")

quakedef_text = (SOURCE / "quakedef.h").read_text(encoding="utf-8")
if '#include "host.h"' not in quakedef_text:
    raise SystemExit("quakedef.h no longer imports the host compatibility interface")
common_text = (SOURCE / "common.h").read_text(encoding="utf-8")
if not re.search(r"(?m)^\s*#\s*define\s+QUAKE_GAME\b", common_text):
    raise SystemExit("common.h no longer selects game-side BSP declarations")
if not re.search(r"(?m)^\s*#\s*define\s+UNUSED\b", common_text):
    raise SystemExit("common.h no longer owns the shared UNUSED helper")
if re.search(r"(?m)^\s*#\s*define\s+UNUSED\b", quakedef_text):
    raise SystemExit("UNUSED helper remains privately defined in quakedef.h")
if re.search(r"(?m)^\s*#\s*define\s+QUAKE_GAME\b", quakedef_text):
    raise SystemExit("QUAKE_GAME context remains privately defined in quakedef.h")

for relative in ("src/core/crc.c", "src/core/cvar.c"):
    text = (ROOT / relative).read_text(encoding="utf-8")
    if '#include "quakedef.h"' in text:
        raise SystemExit(f"migrated core module still includes quakedef.h: {relative}")

print(f"Source layout PASS: {len(sources)} production units, {len(fixture_files)} BENCH fixtures, {len(seen_to)} mapped files")
