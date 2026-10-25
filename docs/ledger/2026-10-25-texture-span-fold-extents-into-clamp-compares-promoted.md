# Texture-span clamp compares read extents directly (2026-10-25)

Status: promoted in `src/d_draw.s` after exact parity and a positive strict i486 mean.

In the full eight-pixel `D_DrawSpans8` path, the S and T clamp checks now
compare their accumulators directly against `bbextents` and `bbextentt` in
memory. This removes the two scratch-register loads that previously preceded
those comparisons. Clamp order, branch conditions, and the high-clamp paths are
unchanged.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and identical aggressive assembly
selectors. Every run rendered 969 frames and produced framebuffer checksum
`1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-125503/timedemo-result.json` | 15.921354 / 15.921352 / 15.921360 | 15.921355333 | 15.921354 |
| Direct extent compares | `out/dos-timedemo-20261025-132611/timedemo-result.json` | 15.921352 / 15.921356 / 15.921363 | 15.921357000 | 15.921356 |

The candidate mean increased by **0.000001667 FPS (0.00001047%)**. The
parity-only screen also passed, with samples 15.921364 / 15.921355 / 15.921354
FPS and checksum `1047377823` on every run.

The complete strict i486 gate passed: 276,090 candidate object instructions,
314,387 linked instructions, 529 startup code rows, and 9,207 provider
instructions; no above-i486, unknown, or exempt instructions. Final mapping
covered 435 source-bound contributions. The result records
`visualParityOnly: false` and `isaAuditStatus: PASS`.
