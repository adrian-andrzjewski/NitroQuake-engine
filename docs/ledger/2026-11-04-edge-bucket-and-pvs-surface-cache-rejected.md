# Active-edge buckets and PVS surface epochs rejected (2026-11-04)

Status: rejected. The bucketed edge search changed rendered color, and moving
surface marks into the PVS pass marked faces that the per-frame frustum walk
does not accept. No candidate code is retained.

## Baseline and protocol

The matched control was `out/dos-timedemo-20261104-155958`, using DOSBox-X
2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, and 320x200 output. It completed 969 timed frames and recorded 970
color and Z checksum records. Its final framebuffer checksum was
`1047377823`; its diagnostic pushback-search count was 96,243.

Every candidate completed the full strict source, linked executable, startup,
and DOS provider ISA gates with zero above-i486, unknown, or exempted
instructions. These were instrumented parity screens only. No uninstrumented
timing A/B was run after a parity failure.

## Active-edge screen buckets

The prototype kept Quake's sorted active-edge list and added a scanline-local
index of 16-pixel screen-x buckets to choose a predecessor for edges that cross.
The first forward-search version differed at color frames 55, 136, 137, and
466, and at Z frames 136 and 137. A backward search from the nearest higher
bucket reduced the differences to color frames 55 and 466, with exact Z
checksums. Restricting index use to crossings of at least 16 pixels preserved
the same two color differences but still recorded 120,219 pushback-search
iterations versus 96,243 for control. The unrestricted backward search
recorded 181,454 iterations. The index added work and did not preserve exact
output, so the assembly changes were removed.

## PVS surface epoch cache

This prototype moved world-surface visibility stamps from the per-frame BSP
leaf walk into `R_MarkLeaves`, reusing them until the PVS view leaf changed.
It changed color frames 55, 249, 863, and 864; all Z records and the final
framebuffer checksum matched. The candidate also raised instrumented
`R_RenderFace` calls from 215,751 to 274,845 and world-BSP inclusive time from
14.435 to 16.793 seconds. PVS membership alone is not the surface visibility
set used by the renderer: the BSP walk applies view-frustum clipping before
marking leaf surfaces. Moving the marks to the PVS loop admitted additional
faces and changed color. The C and assembly changes were removed.

## Disposition and evidence

The experiments show that the active edge ordering and per-frame frustum
filtering are correctness boundaries for these indexes. Neither candidate
justifies a timing run or retained code. Their ignored build, checksum, profile,
capture, and ISA artifacts remain under `out/` for review:

- `out/dos-timedemo-20261104-175924` — first forward bucket search.
- `out/dos-timedemo-20261104-181924` — backward bucket search.
- `out/dos-timedemo-20261104-183942` — long-crossing-only bucket search.
- `out/dos-timedemo-20261104-190754` — PVS surface epoch cache.

The prior world-span depth-hierarchy rejection is recorded separately in
[`2026-11-04-world-span-hzb-alias-rejected.md`](2026-11-04-world-span-hzb-alias-rejected.md).
