# Span16 store 5 T-step overlap rejected (2026-10-22)

Status: rejected in `src/d_draw16.s`; the promoted first-store overlap remains
active.

The next-pixel T-step addition was moved ahead of A-half word store 5 only.
The store and following source-byte load preserve carry for the later `sbb`,
and exact timedemo output parity held. The strict mean was negative, so the
addition was restored to its original position after the store.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| Store 5 candidate, parity screen | `out/dos-timedemo-20261021-224044` | 15.564266 / 15.564244 / 15.564255 | 15.564255000 | 0.000022 |
| Active control, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |
| Store 5 candidate, strict | `out/dos-timedemo-20261021-230441` | 15.564261 / 15.564255 / 15.564261 | 15.564259000 | 0.000006 |

The parity-screen delta was **+0.000003333 FPS**, but the strict mean was
**−0.000001333 FPS (−0.00000857%)** against the active control. Every run
completed 969 frames with checksum `1047377823`. The strict candidate passed
the complete i486 audit: 313,315 relocated instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
the store 5 move; the first-store overlap remains promoted.

The audited candidate executable SHA-256 is
`2BF0892989C489E3F1689C6ADF4D8D241854B13B2E8EAE3102EE7C5AD23FF6CD`; its
source fingerprint is
`E52ABD52F3D7DA266B65C123EA82EB1684D4DEF336040E8A927DFE0691677224` and its
source-tree fingerprint is
`76D9981E6D69ADB765DC16A0621A3E3C155FC27E156C8076D13095ED6427A7E6`.
