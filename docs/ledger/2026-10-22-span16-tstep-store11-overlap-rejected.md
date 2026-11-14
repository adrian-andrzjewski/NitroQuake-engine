# Span16 store 11 T-step overlap rejected (2026-10-22)

Status: rejected in `src/renderer/d_draw16.s`; the promoted first-store overlap remains
active.

The next-pixel T-step addition was moved from after the B-half word store at
offset 11 to immediately before it. The store and following byte load preserve
the carry for the later `sbb`, and exact timedemo output parity held. The
strict pooled mean was negative, so the original instruction order was
restored.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the pinned 32 MB i486
profile, and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Both
variants used `EdgeListMaintenanceImplementation=asm`; the only source change
between them was the store 11 T-step schedule.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active strict control | `out/dos-timedemo-20261022-001256` | 15.564262 / 15.564259 / 15.564253 | 15.564258 | 0.000009 |
| Store 11 candidate, strict | `out/dos-timedemo-20261022-005344` | 15.564254 / 15.564246 / 15.564261 | 15.564253667 | 0.000015 |

The pooled delta is **−0.000004333 FPS (−0.00002784%)**. Every run completed
969 frames with checksum `1047377823`. The candidate passed the full linked
i486 audit: 313,315 opcodes across 435 executable ranges, 529 startup rows,
and 9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions. The negative mean rejects moving this addition before store 11.
