# Span16 store 3 T-step overlap rejected (2026-10-22)

Status: rejected in `src/d_draw16.s`; the promoted first-store overlap remains
active.

The next-pixel T-step addition was moved ahead of A-half word store 3 only.
The store and following source-byte load preserve carry for the later `sbb`,
and exact timedemo output parity held. The strict mean was negative, so the
addition was restored to its original position after the store.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| Store 3 candidate, parity screen | `out/dos-timedemo-20261021-221122` | 15.564256 / 15.564254 / 15.564243 | 15.564251000 | 0.000013 |
| Active control, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |
| Store 3 candidate, strict | `out/dos-timedemo-20261021-223524` | 15.564264 / 15.564251 / 15.564249 | 15.564254667 | 0.000015 |

The parity-screen delta was **−0.000000667 FPS**; the strict mean was
**−0.000005667 FPS (−0.00003641%)** against the active control. Every run
completed 969 frames with checksum `1047377823`. The strict candidate passed
the complete i486 audit: 313,315 relocated instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
the store 3 move; the first-store overlap remains promoted.

The audited candidate executable SHA-256 is
`BE3CCDB22192BB2A93CAC6BBC64638F2426FC8323EA2F9983B0F4A17D40AD08F`; its
source fingerprint is
`81FF38549A095B3E3581A14CEDE9477523176FF8738CA5DC2978F1B63720458B` and its
source-tree fingerprint is
`A21EB72F7B2DA6E4BD285D3360508C89652EA686CA314C1FF417541578976B9E`.
