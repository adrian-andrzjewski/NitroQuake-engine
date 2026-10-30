# `R_GenerateSpans` surface-base-first load schedule rejected (2026-10-29)

Status: rejected after the strict three-run recheck; the original load order was restored.

The candidate moved `movl C(surfaces),%eax` before both `movzwl et_surfs` loads at `Lgs_edgeloop` in `src/r_edgea.s`. The experiment tested whether starting the independent global-base load earlier would hide its latency on the 486.

## Matched 320x200 timedemo

All variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Base-first parity screen | `out/dos-timedemo-20261029-140041/timedemo-result.json` | 16.321754 / 16.321692 / 16.321730 | 0.000062 | 16.321725333 |
| Base-first strict candidate | `out/dos-timedemo-20261029-141639/timedemo-result.json` | 16.321720 / 16.321724 / 16.321704 | 0.000020 | 16.321716000 |

The parity screen was **+0.000002333 FPS (+0.00001430%)** over control. The strict candidate was **−0.000007 FPS (−0.00004288%)** below control, so the screen gain did not survive remeasurement. Every run completed 969 frames with framebuffer checksum `1047377823`.

The complete executable i486 gate passed: 314,263 relocated instructions, 529 startup rows, and 9,207 provider instructions, with zero above-i486, unknown, or exempt instructions. The candidate was rejected and the original load order restored.

## Disposition

The retained schedule is:

```asm
movzwl  et_surfs(%ebx),%esi
movzwl  et_surfs+2(%ebx),%edi
movl    C(surfaces),%eax
```
