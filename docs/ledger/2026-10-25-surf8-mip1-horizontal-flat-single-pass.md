# Mip-1 horizontal-flat blocks use a straight-line row body (2026-10-25)

Status: promoted assembly optimization in `src/surf8.s`.

`LSurf8Mip1HorizontalFlat` already emits its eight scanlines as unrolled row
bodies, but wrapped them in a stack counter initialized to one. The helper now
executes those eight bodies directly, removing the counter push, memory
decrement, conditional branch, and stack adjustment. The caller jumps
unconditionally after the helper, so it does not consume the loop's flags.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same 159 build selectors.

| Variant | Result | FPS samples | Spread | Mean FPS | Median FPS |
|---|---|---|---:|---:|---:|
| Control | `out/dos-timedemo-20261025-045607/timedemo-result.json` | 15.921083 / 15.921085 / 15.921073 | 0.000012 | 15.921080333 | 15.921083 |
| Straight-line mip-1 rows | `out/dos-timedemo-20261025-052211/timedemo-result.json` | 15.921197 / 15.921183 / 15.921183 | 0.000014 | 15.921187667 | 15.921183 |

The candidate mean is **+0.000107333 FPS (+0.000674159%)**. Every candidate
sample exceeded every control sample. All runs rendered 969 frames and
produced framebuffer checksum `1047377823`; the pinned profile and all 159
build selectors matched.

The complete strict i486 gate passed: 314,393 relocated instructions, 529
startup rows, and 9,207 provider instructions, with zero exemptions. It also
verified 403 exact object proofs and final mapping across 435 source-bound
contributions.
