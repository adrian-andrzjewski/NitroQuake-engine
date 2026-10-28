# Ten-pixel turbulent span loop screen rejected (2026-10-27)

The candidate added an opt-in ten-pixel main loop to `D_DrawTurbulent8Span`,
with the existing 8/4/2/1 tail schedule. It was rejected after a three-run
uninstrumented parity screen averaged below the promoted fourteen-pixel loop.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Result | FPS samples | Mean FPS |
|---|---|---|---:|
| Promoted fourteen-pixel control | `out/dos-timedemo-20261027-060739/timedemo-result.json` | 16.165754 / 16.165786 / 16.165774 | 16.165771333 |
| Ten-pixel parity screen | `out/dos-timedemo-20261027-062649/timedemo-result.json` | 16.165542 / 16.165549 / 16.165561 | 16.165550667 |

The candidate mean was **0.000220667 FPS lower (−0.0013649%)**. All candidate
runs rendered 969 frames and produced framebuffer checksum `1047377823`. The
candidate result is `visualParityOnly=true` and `isaAuditStatus=SKIPPED`; the
negative screen did not proceed to the strict ISA audit.

The source-tree fingerprints differ because the candidate selector and branch
were added for this screen. The fourteen-pixel preprocessor path was otherwise
unchanged from the control. The candidate branch and selector changes were
removed; the promoted fourteen-pixel implementation remains active.
