# Alias span deferred Z-store after colormap rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the original Z-store placement was restored.

The candidate moved the Z-buffer store after the colormap load while keeping each `LPatch` label immediately after its five-byte lookup instruction. This preserves the `D_Aff8Patch` displacement contract and tests whether delaying the write changes memory-store pressure on the 486.

## Matched 320x200 timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, 969 frames, and framebuffer checksum `1047377823`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Deferred Z-store parity screen | `out/dos-timedemo-20261029-155811/timedemo-result.json` | 16.321754 / 16.195342 / 16.321710 | 0.126412 | 16.279602000 |
| Fresh control parity recheck | `out/dos-timedemo-20261029-160319/timedemo-result.json` | 16.321712 / 16.321705 / 16.321726 | 0.000021 | 16.321714333 |

The candidate's all-sample mean was **0.042121 FPS slower** (**−0.2581%**) than the strict control. The later control block returned to the normal range, so the candidate's 16.195342 FPS sample appears isolated; it remains included in the mean. All runs retained exact frame and checksum parity. The strict ISA audit was skipped after the negative candidate mean.

## Disposition

The full candidate block is a measured loss with a wide spread and is not promoted. The Z-store was restored to its original position before the colormap lookup. A preceding invalid layout attempt, which broke the patch site, is separately documented in the runtime-patch constraint ledger.
