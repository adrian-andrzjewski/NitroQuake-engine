# Mip-0 flat surface row counter in AH (2026-10-25)

Status: promoted assembly optimization in `src/surf8.s`.

The mip-0 horizontal-flat and fully-flat block helpers now keep their fixed
16-row count in `%ah`, using `decb` and the existing `jnz` loop. Their row
macros use `%al` for colormap results and leave `%ah` untouched. This removes
the per-helper stack push/pop and the memory decrement on every row.

The diagnostic profile ranked surface-cache drawing at 8.81% corrected self
time. Mip-0 block drawing accounted for 3.625479 seconds of its 6.240079-second
surface-block draw time; the profile recorded 7,159 horizontal-flat and 5,223
fully-flat mip-0 blocks. This profile guided candidate selection; its
instrumented FPS is not used for the performance comparison.

## Matched strict timedemo

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, three uninstrumented runs, and the same 159 build selectors.

| Variant | Result | FPS samples | Mean FPS | Median FPS |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261025-033823/timedemo-result.json` | 15.913892 / 15.913886 / 15.913890 | 15.913889333 | 15.913890 |
| `%ah` row counter | `out/dos-timedemo-20261025-040605/timedemo-result.json` | 15.913954 / 15.913961 / 15.913955 | 15.913956667 | 15.913955 |

The candidate mean is **+0.000067333 FPS (+0.00042311%)**. Every candidate
sample exceeded every control sample. All runs rendered 969 frames and
produced framebuffer checksum `1047377823`.

The strict linked i486 gate passed: 314,386 relocated instructions, 529 startup
rows, and 9,207 provider instructions; no above-i486, unknown, or exempt
instructions. The candidate result records `isaAuditStatus: PASS`.
