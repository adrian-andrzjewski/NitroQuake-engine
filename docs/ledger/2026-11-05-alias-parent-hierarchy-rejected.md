# Alias 8-by-8 parent-min hierarchy rejected (2026-11-05)

Status: rejected. The direct parent scan reduced cache-node lookups but increased
Z-buffer reads and was 0.06134% slower in matched release timing. Deriving parent
minima from the 4-by-4 cache avoided raw parent rescans but had too few parent
cache hits and increased total lookup work.

## Candidate

The accepted alias visibility test stores a lazy 16-bit minimum for each 4-by-4
screen cell. This experiment added a lazy 8-by-8 parent cell, with one 16-bit
minimum and one 8-bit epoch per parent (3 KB total). Projected bounds used a
parent when they covered a complete aligned 2-by-2 group of child cells and
retained 4-by-4 checks for the edges. The rejection condition and conservative
depth bound were unchanged.

Two parent-fill strategies were measured:

1. Scan the parent’s 64 Z-buffer values directly on a cache miss.
2. Derive the parent minimum from its four existing 4-by-4 child minima.

## Exact profile parity and work

The fresh 4-by-4 control is `out/dos-timedemo-20261105-125256`. The direct-scan
profile is `out/worktree-alias-hzb-parent-20261105/out/dos-timedemo-20261105-124834`;
the child-derived profile is
`out/worktree-alias-hzb-parent-20261105/out/dos-timedemo-20261105-131451`.
Each used the pinned i486 visual-parity profile, one fixed-step `demo1` replay,
per-frame color checksums, and `-zchecksums`. `fc /B` reported no differences
between each candidate and the control for either stream: all 970 color and Z
records matched. All three profiles counted 4,503 occlusion queries and 1,627
model culls and ended at framebuffer checksum `1047377823`.

| Variant | Cache-node checks | Parent checks | Parent misses | Z samples | Instrumented seconds |
| --- | ---: | ---: | ---: | ---: | ---: |
| 4-by-4 control | 36,938 | 0 | 0 | 567,600 | 132.403427 |
| Direct 8-by-8 scan | 20,505 | 6,318 | — | 616,288 | 132.437026 |
| Child-derived 8-by-8 | 45,172 | 6,318 | 6,167 | 605,872 | 132.471664 |

The direct scan reduced cache-node checks by 44.5%, but sampled 48,688 more Z
values than the control. The child-derived cache had only 151 parent hits and
increased cache-node checks by 22.3% while sampling 38,272 more Z values. Both
instrumented profiles were slower than the control; these measurements are
diagnostic, not release FPS results.

## Strict release timing

The release control is `out/dos-timedemo-20261105-123922`. The strict release
candidate is
`out/worktree-alias-hzb-parent-20261105/out/dos-timedemo-20261105-130854`.
Both used DOSBox-X 2026.08.31, the fixed 320-by-200 `demo1` workload, the same
pinned profile as the adjacent 4-by-4 result, and three uninstrumented runs.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| 4-by-4 control | 16.750392, 16.750453, 16.750447 | 16.750430667 |
| Direct 8-by-8 scan | 16.740127, 16.740170, 16.740169 | 16.740155333 |

The direct-scan hierarchy regressed by 0.010275333 FPS (-0.06134%). Each run
rendered 969 frames, ended at framebuffer checksum `1047377823`, and reported
the same timedemo event trace. The control passed its complete strict i486 gate
with 315,186 relocated instructions. The candidate passed with 315,218 relocated
instructions, 529 startup rows, and 9,207 provider instructions; both had zero
above-i486, unknown, or exempt instructions.

The child-derived strategy was screened out before release timing because its
profile had fewer parent hits than cache misses and increased both cache-node
checks and Z samples. It was not subjected to a release ISA audit. Neither
hierarchy variant is retained in the renderer.
