# RenderFace branchless surfedge magnitude (2026-10-20)

Status: rejected after six parity-screen samples; the original signed-edge
branch was restored in the working assembly source.

The candidate replaced the forward/reverse surfedge branch with a
two's-complement absolute-value sequence in both the regular and submodel edge
loops of `R_RenderFace_asm486`. It was measured against the immediately
preceding promoted build with DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. All runs completed 969 frames with framebuffer checksum
`1047377823`.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Prior promoted source, strict set | `out/dos-timedemo-20261020-213827/timedemo-result.json` | 15.536943 / 15.536991 / 15.536990 | 15.536974667 |
| Fresh control, parity screen | `out/dos-timedemo-20261020-220319/timedemo-result.json` | 15.536950 / 15.536991 / 15.536982 | 15.536974333 |
| Branchless candidate, parity screen 1 | `out/dos-timedemo-20261020-215837/timedemo-result.json` | 15.528918 / 15.538324 / 15.528924 | 15.532055333 |
| Branchless candidate, parity screen 2 | `out/dos-timedemo-20261020-220752/timedemo-result.json` | 15.528919 / 15.528932 / 15.528935 | 15.528928667 |

Across both candidate blocks, mean FPS was **15.530492** and median FPS was
**15.528928**, or **0.006482333 FPS slower (−0.041722%)** than the fresh
control. Five of six candidate samples were below every control sample; the
single higher sample accounts for the candidate's 0.009406 FPS spread. Exact
frame and checksum parity passed. Both screens explicitly skipped the renderer
ISA audit, and no strict run was made because the repeated result was slower.
The branchless sequence was removed; the promoted cache-offset reuse and
owner-compare fusion remain in the working source.
