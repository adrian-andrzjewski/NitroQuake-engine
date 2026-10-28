# Reject leading-edge load-order swap (2026-10-26)

The candidate swapped the independent `st_spanstate` and `st_insubmodel`
loads at `LPatch2` in `R_GenerateSpans`, placing the `st_insubmodel` load
before its `TEST` to give the 486 pipeline an independent load between the
value fetch and use. The screen was essentially tied, so it was rechecked under
the strict i486 gate. The strict mean remained slightly negative.

## Parity screen

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned
32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Strict control | `out/dos-timedemo-20261026-150012` | 15.948144 / 15.948137 / 15.948150 | 15.948143667 |
| Parity screen | `out/dos-timedemo-20261026-163443` | 15.948142 / 15.948145 / 15.948142 | 15.948143 |
| Strict candidate | `out/dos-timedemo-20261026-165955` | 15.948151 / 15.948127 / 15.948152 | 15.948143333 |

Every run completed 969 frames with framebuffer checksum `1047377823`. The
strict candidate mean was **−0.000000334 FPS** against control. Its complete
i486 audit passed: 314,394 relocated instructions, 529 startup rows, 9,207
provider instructions, and zero above-i486, unknown, or exempt instructions.
The candidate source-tree fingerprint was
`00FBF3B08AB154C808F10F46709EB5F516A6B2A2D16AADF9897B8FB809AF9D27`. The
negative strict mean rejects the load swap, and the original order is restored.
