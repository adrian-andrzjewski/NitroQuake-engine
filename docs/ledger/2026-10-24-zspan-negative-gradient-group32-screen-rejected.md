# D_DrawZSpans negative-gradient 32-pixel group (2026-10-24)

Status: rejected at the three-run parity screen; the guarded 16-pixel group
remains active.

The candidate changed only the negative-gradient nonnegative fast path from
16-pixel to 32-pixel main-loop groups. The screen used the same demo, i486
selector profile, and pinned DOSBox-X configuration as the strict control.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 16-pixel groups | `out/dos-timedemo-20261024-092021/timedemo-result.json` | 61.232817 / 61.232836 / 61.232879 | 15.824847 / 15.824842 / 15.824831 | 15.824840668844 | 969 / `1047377823` every run |
| Screen, 32-pixel groups | `out/dos-timedemo-20261024-092741/timedemo-result.json` | 61.232841 / 61.232857 / 61.232844 | 15.824841 / 15.824837 / 15.824840 | 15.824839807384 | 969 / `1047377823` every run |

The screen mean decreased by **0.000000861460 FPS**. Exact frame and checksum
parity held. The parity-only build explicitly skipped the ISA audit, and the
negative mean rejects the group-size change before strict validation. The
source was restored to 16-pixel groups.

- Candidate source fingerprint: `5B501AC07A1EAF49D14424F6DBA081F4FD4B77D04B6A0BD4D86834504E7006FE`.
- Candidate source tree fingerprint: `682F2D5C1B99204379EF89D1D0223D9930F9F559E77E2D485C6F305F71AA187A`.
- Parity-only build: `out/visual-parity-profile-9eea9650c5c9c4f1/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly -NoBootstrap
```
