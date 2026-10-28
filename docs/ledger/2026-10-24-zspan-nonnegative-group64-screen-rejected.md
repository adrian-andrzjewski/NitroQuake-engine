# D_DrawZSpans branch-free 64-pixel group (2026-10-24)

Status: rejected at the three-run parity screen; the committed 32-pixel group
was restored and no strict run was started.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and parity-only timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 32-pixel group | `out/dos-timedemo-20261024-041142/timedemo-result.json` | 61.232868 / 61.232793 / 61.232859 | 15.824834 / 15.824854 / 15.824836 | 15.824841333 | 969 / `1047377823` every run |
| Screen, 64-pixel group | `out/dos-timedemo-20261024-044848/timedemo-result.json` | 61.235294 / 61.235271 / 61.235295 | 15.824207 / 15.824213 / 15.824207 | 15.824209000 | 969 / `1047377823` every run |

The screen mean decreased by **0.000632333 FPS** (**0.00400%**). Exact frame
and framebuffer-checksum parity held, but the negative screen did not qualify
the 64-pixel group for a strict ISA audit.
