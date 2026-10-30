# RenderFace branchless edge magnitude rejected (2026-10-29)

Status: rejected after a negative three-run 320x200 parity screen; the sign-test branch and conditional `NEG` remain active.

The candidate replaced `testl`/`jg`/`negl` with `cltd`/`xorl %edx,%eax`/`subl %edx,%eax` in both regular and submodel surfedge loops of `R_RenderFace_asm486`. This computes `abs(surfedge)` using a sign mask and avoids the taken branch, while remaining within the i486 instruction set.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Strict control | `out/dos-timedemo-20261029-115044/timedemo-result.json` | 16.321754 / 16.321710 / 16.321705 | 0.000049 | 16.321723000 |
| Branchless magnitude parity screen | `out/dos-timedemo-20261029-150403/timedemo-result.json` | 16.317101 / 16.317105 / 16.317089 | 0.000016 | 16.317098333 |

The candidate was **0.004624667 FPS slower (−0.0283344%)**. Every run completed 969 frames with framebuffer checksum `1047377823`. The runner used `VisualParityOnly`; the strict ISA audit was skipped because the candidate mean was negative.

## Disposition

The branchless sequence was removed from both loops. No strict recheck or ISA audit was run after the negative parity screen.
