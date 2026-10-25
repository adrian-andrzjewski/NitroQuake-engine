# Mip-0 fully-flat rows use packed dword stores (2026-10-25)

Status: promoted assembly optimization in `src/surf8.s`.

`SURF8_MIP0_FULLY_FLAT_ROW` now forms four adjacent shaded texels in `%eax`
and stores each group with one `movl`. The existing `AL`/`AH` colormap lookup
order plus `rorl $16,%eax` preserves the four output bytes in framebuffer
order. The fully-flat helper uses `%dl` for its 16-row count after copying the
light index from `%dh` into `%bh` and `%ch`.

The diagnostic profile recorded 5,223 fully-flat mip-0 blocks and ranked
surface-cache drawing at 8.81% corrected self time. These figures motivated
the experiment; instrumented FPS is not used for the performance comparison.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same 159 build selectors.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261025-040605/timedemo-result.json` | 15.913954 / 15.913961 / 15.913955 | 15.913956667 | 15.913955 |
| Packed fully-flat rows | `out/dos-timedemo-20261025-043134/timedemo-result.json` | 15.919141 / 15.919214 / 15.919200 | 15.919185000 | 15.919200 |

The candidate mean is **+0.005228333 FPS (+0.03285376%)**. Every candidate
sample exceeded every control sample. All runs rendered 969 frames and
produced framebuffer checksum `1047377823`.

The strict linked i486 gate passed: 314,391 relocated instructions, 529
startup rows, and 9,207 provider instructions; no above-i486, unknown, or
exempt instructions. The candidate result records `isaAuditStatus: PASS`.
