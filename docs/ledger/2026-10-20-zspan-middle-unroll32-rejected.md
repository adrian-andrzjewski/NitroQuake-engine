# D_DrawZSpans 32-pixel middle-loop follow-up (2026-10-20)

Status: rejected after a three-run parity screen; the promoted 16-pixel
middle-loop grouping remains in the working assembly source.

The candidate doubled the main-loop group from sixteen to thirty-two pixels
for both positive and negative gradients, retaining the signed-depth handlers
for each pair and the existing remainder paths. It was screened against the
immediately preceding promoted build with DOSBox-X 2026.08.31, the pinned
32 MB 486 profile `out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. Both sets completed all 969 frames with framebuffer
checksum `1047377823`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS |
|---|---|---|---|---:|
| Current 16-pixel control, parity screen | `out/dos-timedemo-20261020-220319/timedemo-result.json` | 62.367454 / 62.367290 / 62.367326 | 15.536950 / 15.536991 / 15.536982 | 15.536974333 |
| 32-pixel grouping, parity screen | `out/dos-timedemo-20261020-221556/timedemo-result.json` | 62.378558 / 62.378716 / 62.378729 | 15.534184 / 15.534145 / 15.534142 | 15.534157000 |

The candidate averaged **0.002817333 FPS slower (−0.0181331%)**; all three
samples were below all control samples. Exact frame and checksum parity
passed. The visual-only screen skipped the renderer ISA audit, and the
measured slowdown rejected the candidate without a strict run. The
16-pixel implementation remains active.
