# Span16 store 9 T-step overlap rejected (2026-10-22)

Status: rejected in `src/renderer/d_draw16.s`; the promoted first-store overlap remains
active.

The next-pixel T-step addition was moved ahead of B-half word store 9 only.
The store and following source-byte load preserve carry for the later `sbb`,
and exact timedemo output parity held. The strict mean was negative, so the
addition was restored to its original position after the store.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| Store 9 candidate, parity screen | `out/dos-timedemo-20261021-230944` | 15.564262 / 15.564254 / 15.564260 | 15.564258667 | 0.000008 |
| Active control, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |
| Store 9 candidate, strict | `out/dos-timedemo-20261021-233403` | 15.564260 / 15.564255 / 15.564251 | 15.564255333 | 0.000009 |

The parity-screen delta was **+0.000007000 FPS**, but the strict mean was
**−0.000005000 FPS (−0.00003212%)** against the active control. Every run
completed 969 frames with checksum `1047377823`. The strict candidate passed
the complete i486 audit: 313,315 relocated instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
the store 9 move; the first-store overlap remains promoted.

The audited candidate executable SHA-256 is
`6EA216E9BB6B2F45FB89B206139B9D9B14652AEEFA7450821424D5F158F07597`; its
source fingerprint is
`405058EE9AF2F9F0F95330DC6B37E38DCEFAE59DE864B78ED4439C9B973651F9` and its
source-tree fingerprint is
`7DDAEB41642AFB3BE82E77C61B8BFBAFE6C56AC8EACB5CFCD8DB200C8CEBE121`.
