# Mip-0 flat surface helpers tail-jump to block completion (2026-10-25)

Status: promoted in `src/renderer/surf8.s` after exact parity and a positive strict i486 mean.

The mip-0 horizontal-flat and fully-flat paths are entered only from their
local caller. They now jump directly to each helper instead of using `call`;
after drawing all 16 rows and balancing the horizontal helper's stack counter,
each helper jumps to `LSurfaceBlockMip0Done`. This removes the call/return stack
traffic and the caller's post-call jump from both paths without changing their
pixel loops or the shared block-completion work.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same aggressive assembly selectors.
Every run rendered 969 frames and produced framebuffer checksum `1047377823`.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261025-112826/timedemo-result.json` | 15.921188 / 15.921191 / 15.921193 | 15.921190667 | 15.921191 |
| Tail-jump helpers | `out/dos-timedemo-20261025-122438/timedemo-result.json` | 15.921221 / 15.921222 / 15.921246 | 15.921229667 | 15.921222 |

The candidate mean increased by **0.000039000 FPS (0.00024496%)**. The
parity-only screen also passed, with samples 15.921222 / 15.921249 / 15.921248
FPS and checksum `1047377823` on every run.

The complete strict i486 gate passed: 276,083 candidate object instructions,
314,380 linked instructions, 529 startup code rows, and 9,207 provider
instructions; no above-i486, unknown, or exempt instructions. Final mapping
covered 435 source-bound contributions. The result records
`visualParityOnly: false` and `isaAuditStatus: PASS`.
