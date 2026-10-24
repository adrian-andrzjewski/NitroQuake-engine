# D_DrawZSpans nonnegative fast-path cutoff lowered to 19 (2026-10-24)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete i486 ISA audit.

The positive/add-step Z-span fast path now admits spans of 19 pixels, down from
20. The starting-depth and complete-endpoint proof still gates entry to the
sign-check-free grouped loop; shorter spans and any failed proof use the
general path. An earlier cutoff-19 attempt was rejected against an older source
tree after an isolated slow sample. This recheck used the current cutoff-20
build, including the newer grouped loop and endpoint guard.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, identical aggressive selectors, and three uninstrumented
runs. Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean time | Median FPS |
|---|---|---|---|---:|---:|
| Control, cutoff 20 | `out/dos-timedemo-20261024-150944/timedemo-result.json` | 61.021278 / 61.021296 / 61.021257 | 15.879707 / 15.879702 / 15.879713 | 15.879707008 | 15.879707 |
| Candidate, cutoff 19 | `out/dos-timedemo-20261024-153311/timedemo-result.json` | 61.019502 / 61.019478 / 61.019548 | 15.880169 / 15.880175 / 15.880157 | 15.880167025 | 15.880169 |

The candidate improved the mean by **0.000460017 FPS (+0.00289689%)**; each
candidate sample was faster than each control sample.

The complete strict i486 gate passed:

- 168 project objects and 276,017 instructions, with zero above-i486,
  unclassified, or exempt instructions.
- 314,314 linked instructions matched across 435 executable ranges, with zero
  opcode mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions, with zero exemptions.

Candidate source fingerprint:
`9FF5F4D382A1A88C288F98C2A9034A2B035F71082516BBAFB3DE9E9BC6221F7C`.
Candidate source-tree fingerprint:
`7774C471DEFBABE7222F6D5D9F4579F00EC31603B7D4F434CA2B4B155E22EA23`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-cutoff19-current-20261024 -NoBootstrap
```
