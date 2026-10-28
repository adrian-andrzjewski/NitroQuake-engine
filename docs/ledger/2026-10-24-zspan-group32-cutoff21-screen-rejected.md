# D_DrawZSpans 32-pixel group with cutoff 21 (2026-10-24)

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
| Screen, cutoff 21 | `out/dos-timedemo-20261024-045806/timedemo-result.json` | 61.233104 / 61.688698 / 61.233134 | 15.824773 / 15.707902 / 15.824765 | 15.785813333 | 969 / `1047377823` every run |

The pooled mean decreased by **0.039028000 FPS** (**0.2466%**); the second
run was a timing outlier at 61.688698 seconds. The other two runs were near
the control, but the complete pooled set remained negative. Exact frame and
framebuffer-checksum parity held, and the screen did not qualify this
candidate for a strict ISA audit.
