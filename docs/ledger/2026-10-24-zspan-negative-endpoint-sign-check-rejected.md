# D_DrawZSpans negative-gradient endpoint sign-check removal (2026-10-24)

Status: rejected after a slower strict three-run mean. The endpoint low-word
sign check remains in the assembly source.

The candidate removed `testl %eax,%eax` and its `js` branch after the negative
gradient endpoint proof had confirmed a zero high word. The existing range
reasoning suggested the low word could not be negative when the endpoint was
no greater than the nonnegative start. The timedemo result did not support
keeping the change.

Both variants used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and three uninstrumented strict runs. Every run completed 969
frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from recorded times |
|---|---|---|---|---:|
| Control, sign check retained | `out/dos-timedemo-20261024-115553/timedemo-result.json` | 61.179580 / 61.179607 / 61.179589 | 15.838618 / 15.838611 / 15.838616 | 15.838614942055 |
| Candidate, sign check removed | `out/dos-timedemo-20261024-122941/timedemo-result.json` | 61.179589 / 61.179652 / 61.179597 | 15.838616 / 15.838599 / 15.838614 | 15.838609591720 |

The candidate mean decreased by **0.000005350334 FPS (−0.00003378%)**. Exact
frame and checksum parity held, and the candidate passed the complete strict
i486 ISA gate, but the negative mean rejects the change. The original test and
branch were restored.

The candidate audited 168 project objects / 276,018 instructions, 314,315
linked instructions across 435 executable ranges, 529 startup rows, and 9,207
DPMI provider instructions, with zero above-i486 instructions or exemptions.
Candidate source fingerprint:
`869359371A0D4414A554B89512D066AB8ED81CC6583A7E345055E234B6AAF19B`.
Candidate source-tree fingerprint:
`193E8921DCADDCB74836D85DE5D442032A6754FD95D2C9BDD2BD4AE4752FF02D`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-negative-endpoint-sign-candidate-20261024 -NoBootstrap
```
