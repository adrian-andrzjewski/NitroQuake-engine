# D_DrawZSpans negative-gradient fast-path cutoff 24 (2026-10-24)

Status: rejected at the three-run parity screen; the cutoff remains 22 pixels.

The candidate raised the minimum span length for the negative-gradient
nonnegative fast path from 22 to 24 pixels. It used a parity-only build, so the
screen did not prove i486 compatibility.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, cutoff 22 | `out/dos-timedemo-20261024-092021/timedemo-result.json` | 61.232817 / 61.232836 / 61.232879 | 15.824847 / 15.824842 / 15.824831 | 15.824840668844 | 969 / `1047377823` every run |
| Screen, cutoff 24 | `out/dos-timedemo-20261024-094542/timedemo-result.json` | 61.232818 / 61.232858 / 61.232914 | 15.824847 / 15.824837 / 15.824823 | 15.824835672391 | 969 / `1047377823` every run |

The screen mean decreased by **0.000004996453 FPS**. Exact frame and checksum
parity held, but the negative mean rejects the higher cutoff before strict
validation. The source was restored to 22 pixels.

- Candidate source fingerprint: `CD2D06DCFC73CAF211684B0181E4FA4A48D07991FFAA38BBCA4304523B7B2AB3`.
- Candidate source tree fingerprint: `FE95AE2354B21955BC7EA72827E8DB27DC215BA5ED7F4D969BC71A7402BF1919`.
- Parity-only build: `out/visual-parity-profile-9eea9650c5c9c4f1/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly -NoBootstrap
```
