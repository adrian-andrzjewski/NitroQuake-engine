# Alias span hot-loop 16-byte alignment rejected (2026-10-29)

Status: rejected after a negative strict three-run 320x200 mean; the alignment directive was removed.

The experiment added `.p2align 4,,15` before `LDrawLoop` in `D_PolysetDrawSpans8`, aligning the repeated eight-pixel alias span body to a 16-byte boundary. The intent was to keep the hot entry on a 486 fetch/cache-line boundary without changing pixel operations.

## Matched 320x200 timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, 969 frames, and framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Alignment parity screen | `out/dos-timedemo-20261029-152621/timedemo-result.json` | 16.321756 / 16.321709 / 16.321710 | 0.000047 | 16.321725000 |
| Strict aligned candidate | `out/dos-timedemo-20261029-154216/timedemo-result.json` | 16.321720 / 16.321716 / 16.321698 | 0.000022 | 16.321711333 |

The parity screen was **0.000002000 FPS faster** (**+0.00001225%**), but the strict candidate was **0.000011667 FPS slower** (**−0.00007148%**) than control. The full i486 gate passed: 314,278 relocated executable instructions, 529 startup rows, and 9,207 provider instructions, with zero above-i486 instructions, unknown instructions, or exemptions. Every run retained exact frame and checksum parity.

## Disposition

The negative strict mean rejects the alignment despite the positive parity screen. The directive was removed; `LDrawLoop` retains its prior layout.
