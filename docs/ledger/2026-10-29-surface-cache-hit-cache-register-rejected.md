# Surface-cache hit pointer register retention rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the original cache-pointer spill and reload remain active.

The candidate retained the cached surface pointer in callee-saved `%ebx`, replacing the unconditional local stack spill and returning the register value on a hit. On key mismatch it saved the pointer to the existing local and restored the mip level from the function argument before rebuilding the cache. `R_DlightContributes` preserves `%ebx` under the i386 calling convention.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Cache-register parity screen | `out/dos-timedemo-20261029-145720/timedemo-result.json` | 16.322035 / 16.322075 / 16.196545 | 0.125530 | 16.280218333 |

The candidate mean was **0.041504667 FPS slower (−0.2543%)**. The first two runs were close to control; the third took 59.827576 seconds versus 59.367595 and 59.367449 seconds for the first two. All runs completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the pooled mean was negative. The outlier remains in the recorded mean.

## Disposition

The cache pointer's original stack-local schedule was restored. No strict recheck or ISA audit was run after the negative pooled parity screen.
