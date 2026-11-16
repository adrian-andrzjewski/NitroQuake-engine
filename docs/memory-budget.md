# DOS engine and renderer memory budget

`meminfo` prints the live engine, video, renderer, and stack budget. It runs
once during startup before `quake.rc`; enter it again from the console to see
current allocations and the observed peaks accumulated while rendering.

## Source-derived 320x200 i486 release budget

| Pool or allocation | Bytes | Accounting |
| --- | ---: | --- |
| Engine block, standard game minimum | `0x550000` (5,570,560) | Supplied as one contiguous arena to `Memory_Init`. |
| Engine block, registered game minimum | `0x650000` (6,619,136) | Standard minimum plus 1 MiB for `-hipnotic` or `-rogue`. |
| Default zone | `0xC000` (49,152) | Low-hunk allocation; `-zone` changes it. |
| Surface cache at 320x200 | 2,457,600 | High-hunk video payload; `-surfcachesize` overrides it. |
| Z buffer | 128,000 | `320 * 200 * sizeof(short)`, in the video high-hunk block. |
| Single-buffer framebuffer | 64,320 | `320 * (200 + 1)` bytes, in the video high-hunk block. |
| 320x200 alignment pad | 16 | Added between surface cache and framebuffer. |
| Total video payload | 2,649,936 | Cache + Z buffer + framebuffer + pad. |
| Video hunk block | 2,649,952 | Payload plus the 16-byte hunk header. |
| Frame-local edge/surface arrays | 128,096 | `2401 * 32` edge bytes + `801 * 64` surface bytes. |
| i486 release edge frame | 128,176 | Generated assembly frame including alignment and saved registers. |
| Waterwarp image | 64,000 | Renderer `malloc`; on failure, a separate guarded stack frame may be used. |

These are the default 320x200 values. Resolution, `-surfcachesize`, renderer
capacity cvars, and the loaded BSP change the live report. At larger resolutions
the default surface cache grows by three bytes per pixel above 320x200.

## Example runtime capture

This i486 release capture used VGA BIOS mode 0x13 at 320x200. It ran `map e1m1`
and entered `meminfo` after 40 `wait` commands. Values are observations from
one DOSBox-X/CWSDPMI run; the stack measurements describe that DPMI environment.

| Pool | Observed value |
| --- | --- |
| Engine block | 30,008,668 supplied; 5,570,560 minimum |
| Engine arena | Zone 49,152; low hunk 3,343,232 (peak 3,456,736); high hunk 2,660,192 (peak 4,015,152); gap 24,005,244 |
| Cache | 1,453,408 bytes in 34 blocks, included in the hunk gap |
| Video | 320x200; cache request/allocated 2,457,600, usable 2,457,596; Z 128,000; framebuffer 64,320; pad 16; video hunk 2,649,952; gap after setup 26,962,700 |
| Edges and surfaces | Edges: capacity 2,400, peak 405 (12,960 bytes), extra hunk 0; surfaces: capacity 800, peak 209 (13,376 bytes), extra hunk 0 |
| Renderer stack arrays | 128,096 local bytes; 128,176 generated edge frame |
| Waterwarp | 64,000-byte buffer allocated; last route used the allocated buffer (37 allocated, 0 stack, 0 skipped) |
| DPMI stack | BSP depth 63; available minimum 523,940; normal 180,932 with 343,008 headroom; fallback 244,948 with 278,992 headroom |

A separate standard `-minmemory` startup reached video setup with the engine
block exactly at 5,570,560 bytes. That capture did not reach a rendered map.
The registered-data minimum remains source-derived; no Hipnotic or Rogue PAKs
were available for a registered-data runtime capture.

## Reading `meminfo`

- The engine block line shows total supplied and the active startup minimum.
- Zone, low/high hunk, and the hunk gap are portions of that engine block. The
  zone is itself part of low-hunk use, so do not add it to low hunk. Cache bytes
  are live cache blocks inside the reported gap. Video allocations are included
  in high-hunk use; extra renderer edge/surface allocations are included in
  low-hunk use. Do not add these breakdowns to the engine total.
- Video reports the active mode, requested and allocated surface cache, usable
  cache after its four-byte guard, Z/framebuffer/pad sizes, the high-hunk video
  block, and the gap captured immediately after video setup.
- Renderer edge/surface peaks count actual usage since the current map loaded.
  Capacity above 2,400 edges or 800 surfaces allocates additional hunk storage;
  the default local arrays still reserve their frame space. The report gives
  the generated edge-frame cost for the selected profile.
- Hunk high-water marks accumulate since `Memory_Init`. Renderer stack values
  are separate: the dispatcher samples actual ESP against DJGPP's bounds,
  reports the current BSP-derived normal and warp-fallback requirements, and
  compares them with the lowest available stack observed so far. A stack value
  is unavailable until rendering has reached the guard.
- Waterwarp reports the 64,000-byte allocation result, the last dispatcher
  route, and counts for allocated-buffer, guarded-stack, and skipped routes.
  The DOS stack is outside the engine block and must remain a separate line.

The current release formulas are `172868 + 128 * BSP-depth` bytes for normal
rendering and `236884 + 128 * BSP-depth` for the stack warp fallback. The
fallback includes the additional 64,012-byte frame and its call. The C-reference
profile derives its own formula from its selected frames; use the runtime line
for that build rather than applying the i486 release constants.

## Capture points

1. Save the startup `meminfo` block printed before `quake.rc` runs.
2. Load a representative large map, let it render, then enter `meminfo`. Hunk
   peaks cover loading; edge/surface and stack peaks cover completed frames.
3. For a rendering run, finish a deterministic timedemo or gameplay interval,
   then enter `meminfo` before changing maps. The observed renderer peaks remain
   available after the interval.
4. Repeat with `-minmemory`, then with registered data selected by `-hipnotic`
   or `-rogue`. The engine line shows the exact supplied/minimum values; a video
   rejection reports the mode payload and the memory allowance that failed.

DOSBox/DPMI results describe that run's available stack only. The measured
stack headroom is not a fixed reserve and does not characterize other DPMI
hosts or physical 486 systems.
