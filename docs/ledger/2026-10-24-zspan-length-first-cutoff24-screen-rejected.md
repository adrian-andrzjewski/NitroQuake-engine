# D_DrawZSpans length-first guard with cutoff 24 (2026-10-24)

Status: rejected at the three-run parity screen; no strict run was started.

Both screen variants used DOSBox-X 2026.08.31, the pinned 32 MB 486 profile
`out/dosbox-x-486-high-32mb-profile.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, identical aggressive i486 selectors, and parity-only timing.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, length-first cutoff 22 | `out/dos-timedemo-20261024-020035/timedemo-result.json` | 61.263773 / 61.263806 / 61.263777 | 15.816852 / 15.816843 / 15.816850 | 15.816848333 | 969 / `1047377823` every run |
| Screen, length-first cutoff 24 | `out/dos-timedemo-20261024-022819/timedemo-result.json` | 61.264029 / 61.264068 / 61.264034 | 15.816786 / 15.816775 / 15.816784 | 15.816781667 | 969 / `1047377823` every run |

The screen mean decreased by **0.000066667 FPS** (**0.00042%**). Exact frame
and framebuffer-checksum parity held, but the negative timing screen did not
qualify this candidate for the strict ISA audit. The committed cutoff 22 was
restored.
