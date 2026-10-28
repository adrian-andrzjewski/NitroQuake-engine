# D_DrawZSpans 32-pixel group with cutoff 23 (2026-10-24)

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
| Screen, cutoff 23 | `out/dos-timedemo-20261024-045333/timedemo-result.json` | 61.232830 / 61.232905 / 61.232867 | 15.824844 / 15.824825 / 15.824834 | 15.824834333 | 969 / `1047377823` every run |

The screen mean decreased by **0.000007000 FPS** (**0.000044%**). Exact frame
and framebuffer-checksum parity held, but the negative screen did not qualify
this candidate for a strict ISA audit.
