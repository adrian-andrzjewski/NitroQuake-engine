# D_DrawZSpans negative-gradient fast-path cutoff 18 (2026-10-24)

Status: rejected at the three-run parity screen; the cutoff remains 22 pixels.

The candidate lowered the minimum span length for the negative-gradient
nonnegative fast path from 22 to 18 pixels. It used a parity-only build, so the
screen did not prove i486 compatibility.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, cutoff 22 | `out/dos-timedemo-20261024-092021/timedemo-result.json` | 61.232817 / 61.232836 / 61.232879 | 15.824847 / 15.824842 / 15.824831 | 15.824840668844 | 969 / `1047377823` every run |
| Screen, cutoff 18 | `out/dos-timedemo-20261024-093304/timedemo-result.json` | 61.232839 / 61.232879 / 61.232857 | 15.824842 / 15.824831 / 15.824837 | 15.824836964577 | 969 / `1047377823` every run |

The screen mean decreased by **0.000003704266 FPS**. Exact frame and checksum
parity held, but the negative mean rejects the lower cutoff before strict
validation. The source was restored to 22 pixels.

- Candidate source fingerprint: `3CB04ACA5DAAA9A460B68E85685CA6E7501320BEDAD300EB786046C5F77610B1`.
- Candidate source tree fingerprint: `4B90C55A2649E9B9FCD6557A1917C8602502DE5A4CEBE0F6D52A9938347986A4`.
- Parity-only build: `out/visual-parity-profile-9eea9650c5c9c4f1/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly -NoBootstrap
```
