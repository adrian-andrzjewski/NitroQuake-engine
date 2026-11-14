# Span16 A-half T-step/store overlap rejected (2026-10-21)

Status: rejected in `src/renderer/d_draw16.s`; the promoted first-store overlap remains
active.

The first-store T-step schedule was tested at the later A-half word stores 3
and 5. Both additions were moved ahead of their stores, relying on the store
and following byte load to preserve carry for the later `sbb`. The timedemo
retained exact output parity, but the strict mean was negative, so these two
moves were restored.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| A-half candidate, parity screen | `out/dos-timedemo-20261021-211302` | 15.564268 / 15.564260 / 15.564242 | 15.564256667 | 0.000026 |
| Active control, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |
| A-half candidate, strict | `out/dos-timedemo-20261021-213659` | 15.564256 / 15.564257 / 15.564265 | 15.564259333 | 0.000009 |

The parity-screen delta was **+0.000005000 FPS**, but the strict mean was
**−0.000001000 FPS (−0.00000643%)** against the active control. Every run
completed 969 frames with checksum `1047377823`. The strict candidate passed
the complete i486 audit: 313,315 relocated instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
moving the additions before stores 3 and 5; the first-store move remains
promoted.

The audited A-half candidate executable SHA-256 is
`DED38356A6E7998EA091B572FD746C5FE8AFAE9F231DA6BA8D68AE33C1F42EE4`; its
source fingerprint is
`A11E4091E371BC28532C47228B93556A7B9FCC2CCC95E69B1A935224FC20D5EA` and its
source-tree fingerprint is
`A1329E01296FE308CC85D0BED64CFD2EE432B34FCD23EDAFBD596127D953759A`.
