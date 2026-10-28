# D_DrawZSpans negative-depth pair step overlap rejected (2026-10-24)

Status: reverted after the strict three-run mean was lower than control.

The experiment moved the second fixed-point Z step in the i486
`ZSPAN_ADD_NEGATIVE_PAIR` path between `SHLD` and `ROR`, matching the schedule
already promoted for nonnegative pairs. The i386 `ZPACK16` order was left
unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, `testdata/id1`, and the pinned 32 MB profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS |
| --- | --- | --- | ---: |
| Control | `D0DABB836B3F8993DB869F4273E05509C5D28F18CBDA537B5F93FC5AFC84397E` | 15.824849 / 15.824840 / 15.824838 | 15.824842333 |
| Negative-depth step overlap | `B67719528969AF9876D16BEEB1460F1D366FF6259656D3168B47A20A4A56F018` | 15.824838 / 15.824835 / 15.824840 | 15.824837667 |

The initial candidate mean was **−0.000004667 FPS (−0.00002950%)**. Since that
delta was smaller than the observed spread, the already audited candidate was
re-run immediately after a fresh control set:

| Variant | Source tree fingerprint | Run FPS | Mean FPS |
| --- | --- | --- | ---: |
| Fresh control | `D0DABB836B3F8993DB869F4273E05509C5D28F18CBDA537B5F93FC5AFC84397E` | 15.824846 / 15.824840 / 15.824824 | 15.824836667 |
| Candidate repeat | `B67719528969AF9876D16BEEB1460F1D366FF6259656D3168B47A20A4A56F018` | 15.824836 / 15.824830 / 15.824831 | 15.824832333 |

The fresh paired recheck was **−0.000004334 FPS (−0.00002739%)**. Every run
retained exact parity, and the candidate had passed the complete strict i486
audit. The negative mean rejects the schedule; the source was restored and no
performance commit was made.

- Control result: `out/dos-timedemo-20261024-071331/timedemo-result.json`.
- Candidate result: `out/dos-timedemo-20261024-081450/timedemo-result.json`.
- Fresh control result: `out/dos-timedemo-20261024-081949/timedemo-result.json`.
- Candidate repeat result: `out/dos-timedemo-20261024-082358/timedemo-result.json`.
- Candidate source fingerprint:
  `772162898905847BBEB3AC13B80A675E4F2FB0E027F551F260F6296D8D7F43D5`.
- Candidate strict audit: 314,158 linked instructions across 435 executable
  ranges, 529 startup rows, and 9,207 provider instructions; zero above-i486,
  unknown, or exempt instructions.
- Candidate build and audit reports:
  `out/local-zspan-negative-depth-step-overlap-20261024/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-negative-depth-step-overlap-20261024 -NoBootstrap
```
