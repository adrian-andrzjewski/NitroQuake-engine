# D_DrawZSpans nonnegative fast-path cutoff lowered to 20 (2026-10-24)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete i486 ISA audit.

The positive/add-step Z-span fast path now admits spans of 20 pixels, down from
21. The starting-depth and complete-endpoint proof still gates entry to the
sign-check-free grouped loop; short spans and any failed proof use the general
path. This recheck was measured against the current cutoff-21 build, after the
32-pixel loop and endpoint-guard optimizations had changed the costs from the
earlier cutoff-20 experiment.

Both variants used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, identical aggressive selectors, and three uninstrumented
runs. Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean time | Median FPS |
|---|---|---|---|---:|---:|
| Control, cutoff 21 | `out/dos-timedemo-20261024-144418/timedemo-result.json` | 61.023524 / 61.023553 / 61.023569 | 15.879122 / 15.879115 / 15.879111 | 15.879115869 | 15.879115 |
| Candidate, cutoff 20 | `out/dos-timedemo-20261024-150944/timedemo-result.json` | 61.021278 / 61.021296 / 61.021257 | 15.879707 / 15.879702 / 15.879713 | 15.879707008 | 15.879707 |

The candidate improved the mean by **0.000591139 FPS (+0.00372275%)**; each
candidate sample was faster than each control sample.

The complete strict i486 gate passed:

- 168 project objects and 276,017 instructions, with zero above-i486,
  unclassified, or exempt instructions.
- 314,314 linked instructions matched across 435 executable ranges, with zero
  opcode mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions, with zero exemptions.

Candidate source fingerprint:
`E017774C9D844E23DBAE0281B4D81F09F4B5FC8975358E76813332B460DF2233`.
Candidate source-tree fingerprint:
`3FDC3E6D1C18933170958019C0027195CC1D627E058C4FFE46A056043FE5A9ED`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-cutoff20-current-20261024 -NoBootstrap
```
