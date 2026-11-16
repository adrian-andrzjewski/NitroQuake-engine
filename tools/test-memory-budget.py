#!/usr/bin/env python3
"""Check the source-derived DOS memory budget and its runtime reporting path."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"memory budget check failed: {message}")


host = read("src/core/host.c")
host_cmd = read("src/core/host_cmd.c")
zone = read("src/memory/zone.c")
zone_asm = read("src/memory/zone_heapasm.s")
hunk_asm = read("src/memory/zone_hunknamedallocasm.s")
video = read("src/video/vid_vga.c")
renderer = read("src/renderer/r_main.c")
doc = read("docs/memory-budget.md")
runner = read("tools/run-tests.ps1")

require("#define MINIMUM_MEMORY\t\t\t0x550000" in host,
        "standard engine minimum must remain source-derived")
require("#define MINIMUM_MEMORY_LEVELPAK\t(MINIMUM_MEMORY + 0x100000)" in host,
        "registered-data minimum must remain one MiB above standard")
require("Engine memory block too small:" in host and
        'standard_quake ? "standard" : "registered-data"' in host,
        "minimum-memory failures must identify the required game-data path")
require('Cbuf_InsertText ("meminfo\\nexec quake.rc\\n")' in host,
        "startup must print the initial memory budget before quake.rc")
require('Cmd_AddCommand ("meminfo", Host_Meminfo_f)' in host_cmd and
        "Memory_ReportBudget ();" in host_cmd and
        "VID_ReportMemoryBudget ();" in host_cmd and
        "R_ReportMemoryBudget ();" in host_cmd,
        "meminfo must report each owning subsystem")
require("hunk_low_peak_used" in zone and "hunk_high_peak_used" in zone and
        "hunk_low_peak_used = 0;" in zone and "hunk_high_peak_used = 0;" in zone,
        "C hunk allocator must reset and update high-water marks")
require("memory_zone_size = zonesize;" in zone,
        "C memory initialization must retain the configured zone size")
require("hunk_low_peak_used" in zone_asm and
        "hunk_high_peak_used" in zone_asm and
        "C(memory_zone_size)" in zone_asm,
        "assembly Memory_Init must reset high-water marks and zone size")
require("C(hunk_low_peak_used)" in hunk_asm and
        "C(hunk_high_peak_used)" in hunk_asm,
        "assembly hunk allocators must update high-water marks")
require("cache_bytes += entry->size;" in zone and
        "included in hunk gap" in zone,
        "live cache must be shown as a subset of the hunk gap")
require("VGA_zbuffersize" in video and "VGA_framebuffersize" in video and
        "VGA_video_hunkbytes" in video and "VGA_hunk_gap_after_setup" in video,
        "video diagnostics must use the allocated buffer sizes")
require("Not enough memory for video mode %dx%d" in video and
        "Video high-hunk allocation failed" in video,
        "video failure messages must identify the rejected allocation")
require("lvid->width, lvid->height, tbuffersize," in video,
        "video rejection must report the complete payload without double-counting cache")
require("requested_cache = D_SurfaceCacheForRes (vid.width, vid.height);" in video,
        "video diagnostics must report the resolution-aware cache request")
require("r_render_stack_min_available" in renderer and
        "R_RecordRendererMemoryBudgetFrame" in renderer and
        "R_WarpStackRequirement (&fallback_required)" in renderer,
        "renderer must track usage and report normal/fallback stack capacity")
require('default: return "no render yet";' in renderer and
        "r_warp_last_route = R_WARP_ROUTE_ALLOCATED;" in renderer,
        "warp allocation state must not claim a render route before rendering")
require("test-memory-budget.py" in runner,
        "memory budget regression must run in the host suite")

surface_cache = 2400 * 1024
z_buffer = 320 * 200 * 2
framebuffer = 320 * 201
alignment_pad = 16
video_payload = surface_cache + z_buffer + framebuffer + alignment_pad

require(surface_cache == 2_457_600, "320x200 surface-cache baseline")
require(z_buffer == 128_000, "320x200 Z-buffer baseline")
require(framebuffer == 64_320, "320x200 framebuffer baseline")
require(video_payload == 2_649_936 and video_payload + 16 == 2_649_952,
        "video payload and hunk header totals")
for value in ("2,457,600", "128,000", "64,320", "2,649,936",
              "2,649,952", "128,096", "128,176", "64,000"):
    require(value in doc, f"documentation must include source-derived value {value}")

print("DOS engine and renderer memory budget checks: PASS")
