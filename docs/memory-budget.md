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

## Runtime captures

These captures use the i486 release build `ba68f9c75723-efcec970319b`, DOSBox-X
2026.08.31, and CWSDPMI. The emulator reports an 80486 CPU, DOS 5.00, DPMI 0.90,
and 31,280 KiB of physical RAM. They describe this DOSBox/DPMI setup, not a
physical 486 or other DPMI hosts.

### Startup at 320x200

The first `meminfo` runs before `quake.rc`, before a map loads, and before a
render frame samples the stack guard.

| Pool | Startup observation |
| --- | --- |
| Engine block | 30,008,668 supplied; 5,570,560 minimum |
| Engine arena | Zone 49,152; low hunk 480,544; high hunk 2,649,952; gap 26,878,172 |
| Cache | 64,064 bytes in 1 block, included in the hunk gap |
| Video | 320x200; cache request/allocated 2,457,600, usable 2,457,596; Z 128,000; framebuffer 64,320; pad 16; video hunk 2,649,952; gap after setup 26,962,700 |
| Renderer | Edges and surfaces both 0 used; 128,096 local array bytes; 128,176 generated edge frame |
| Waterwarp and stack | 64,000-byte warp buffer allocated; no warp route yet; renderer stack not sampled until the first render guard |

### Large-map render capture

The base-game PAK directory identifies `e4m7` as the largest supplied BSP
(1,495,232 bytes). This run loaded `e4m7`, executed 40 `wait` commands, then
entered `meminfo` while still on that map.

| Pool | Observation after `e4m7` rendering |
| --- | --- |
| Engine block | 30,008,668 supplied; 5,570,560 minimum |
| Engine arena | Zone 49,152; low hunk 3,624,832 (peak 3,806,144); high hunk 2,731,872 (peak 4,145,216); gap 23,651,964 |
| Cache | 2,199,856 bytes in 47 blocks, included in the hunk gap |
| Video | 320x200; cache request/allocated 2,457,600, usable 2,457,596; Z 128,000; framebuffer 64,320; pad 16; video hunk 2,649,952; gap after setup 26,962,700 |
| Edges and surfaces | Edges: capacity 2,400, peak 510 (16,320 bytes), extra hunk 0; surfaces: capacity 800, peak 255 (16,320 bytes), extra hunk 0 |
| Renderer stack arrays | 128,096 local bytes; 128,176 generated edge frame |
| Waterwarp | 64,000-byte buffer allocated; allocated-buffer route 37 times, stack 0, skipped 0 |
| DPMI stack | BSP depth 87; available minimum 523,940; normal 184,004 with 339,936 headroom; fallback 248,020 with 275,920 headroom |

### Registered-data expansion renders

These runs used the local Hipnotic and Rogue PAKs with the base `testdata/id1`
PAKs. Both selected registered data and reported a 6,619,136-byte minimum. Each
map ran for 40 `wait` commands before `meminfo`; the VGA 320x200 video layout
and its 2,649,952-byte high-hunk block matched the startup capture.

| Run | Hunk arena after rendering | Cache | Renderer peaks | DPMI stack at observed minimum |
| --- | --- | --- | --- | --- |
| `-hipnotic`, `hip1m3` (2,218,640-byte BSP) | Low 5,041,952 (peak 5,171,152); high 2,654,592 (peak 4,868,624); gap 22,312,124 | 2,888,384 bytes, 63 blocks | Edges 414 (13,248 bytes); surfaces 179 (11,456 bytes); extra hunk 0 | BSP depth 111; available 523,940; normal 187,076 with 336,864 headroom; fallback 251,092 with 272,848 headroom |
| `-rogue`, `r2m7` (2,291,536-byte BSP) | Low 5,354,384 (peak 5,481,328); high 2,700,256 (peak 4,941,520); gap 21,954,028 | 3,676,784 bytes, 75 blocks | Edges 554 (17,728 bytes); surfaces 251 (16,064 bytes); extra hunk 0 | BSP depth 105; available 523,940; normal 186,308 with 337,632 headroom; fallback 250,324 with 273,616 headroom |

Both expansion renders used the allocated 64,000-byte warp buffer 37 times;
neither used the stack fallback or skipped a warp. These are DOSBox-X/CWSDPMI
observations and do not qualify a physical 486 or other DPMI stack size.

### Low-memory map boundary

These controlled map-load traces used the `i486-c-reference` selector set with
the opt-in `MEMORY_ALLOCATION_TRACE` diagnostic build mode. The build was
`f811a411e2fa-e53a4a60da19` (source revision
`f811a411e2fa69455c4734c6bc9f5ed9ac91913c`), executable SHA256
`A9892488B1462BC080635E6DC11B0055BBB2B15018D146E4F4A4AC873D68A338`, and
manifest SHA256
`69057909F18FC252237D9D5E97CF84A9EFA99AAEBB01E7A9CD34589EDAEAE7DF`. DOSBox-X
2026.08.31 with CWSDPMI reported an 80486 CPU, DOS 5.00, DPMI 0.90, and
31,280 KiB of physical RAM. This is emulator evidence for that configuration,
not a physical-486 or general DPMI guarantee.

| Run | Engine block | First limiting allocation | Map result |
| --- | ---: | --- | --- |
| `-minmemory`, `e1m1` | 5,570,560 bytes | Low hunk: request 107,984; aligned block 108,000; 47,760 bytes available. | Startup and video setup pass; map stops before `POSTMAP`. |
| `-mem 6.90625`, `e1m1` | 7,241,728 bytes | Low hunk: request 22,000; aligned block 22,016; 15,056 bytes available. | Map stops before `POSTMAP`. |
| `-mem 6.921875`, `e1m1` | 7,258,112 bytes | No allocation failure. After world-model loading, the hunk gap is 9,424 bytes. | Map completes; 40 `wait` commands complete and `meminfo` runs. |
| `-hipnotic -minmemory`, `hip1m1` | 6,619,136 bytes | Low hunk: request 129,772; aligned block 129,792; 47,168 bytes available. | Startup and video setup pass; map stops before `POSTMAP`. |
| `-rogue -minmemory`, `r1m1` | 6,619,136 bytes | Low hunk: request 141,172; aligned block 141,200; 63,328 bytes available. | Startup and video setup pass; map stops before `POSTMAP`. |

This brackets the observed `e1m1` transition within 16,384 bytes for this build
and DPMI setup; it is not a new minimum-memory requirement for other hosts or
maps. The successful low-memory run finished with low hunk use 3,343,232 bytes
(peak 3,538,032), high hunk use 2,693,824 bytes (peak 4,015,152), a gap of
1,221,056 bytes, and 957,248 cache bytes in 25 blocks. At the failing boundaries, the
allocator trace identifies the low hunk as the first exhausted pool; the
remaining gap is smaller than that allocation's aligned block.

The standard startup minimum (`5,570,560` bytes) and registered-data startup
minimum (`6,619,136` bytes) describe startup and video setup only. They do not
guarantee that a selected map will load. The diagnostic logs and run manifests
were captured under `benchmarks/out/memory-maptrace-20261117-125228/`; the
registered-data runs used Hipnotic PAK SHA256
`62B83569BA975015535BE73407796CE0829EBCFA75A68FB29C67514649DC655F` and Rogue
PAK SHA256 `C3C40408F953E2DE99F241DD85BF7854B69F1AE264B4E55A5657EF2AB12201A7`.

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
