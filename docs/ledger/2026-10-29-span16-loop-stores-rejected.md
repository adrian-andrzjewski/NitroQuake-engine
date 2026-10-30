# Span16 compact loop stores rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; packed word stores remain active.

The `TextureSpanStores=loop` selector replaced the unrolled two-pixel word stores in each Span16 half with a compact per-byte `STOSB` loop. This reduced the loop body and code footprint but added a counter decrement and conditional branch per pixel and increased destination store operations.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict word-store control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| `TextureSpanStores=loop` parity screen | `out/dos-timedemo-20261029-144444/timedemo-result.json` | 15.676107 / 15.676115 / 15.676128 | 0.000021 | 15.676116667 |

The loop-store variant was **0.645606333 FPS slower (−3.9555%)**. Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the candidate mean was negative.

## Disposition

No source change was made. `TextureSpanStores=word` remains the default; no strict recheck or ISA audit was run after the large regression.
