# Span16 packed stores after the final address ADC promoted (2026-10-21)

Status: promoted in `src/renderer/d_draw16.s` under the user's any-positive pooled-mean
rule.

In the default `ASM486_SPAN16_WORD_STORES` path, each `SPAN16_STORE_WORD` is
scheduled after the pair's final `adcl advancetable+4(,%ecx,4),%esi` for word
offsets 1, 3, 5, and 7 in the A half and 9, 11, and 13 in the B half. The store
does not alter flags, and the DDA updates and source addresses are unchanged.
All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Timing and parity

| Variant | Artifacts | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Strict control, 6 runs | `out/dos-timedemo-20261021-114126`, `out/dos-timedemo-20261021-115920` | 15.537299 / 15.537293 / 15.537299 / 15.423568 / 15.537285 / 15.537227 | 15.518328500 | 0.113731 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-123303` | 15.537284 / 15.537298 / 15.537285 | 15.537289000 | 0.000014 |
| Parity-screen control, 3 runs | `out/dos-timedemo-20261021-111154`, `out/dos-timedemo-20261021-111318` | 15.537301 / 15.537287 / 15.537293 | 15.537293667 | 0.000014 |
| Parity-screen candidate, 3 runs | `out/dos-timedemo-20261021-120454` | 15.537292 / 15.537300 / 15.537292 | 15.537294667 | 0.000008 |

The strict candidate mean is **+0.018960500 FPS (+0.12218%)** over the pooled
six-run strict control mean. The parity-screen mean is also positive by
**+0.000001000 FPS (+0.00000644%)**. The strict control pool includes a slow
15.423568 FPS sample, which remains in the mean as required. Against the first
clean three-run strict control block (`114126`) alone, the candidate mean is
**−0.000008 FPS**. The positive pooled result qualifies under the user's rule;
the recorded timing does not claim a resolved causal speedup.

All strict and parity-screen runs completed 969 frames with framebuffer
checksum `1047377823`. The strict candidate result is
`out/dos-timedemo-20261021-123303/timedemo-result.json`; it records
`isaAuditStatus=PASS`, profile hash
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and
source-tree fingerprint
`68248DECC4B2F0CE3FA29739E7530BC527ADED5B1A62F7C00FBFD21AA6483A93`.

## Strict i486 audit

The complete strict gate passed: 403 exact native/annotated object proofs,
313,315 linked instructions across 435 executable text ranges, zero above-i486,
unknown, or exempt instructions, and final mapping of 2,377 CODE ranges plus 35
DATA ranges. Startup proof covered 1,660 loaded bytes and 529 code rows; the
CWSDPMI provider audit verified 9,207 instructions with zero exemptions.
