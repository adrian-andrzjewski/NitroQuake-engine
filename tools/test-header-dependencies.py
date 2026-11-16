#!/usr/bin/env python3
"""Keep legacy umbrella and benchmark-interface dependencies explicit."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src"
LEGACY_LIST = ROOT / "docs" / "legacy-quakedef-includes.txt"
PROFILE_HEADER = SOURCE / "tests" / "bench486" / "bench486_profile.h"

INCLUDE_QUAKEDEF = re.compile(
    r'^\s*#\s*include\s*[<"]quakedef\.h[>"]', re.MULTILINE
)
for include_form in (
    '#include "quakedef.h"',
    "# include <quakedef.h>",
    '#include "quakedef.h" // legacy dependency',
):
    if not INCLUDE_QUAKEDEF.search(include_form):
        raise SystemExit(f"umbrella include detector missed: {include_form}")
INCLUDE_PROFILE = re.compile(
    r'^\s*#\s*include\s*"tests/bench486/bench486_profile\.h"\s*$',
    re.MULTILINE,
)
PROFILE_SYMBOL = re.compile(
    r"\b(?:BENCH486_PROFILE_[A-Za-z0-9_]+|BENCH486_TIMEDEMO_[A-Za-z0-9_]+|"
    r"bench486_[A-Za-z0-9_]+|Bench486[A-Za-z0-9_]+|Zone_ResetProfileCounters)\b"
)

production_sources = sorted(
    path for path in SOURCE.rglob("*.c")
    if "tests" not in path.relative_to(SOURCE).parts
)
legacy_sources = {
    path.relative_to(ROOT).as_posix()
    for path in production_sources
    if INCLUDE_QUAKEDEF.search(path.read_text(encoding="utf-8", errors="replace"))
}

listed = [
    line.strip()
    for line in LEGACY_LIST.read_text(encoding="utf-8").splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]
if len(listed) != len(set(listed)):
    raise SystemExit("legacy-quakedef-includes.txt contains duplicate paths")
if set(listed) != legacy_sources:
    unlisted = sorted(legacy_sources - set(listed))
    stale = sorted(set(listed) - legacy_sources)
    raise SystemExit(
        "legacy quakedef include inventory differs; "
        f"unlisted={unlisted}, stale={stale}"
    )

umbrella = (SOURCE / "quakedef.h").read_text(encoding="utf-8", errors="replace")
common_header = (SOURCE / "common.h").read_text(encoding="utf-8", errors="replace")
host_header = (SOURCE / "host.h").read_text(encoding="utf-8", errors="replace")
host_source = (SOURCE / "core" / "host.c").read_text(encoding="utf-8", errors="replace")
cpu_header = (SOURCE / "core" / "cpu.h").read_text(encoding="utf-8", errors="replace")
renderer_header = (SOURCE / "render.h").read_text(encoding="utf-8", errors="replace")
video_header = (SOURCE / "vid.h").read_text(encoding="utf-8", errors="replace")
driver_interface = (SOURCE / "d_iface.h").read_text(encoding="utf-8", errors="replace")
profile_header_text = PROFILE_HEADER.read_text(encoding="utf-8", errors="replace")
if '#include "core/cpu.h"' not in umbrella or '#include "core/cpu.h"' not in common_header:
    raise SystemExit("common and legacy headers must expose the shared CPU target interface")
if "extern qboolean isDedicated;" not in host_header:
    raise SystemExit("host.h is missing the host-owned dedicated-mode declaration")
if "extern qboolean isDedicated;" in umbrella:
    raise SystemExit("dedicated-mode declaration remains in quakedef.h")
if re.search(r"(?m)^\s*#\s*define\s+MINIMUM_MEMORY\b", umbrella):
    raise SystemExit("host startup memory thresholds remain in quakedef.h")
for definition in ("MINIMUM_MEMORY", "MINIMUM_MEMORY_LEVELPAK"):
    if not re.search(r"(?m)^\s*#\s*define\s+" + definition + r"\b", host_source):
        raise SystemExit(f"host.c is missing its local startup threshold: {definition}")
if re.search(r"(?m)^\s*#\s*define\s+MAX_NUM_ARGVS\b", umbrella):
    raise SystemExit("common command-line capacity remains in quakedef.h")
if re.search(r"(?m)^\s*#\s*define\s+GAMENAME\b", umbrella):
    raise SystemExit("common default game directory remains in quakedef.h")
common_source = (SOURCE / "core" / "common.c").read_text(encoding="utf-8", errors="replace")
if not re.search(r"(?m)^\s*#\s*define\s+MAX_NUM_ARGVS\b", common_source):
    raise SystemExit("common.c is missing its local argument capacity")
if not re.search(r"(?m)^\s*#\s*define\s+GAMENAME\b", common_source):
    raise SystemExit("common.c is missing its local default game directory")
for definition in (
        "#define id386 1",
        "#define id386 0",
        "#define UNALIGNED_OK 1",
        "#define UNALIGNED_OK 0"):
    if definition not in cpu_header:
        raise SystemExit(f"core/cpu.h is missing {definition}")
for declaration in (
        "void D_BeginDirectRect (int x, int y, byte *pbitmap, int width, int height);",
        "void D_EndDirectRect (int x, int y, int width, int height);"):
    if declaration not in video_header:
        raise SystemExit(f"vid.h is missing the video-owned declaration: {declaration}")
    if declaration in driver_interface:
        raise SystemExit(f"video-owned declaration remains in d_iface.h: {declaration}")
for declaration in (
        "void D_EnableBackBufferAccess (void);",
        "void D_DisableBackBufferAccess (void);",
        "void D_UpdateRects (vrect_t *prect);"):
    if declaration not in renderer_header:
        raise SystemExit(f"render.h is missing the renderer-owned declaration: {declaration}")
    if declaration in driver_interface:
        raise SystemExit(f"renderer-owned declaration remains in d_iface.h: {declaration}")
screen_source = (
    SOURCE / "client" / "screen.c"
).read_text(encoding="utf-8", errors="replace")
if '#include "renderer/r_local.h"' in screen_source:
    raise SystemExit("client screen code depends on the renderer-private header")
if re.search(r"(?m)^\s*#\s*define\s+CACHE_SIZE\b", umbrella):
    raise SystemExit("renderer alignment constant remains in quakedef.h")
if not re.search(r"(?m)^\s*#\s*define\s+CACHE_SIZE\b", renderer_header):
    raise SystemExit("render.h is missing the renderer alignment constant")
if "#ifndef BENCH486_PROFILE_H" not in profile_header_text:
    raise SystemExit("benchmark profiling interface has no include guard")
profile_symbols = set(PROFILE_SYMBOL.findall(profile_header_text))
if any(re.search(r"\b" + re.escape(symbol) + r"\b", umbrella) for symbol in profile_symbols):
    raise SystemExit("profiling declarations remain in quakedef.h")
if re.search(r"(?m)^\s*#\s*ifdef\s+PROFILE486\b", umbrella):
    raise SystemExit("PROFILE486 declarations remain in quakedef.h")

profile_consumers = 0
for path in production_sources:
    text = path.read_text(encoding="utf-8", errors="replace")
    if any(re.search(r"\b" + re.escape(symbol) + r"\b", text) for symbol in profile_symbols):
        if not INCLUDE_PROFILE.search(text):
            raise SystemExit(
                "profiling consumer omits its direct interface include: "
                f"{path.relative_to(ROOT).as_posix()}"
            )
        profile_consumers += 1

drawing_asm_text = (SOURCE / "renderer" / "asm_drawing.h").read_text(encoding="utf-8")
drawing_bench_text = (
    SOURCE / "tests" / "bench486" / "bench486_drawing_iface.h"
).read_text(encoding="utf-8")
if "Bench486Drawing" in drawing_asm_text or "bench486_drawing_probe" in drawing_asm_text:
    raise SystemExit("benchmark drawing declarations remain in the production assembly contract")
if "#ifndef BENCH486_DRAWING_IFACE_H" not in drawing_bench_text:
    raise SystemExit("benchmark drawing interface has no include guard")
if '#include "renderer/asm_drawing.h"' in drawing_bench_text:
    raise SystemExit("benchmark drawing interface depends on the production assembly contract")
for declaration in (
        "bench486_drawing_probe",
        "Bench486DrawingLump",
        "Draw_PicFromWad_Drawing_C",
        "Draw_EndDisc_Drawing_C"):
    if declaration not in drawing_bench_text:
        raise SystemExit(f"bench486_drawing_iface.h is missing its owned declaration: {declaration}")
for relative in (
        "src/client/draw.c",
        "src/tests/bench486/bench486_drawing.h"):
    text = (ROOT / relative).read_text(encoding="utf-8")
    if '#include "tests/bench486/bench486_drawing_iface.h"' not in text:
        raise SystemExit(f"{relative} omits the drawing benchmark interface")
if '#include "renderer/asm_drawing.h"' not in (
        SOURCE / "tests" / "bench486" / "bench486_drawing.h").read_text(encoding="utf-8"):
    raise SystemExit("drawing benchmark fixture omits its renderer layout contract")

sprite_hooks_path = SOURCE / "tests" / "bench486" / "bench486_sprite_hooks.h"
sprite_hooks_text = sprite_hooks_path.read_text(encoding="utf-8", errors="replace")
renderer_private_text = (
    SOURCE / "renderer" / "r_local.h"
).read_text(encoding="utf-8", errors="replace")
if "#ifndef BENCH486_SPRITE_HOOKS_H" not in sprite_hooks_text:
    raise SystemExit("benchmark sprite hook interface has no include guard")
if "struct spritedesc_s;" not in sprite_hooks_text or '#include "d_iface.h"' in sprite_hooks_text:
    raise SystemExit("benchmark sprite hook interface is not forward-declared")
for declaration in (
        "bench486_sprite_setup_hook",
        "bench486_sprite_project_hook"):
    if declaration not in sprite_hooks_text:
        raise SystemExit(f"bench486_sprite_hooks.h is missing its declaration: {declaration}")
    if declaration in renderer_private_text:
        raise SystemExit(f"benchmark sprite hook remains in renderer/r_local.h: {declaration}")
for relative in (
        "src/renderer/d_sprite.c",
        "src/renderer/r_sprite.c",
        "src/core/host_cmd.c",
        "src/tests/bench486/bench486_publicbindings.h",
        "src/tests/bench486/bench486_renderdispatch.h",
        "src/tests/bench486/bench486_sprite_orientation.h"):
    text = (ROOT / relative).read_text(encoding="utf-8", errors="replace")
    if '#include "tests/bench486/bench486_sprite_hooks.h"' not in text:
        raise SystemExit(f"{relative} omits the sprite benchmark hook interface")

light_probe_path = SOURCE / "tests" / "bench486" / "bench486_light_probe.h"
light_probe_text = light_probe_path.read_text(encoding="utf-8", errors="replace")
light_asm_text = (SOURCE / "renderer" / "asm_light.h").read_text(
    encoding="utf-8", errors="replace")
if "#ifndef BENCH486_LIGHT_PROBE_H" not in light_probe_text:
    raise SystemExit("benchmark light probe interface has no include guard")
for declaration in (
        "bench486_mark_lights_probe_t",
        "bench486_mark_lights_probe",
        "R_MarkLights_C",
        "R_PushDlights_C",
        "ml_probe_planedist",
        "ml_probe_size"):
    if declaration not in light_probe_text:
        raise SystemExit(
            f"bench486_light_probe.h is missing its owned declaration: {declaration}")
    if declaration in renderer_private_text or declaration in light_asm_text:
        raise SystemExit(
            f"BENCH light declaration remains in a production renderer header: {declaration}")
for relative in (
        "src/renderer/r_light.c",
        "src/renderer/r_lightasm.s",
        "src/core/host_cmd.c"):
    text = (ROOT / relative).read_text(encoding="utf-8", errors="replace")
    if '#include "tests/bench486/bench486_light_probe.h"' not in text:
        raise SystemExit(f"{relative} omits the light benchmark interface")

print(
    "Header dependencies PASS: "
    f"{len(production_sources)} production C files, "
    f"{len(legacy_sources)} explicit legacy umbrella users, "
    f"{profile_consumers} direct profiling consumers"
)
