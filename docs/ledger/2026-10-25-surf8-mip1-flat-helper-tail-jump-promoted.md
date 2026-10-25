# Mip-1 flat surface helpers tail-jump to block completion (2026-10-25)

Status: promoted in `src/surf8.s` after exact parity and a positive strict i486 mean.

The mip-1 fully-flat and horizontal-flat helpers have a single local caller.
Both paths now jump directly to their helper instead of using `call`; after
their eight unrolled rows, each helper jumps to `LSurfaceBlockMip1Done`. This
removes the call/return stack traffic and the caller's post-call jump while
leaving the texel, lighting, and row-address calculations unchanged. The
profile-backed source comment records 14,837 horizontal-flat blocks, of which
11,327 use the fully-flat helper.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and identical aggressive assembly
selectors. Every run rendered 969 frames and produced framebuffer checksum
`1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-122438/timedemo-result.json` | 15.921221 / 15.921222 / 15.921246 | 15.921229667 | 15.921222 |
| Tail-jump helpers | `out/dos-timedemo-20261025-125503/timedemo-result.json` | 15.921354 / 15.921352 / 15.921360 | 15.921355333 | 15.921354 |

The candidate mean increased by **0.000125666 FPS (0.0007893%)**. The
parity-only screen also passed, with samples 15.921344 / 15.921356 / 15.921350
FPS and checksum `1047377823` on every run.

The complete strict i486 gate passed: 276,080 candidate object instructions,
314,377 linked instructions, 529 startup code rows, and 9,207 provider
instructions; no above-i486, unknown, or exempt instructions. Final mapping
covered 435 source-bound contributions. The result records
`visualParityOnly: false` and `isaAuditStatus: PASS`.
