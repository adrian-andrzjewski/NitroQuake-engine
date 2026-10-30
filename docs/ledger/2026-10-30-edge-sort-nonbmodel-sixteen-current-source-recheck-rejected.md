# `R_GenerateSpans` non-bmodel sixteen-comparison current-source recheck rejected (2026-10-30)

Status: rejected as no measurable gain. This rechecked the two-comparison
extension against the current source tree; the retained fourteen-comparison
`Lsortloopnb` path was restored afterward.

## Candidate

The candidate added two `st_next` advances, key comparisons, and signed
`jl LInsertAndExit` exits before the non-bmodel sort group's back-edge.
Comparison order and early exits stayed unchanged; the matching `PROFILE486`
counters and optional `EDGE_SCAN_PROBE_SORT` blocks were extended for both
comparisons. The control and candidate used identical selectors. Their
source-tree fingerprints were
`BFA0E1915D6AAB6A95DABA044EF27068093FEF9A5383F040B75B8B6A4CE78973` and
`B4D6DD66F8B50A049B8BBE7071CD0D0271201A366B1E3EC29FD4EE1D1ADE2F34`.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
CWSDPMI, `demo1`, and the aggressive selector profile. Each of the six
uninstrumented runs rendered 969 frames and ended with checksum `1047377823`.

| Variant | FPS samples | Spread | Median FPS | Mean FPS |
|---|---|---:|---:|---:|
| Fourteen-comparison control | 16.321754 / 16.321701 / 16.321723 | 0.000053 | 16.321723 | 16.321726000 |
| Sixteen-comparison candidate | 16.321763 / 16.321716 / 16.321706 | 0.000057 | 16.321716 | 16.321728333 |

The candidate mean was **+0.000002333 FPS (+0.0000143%)**. This is below both
sample spreads, so the timing does not establish an improvement. The candidate
was removed. No fixed-step frame-stream or PCX comparison was run for this
rejected candidate; only the pinned final checksum was verified.

## i486 gate and artifacts

The candidate passed the complete i486 gate: 314,345 relocated instructions,
529 startup code rows, and 9,207 CWSDPMI instructions, with zero above-i486,
unknown, or exempt instructions. Source proof covered 403 native and annotated
objects.

- Control: `out/dos-timedemo-20261030-111439/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261030-113228/timedemo-result.json`
- Candidate ISA report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`
