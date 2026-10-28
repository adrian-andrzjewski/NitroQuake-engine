# Alias scan no-turnover fallthrough layout rejected (2026-10-26)

Moved `LNoLeftEdgeTurnover` before the row packer so that path fell through to
`LScanLoop`, removing its per-row unconditional jump and adding one entry jump
per scan. The schedule preserved exact output and passed the full strict i486
gate, but its strict pooled mean was negative. The original layout is restored.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive selector
set, and the pinned i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Strict control | `out/dos-timedemo-20261026-044845` | 15.942841 / 15.942874 / 15.942874 | 15.942863000 | 0.000033 |
| Candidate parity screen | `out/dos-timedemo-20261026-053237` | 15.945395 / 15.945389 / 15.945390 | 15.945391333 | 0.000006 |
| Strict candidate | `out/dos-timedemo-20261026-055744` | 15.945393 / 15.824836 / 15.945402 | 15.905210333 | 0.120566 |

The strict candidate mean was **−0.037652667 FPS (−0.23617255%)** against
control. All nine runs rendered 969 frames with framebuffer checksum
`1047377823`. The complete strict i486 gate passed: 314,411 relocated
instructions, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. No independent cause was
established for the slow strict sample, so it remains in the pooled mean. The
candidate is rejected and was not committed.
