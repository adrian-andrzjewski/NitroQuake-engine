# `R_GenerateSpans` non-bmodel sort thirty-two-way unroll rejected (2026-10-29)

Status: rejected after a neutral three-run 320x200 parity screen; the sixteen-way loop was restored.

The candidate added sixteen more comparisons to `Lsortloopnb` in `src/r_edgea.s`, checking thirty-two active-surface keys before the backedge instead of sixteen. Each comparison retained its immediate signed exit to `LInsertAndExit`, and the `PROFILE486` counter and `EDGE_SCAN_PROBE_SORT` probe remained at every comparison. The hypothesis was that fewer taken backedges would offset the larger instruction footprint.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Thirty-two-way parity screen | `out/dos-timedemo-20261029-142333/timedemo-result.json` | 16.321756 / 16.321701 / 16.321712 | 0.000055 | 16.321723000 |

The candidate mean exactly matched control, so it did not demonstrate a measurable improvement. Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the candidate was not promoted. The extra sixteen comparisons were removed.

## Disposition

`Lsortloopnb` remains unrolled sixteen comparisons per backedge. No strict recheck or ISA audit was run after the neutral parity screen.
