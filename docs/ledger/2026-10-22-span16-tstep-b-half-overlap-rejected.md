# Span16 B-half T-step/store overlap rejected (2026-10-22)

Status: rejected in `src/d_draw16.s`; the promoted first-store overlap remains
active.

The first-store T-step schedule was tested at B-half word stores 9, 11, and
13. Each next-pixel T-step addition was moved before its current word store;
the store and following byte load preserve carry for the later `sbb`. The
timedemo retained exact output parity, but the strict mean was negative, so all
three B-half moves were restored.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| B-half candidate, parity screen | `out/dos-timedemo-20261021-214156` | 15.564259 / 15.564251 / 15.564259 | 15.564256333 | 0.000008 |
| Active control, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |
| B-half candidate, strict | `out/dos-timedemo-20261021-220603` | 15.564258 / 15.564259 / 15.564254 | 15.564257000 | 0.000005 |

The parity-screen delta was **+0.000004667 FPS**, but the strict mean was
**−0.000003333 FPS (−0.00002142%)** against the active control. Every run
completed 969 frames with checksum `1047377823`. The strict candidate passed
the complete i486 audit: 313,315 relocated instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
moving the additions before stores 9, 11, and 13; the first-store move remains
promoted.

The audited B-half candidate executable SHA-256 is
`9174E42058AEF006316CCF467843A5B833810C02B63AB2DCDE61FFB33E4142C7`; its
source fingerprint is
`141B1E93B7F8FBFD6064E0DCF842AE945DE0C561AF21F7C8AA796F3C6E9A609D` and its
source-tree fingerprint is
`586C6CF874DCB943D1F2FBF908A39DC63D3075F35D42D66829DE026544D07EB3`.
