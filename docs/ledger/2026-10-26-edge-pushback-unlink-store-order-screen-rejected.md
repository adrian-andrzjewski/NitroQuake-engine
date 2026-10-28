# Edge pushback unlink-store order screen rejected (2026-10-26)

Swapping the two independent stores that unlink an edge before it is reinserted
in `R_StepActiveU` preserved the exact output, but the parity-only timing screen
was slightly negative. The candidate is reverted.

The screen used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive selector
set, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Current strict control | `out/dos-timedemo-20261026-044845` | 15.942841 / 15.942874 / 15.942874 | 15.942863000 | 0.000033 |
| Candidate parity screen | `out/dos-timedemo-20261026-050327` | 15.942849 / 15.942839 / 15.942830 | 15.942839333 | 0.000019 |

The candidate screen mean was **−0.000023667 FPS (−0.00014845%)** against
control. Each candidate run rendered 969 frames with framebuffer checksum
`1047377823`. This parity-only screen skipped the strict i486 ISA audit; the
negative mean rejects the reorder, so no strict candidate run or promotion
commit was made.
