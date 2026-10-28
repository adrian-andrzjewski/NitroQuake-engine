# Edge pushback neighbor-link store order screen rejected (2026-10-26)

Swapping the two final neighbor-link stores in `R_StepActiveU`'s
`LPushBackFound` insertion sequence preserved the list updates and exact output,
but the parity-only timing screen was negative. The candidate is reverted.

The candidate screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive
selector set, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Current strict control | `out/dos-timedemo-20261026-044845` | 15.942841 / 15.942874 / 15.942874 | 15.942863000 | 0.000033 |
| Candidate parity screen | `out/dos-timedemo-20261026-045820` | 15.942836 / 15.823203 / 15.942873 | 15.902970667 | 0.119670 |

The parity-screen mean was **−0.039892333 FPS (−0.25022064%)** against the
current strict control. All candidate runs rendered 969 frames with framebuffer
checksum `1047377823`. This screen skipped the strict i486 ISA audit; because its
pooled mean was negative, no strict candidate run was started and this change
was rejected without a promotion commit.
