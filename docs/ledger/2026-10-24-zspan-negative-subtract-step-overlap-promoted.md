# D_DrawZSpans negative-depth step scheduling (2026-10-24)

Status: promoted for the i486 path after a positive strict three-run mean. The
i386 packing path retains its prior instruction order.

In `ZSPAN_SUB_NEGATIVE_PAIR`, the i486 sequence now advances the second
fixed-point sample between `SHLD` and `ROR`. `SHLD` has already copied the
needed next sample into the packed value in `%eax`; the following `ROR` only
reorders `%eax`, so the `%edx` step can execute in that slot. The i386 path
still uses `ZPACK16` followed by the original step.

Both builds used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, `testdata/id1`, and the pinned 32 MB DOSBox-X profile with
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Run FPS | Mean FPS | Frames/checksum |
|---|---|---|---:|---:|---|
| Fresh control, prior negative-depth schedule | `out/dos-timedemo-20261024-081949/timedemo-result.json` | 61.232822 / 61.232844 / 61.232912 | 15.824846 / 15.824840 / 15.824824 | 15.824836667 | 969 / `1047377823` every run |
| Candidate, step between `SHLD` and `ROR` | `out/dos-timedemo-20261024-084705/timedemo-result.json` | 61.232830 / 61.232859 / 61.232847 | 15.824844 / 15.824836 / 15.824840 | 15.824840000 | 969 / `1047377823` every run |

The candidate mean is **0.000003333 FPS higher** (**+0.00002106%**). The gain
is smaller than the run-to-run spread, but the matched three-run mean is
positive. The complete strict i486 gate passed: 314,158 linked instructions,
435 executable ranges, 529 startup rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. The same pinned profile
hash was used for both builds. Control source fingerprint:
`08DB7B35A3BFAD24027D3F784B747D9F1C6ED137D1BD370599E1531DC6A78BCE`; tree
fingerprint: `D0DABB836B3F8993DB869F4273E05509C5D28F18CBDA537B5F93FC5AFC84397E`.
Candidate source fingerprint:
`78287F38119693CB33FD155B7EFBA57447AEB765A5986EEA41858C919BBD5EB9`; tree
fingerprint: `92BDA5833ED6C5BF52131ED42A4E97D289AECDEF0C57F0B83AFB65F1B3CEC3E4`.

- Candidate strict build and audit reports:
  `out/local-zspan-negative-subtract-step-overlap-20261024/`.
- Pinned profile SHA-256:
  `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-negative-subtract-step-overlap-20261024 -NoBootstrap
```
