# D_DrawZSpans negative-gradient fast-path cutoff 20 (2026-10-24)

Status: rejected at the three-run parity screen; the cutoff remains 22 pixels.

The candidate lowered the minimum span length for the negative-gradient
nonnegative fast path from 22 to 20 pixels. It used a parity-only build, so the
screen did not prove i486 compatibility.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, cutoff 22 | `out/dos-timedemo-20261024-092021/timedemo-result.json` | 61.232817 / 61.232836 / 61.232879 | 15.824847 / 15.824842 / 15.824831 | 15.824840668844 | 969 / `1047377823` every run |
| Screen, cutoff 20 | `out/dos-timedemo-20261024-093846/timedemo-result.json` | 61.232824 / 61.232847 / 61.232883 | 15.824846 / 15.824840 / 15.824830 | 15.824838773636 | 969 / `1047377823` every run |

The screen mean decreased by **0.000001895208 FPS**. Exact frame and checksum
parity held, but the negative mean rejects the lower cutoff before strict
validation. The source was restored to 22 pixels.

- Candidate source fingerprint: `169A499A1AD98BB9041E21F123B701B8C77BE983F0328A65AEB6FED30D5CDB88`.
- Candidate source tree fingerprint: `64784DF4C359CCC46FD65330A239F785DEB5715C2651A2142B0F5B8DF3DAA826`.
- Parity-only build: `out/visual-parity-profile-9eea9650c5c9c4f1/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly -NoBootstrap
```
