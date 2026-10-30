# Span16 T-adjust load between endpoint FISTPs rejected (2026-10-29)

Status: rejected after the parity screen's small positive mean became negative in the strict three-run comparison; the original load order was restored.

The candidate moved only `movl C(tadjust),%ecx` from after the first texel fetch to between `fistpl snext` and the T-endpoint multiply/FISTP in `LNotLastSegment`. It was intended to overlap an independent integer load with x87 endpoint work without changing either endpoint result or the FPU stack.

## Matched 320x200 timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, 969 frames, and framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict promoted control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Fresh control recheck | `out/dos-timedemo-20261029-160319/timedemo-result.json` | 16.321712 / 16.321705 / 16.321726 | 0.000021 | 16.321714333 |
| T-adjust parity screen | `out/dos-timedemo-20261029-161107/timedemo-result.json` | 16.321717 / 16.321717 / 16.321719 | 0.000002 | 16.321717667 |
| Strict T-adjust candidate | `out/dos-timedemo-20261029-162721/timedemo-result.json` | 16.321724 / 16.321695 / 16.321719 | 0.000029 | 16.321712667 |

The parity screen was **0.000003333 FPS faster** (**+0.00002042%**) than the fresh control recheck. The strict candidate was **0.000001667 FPS slower** (**−0.00001021%**) than that recheck and **0.000010333 FPS slower** than the original strict control. The complete executable, startup, and provider i486 audits passed with zero above-i486, unknown, or exempt instructions. All runs retained exact frame and checksum parity.

## Disposition

The negative strict mean rejects the load movement despite its positive parity screen. The original `tadjust` load position remains active.
