# D_DrawZSpans 24-pixel group (2026-10-24)

Status: rejected at the three-run parity screen. The committed 32-pixel group
is restored; no strict i486 audit was started.

The candidate changed the nonnegative Z-span main loop from 32 pixels per
branch to 24 pixels per branch (twelve packed pixel pairs), then used the
existing 16/8/4/2-pixel remainder path. Endpoint proof and per-pair arithmetic
were unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, and the pinned 32 MB profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 32-pixel group | `out/dos-timedemo-20261024-041142/timedemo-result.json` | 61.232868 / 61.232793 / 61.232859 | 15.824834 / 15.824854 / 15.824836 | 15.824841333 | 969 / `1047377823` every run |
| Screen, 24-pixel group | `out/dos-timedemo-20261024-050939/timedemo-result.json` | 61.289881 / 61.289882 / 61.289922 | 15.810113 / 15.810113 / 15.810104 | 15.810110000 | 969 / `1047377823` every run |

The candidate mean was **0.014731333 FPS slower** (**−0.09309%**). Every run
retained exact frame and framebuffer-checksum parity. The visual-parity-only
build skipped the i486 audit; the negative timing screen rejected the
candidate, so no strict run was started. Candidate source fingerprint:
`37D4541495D5201667F742839108814D3B23DF3DE57C644E2CCB7BC43E892D1D`.
