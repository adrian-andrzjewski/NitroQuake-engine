# D_DrawZSpans 32-pixel group with cutoff 20 (2026-10-24)

Status: rejected at the three-run parity screen; cutoff 22 was restored and no
strict run was started.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and parity-only timing. The
32-pixel branch-free loop was identical; only the minimum fast-path length
changed.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, cutoff 22 | `out/dos-timedemo-20261024-041142/timedemo-result.json` | 61.232868 / 61.232793 / 61.232859 | 15.824834 / 15.824854 / 15.824836 | 15.824841333 | 969 / `1047377823` every run |
| Screen, cutoff 20 | `out/dos-timedemo-20261024-044359/timedemo-result.json` | 61.233997 / 61.234011 / 61.234048 | 15.824543 / 15.824539 / 15.824530 | 15.824537333 | 969 / `1047377823` every run |

The screen mean decreased by **0.000304000 FPS** (**0.00192%**). Exact frame
and framebuffer-checksum parity held, but the negative screen did not qualify
this candidate for a strict ISA audit.
