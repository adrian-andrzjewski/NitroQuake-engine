# Alias scan low-word counter decrement promoted (2026-10-26)

Status: promoted in `src/renderer/d_polysa.s` under the user's positive pooled-mean rule.

After packaging a row in `LScanLoop`, `%ecx` stores the scan fraction in its
high word and the remaining row count in its low word. Replacing the 32-bit
decrement plus low-word test (`decl %ecx; testl $0xFFFF,%ecx`) with
`decw %cx` removes one instruction. The last row's Bresenham update is dead,
so the existing early exit remains in place.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Control (`decl` + `testl`, parity screen) | `out/dos-timedemo-20261026-004645` | 15.935237 / 15.935234 / 15.935239 | 15.935236667 |
| Candidate (`decw`, parity screen) | `out/dos-timedemo-20261026-005110` | 15.942839 / 15.942879 / 15.942881 | 15.942866333 |
| Candidate strict i486 | `out/dos-timedemo-20261026-005503` | 15.942846 / 15.942847 / 15.942840 | 15.942844333 |

The matched three-run screen improved by **+0.007629667 FPS (+0.04790%)**.
The strict candidate passed the i486 ISA audit and all runs completed 969
frames with framebuffer checksum `1047377823`. Its source-tree fingerprint
was `4083E4EB3B822EE8B1CB9963B728E839068CDC8C7B315C11F42D67B27A4D8595`.
