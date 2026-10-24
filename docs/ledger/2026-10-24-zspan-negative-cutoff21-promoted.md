# D_DrawZSpans negative-gradient cutoff lowered to 21 pixels (2026-10-24)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete i486 ISA audit.

The negative-gradient `LZDrawNeg` fast path now starts at 21 pixels instead of
22. The existing start and endpoint checks prove every subtract-step sample is
nonnegative, allowing this one-pixel-longer span to use the loop without a
per-pair sign test. The fixed-point depth calculation and stores are unchanged.

Both variants used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and three uninstrumented strict runs. Every run completed 969
frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from recorded times |
|---|---|---|---|---:|
| Control, negative cutoff 22 | `out/dos-timedemo-20261024-112522/timedemo-result.json` | 61.179588 / 61.179649 / 61.179574 | 15.838616 / 15.838600 / 15.838620 | 15.838611921704 |
| Candidate, negative cutoff 21 | `out/dos-timedemo-20261024-115553/timedemo-result.json` | 61.179580 / 61.179607 / 61.179589 | 15.838618 / 15.838611 / 15.838616 | 15.838614942055 |

The mean improved by **0.000003020350 FPS (+0.00001907%)**. The gain is below
the run-to-run spread; the positive pooled mean qualifies under the current
acceptance rule. One candidate sample was slower than the highest control
sample.

The candidate passed the complete strict i486 gate:

- 168 project objects and 276,016 instructions; zero above-i486, unknown, or
  exempt instructions.
- 314,313 linked instructions matched across 435 executable ranges; zero opcode
  mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions; zero exemptions.

Candidate source fingerprint:
`437578CA6963F943D5B7FDF2E29BF0038A6F36116EFEBB765C081B122E33A52B`.
Candidate source-tree fingerprint:
`3B45CA95DA510D614B7864E3DED7042C4A294A2868C5CB923C6DC814F424E648`.
Control source-tree fingerprint:
`6520C75346DC831B1E7CB2346A21F933DBAE3D789416BA593B72DA62CD2440D9`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-negative-cutoff21-candidate-20261024 -NoBootstrap
```
