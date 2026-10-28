# Span16 tail texel load before T endpoint pop rejected (2026-10-24)

Status: reverted after a three-run parity screen produced a lower pooled mean.

The candidate moved the independent first texel load in `LLastSegment` to the
gap between the T endpoint multiply and `fistpl tnext`. The tail endpoint
results and texture read were unchanged.

The control was the immediately preceding strict candidate. Both variants used
DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486 profile with
SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. All runs
completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS from mean duration |
| --- | --- | --- | ---: |
| Control | `D19EC7C86748FCCB2CF075CDC2CF3CF74CB1E9B85BCD1E8F4D0A8169F9CC4ABE` | 15.900777 / 15.900727 / 15.900733 | 15.900745740052 |
| Tail load overlap | `F1D1C8401F12D2FFC931C5293BE697A3B1B6458913DF447DCF1959556039EC83` | 15.900763 / 15.900736 / 15.900717 | 15.900738608179 |

The candidate mean regressed by **0.000007131873 FPS (-0.0000448%)**. Exact
frame and checksum parity held, but the negative mean rejects the schedule.
The candidate used `-VisualParityOnly`, so the renderer ISA audit was skipped;
no strict promotion run was made.

- Candidate result: `out/dos-timedemo-20261024-163954/timedemo-result.json`.
- Candidate executable: `out/visual-parity-profile-9eea9650c5c9c4f1/qbench.exe`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly -NoBootstrap
```
