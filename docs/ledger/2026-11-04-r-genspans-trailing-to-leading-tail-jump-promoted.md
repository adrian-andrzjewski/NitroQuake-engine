# R_GenerateSpans trailing-to-leading continuation tail-jump promoted (2026-11-04)

Status: promoted under the current any-positive pooled-mean rule. The measured
mean is strongly influenced by one slow control run; excluding that sample
leaves an effectively zero difference, so the causal effect size is uncertain.

## Change

At `Lgs_edgeloop`, the both-sides edge path still forms the leading surface
pointer before entering `TrailingEdge`. It now pushes `Lgs_leading_body` as the
helper's return address and jumps to `TrailingEdge`, replacing the direct call
and the following jump. `TrailingEdge` returns directly to the leading-edge
body. No labels or other fall-through paths moved.

This is separate from the 2026-10-29 parity failure: that candidate moved
`Lgs_nextedge` and changed the fall-through after leading-edge insertion. This
change leaves that layout intact and changes only the local call/jump handoff.

## Matched timing

Control and candidate used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, `demo1`,
320x200 output, `optimizationProfile=aggressive`, and the same `testdata/id1`
root. Timing was uninstrumented, with no concurrent DOSBox-X workload. The
source trees differed only in `src/r_edgea.s`.

| Variant | FPS samples | Mean FPS | Median FPS | Range |
|---|---|---:|---:|---:|
| Control | 16.365687 / 16.239810 / 16.365684 | 16.323727000 | 16.365684 | 0.125877 |
| Candidate | 16.365729 / 16.365663 / 16.365667 | 16.365686333 | 16.365667 | 0.000066 |

The pooled candidate mean is **+0.041959333 FPS (+0.257045%)**. The 16.239810
control sample took 59.668187 seconds, versus 59.209248 and 59.209258 seconds
for the other controls. Excluding that hitch for sensitivity, the remaining two
control runs average 16.365685500 FPS, only **0.000000833 FPS (+0.0000051%)**
below the candidate mean. The candidate median is 0.000017 FPS below the control
median. The positive pooled mean meets the current rule, but the size and cause
of the gain are unresolved.

An earlier candidate-only three-run result reported 16.495436 FPS but had no
matched control from that host interval; it is excluded from this comparison.

## Correctness and compatibility

All six timing runs rendered 969 frames and ended at checksum `1047377823`. The
control and candidate fixed-step replay checksum files were byte-identical
(SHA-256
`DD412F1963A97CF3DCE5167E413EE788F919F0E3AB015BE5D5137224EE590DA5`), and the
captured frame 695 PCX files were byte-identical (65,161 bytes,
SHA-256 `4F00A71AB1F11B53AFC83984D07A0CAA44F354245B029AC06471B7E97705642F`).
Both control and candidate strict linked i486 audits passed with zero reported
ISA violations or exemptions.

## Artifacts

- Control timing: `out/worktree-bsp-state-pack-20261103/out/dos-timedemo-20261104-065758/timedemo-result.json`
- Candidate timing: `out/worktree-edge-fastpath-census-20261104/out/dos-timedemo-20261104-070204/timedemo-result.json`
- Control parity: `out/worktree-bsp-state-pack-20261103/out/dos-timedemo-20261104-064004/runs/run-01/`
- Candidate parity: `out/worktree-edge-fastpath-census-20261104/out/dos-timedemo-20261104-065511/runs/run-01/`
- Earlier unmatched candidate-only timing (excluded): `out/worktree-edge-fastpath-census-20261104/out/dos-timedemo-20261104-041403/timedemo-result.json`
