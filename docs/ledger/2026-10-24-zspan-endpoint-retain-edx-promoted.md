# D_DrawZSpans endpoint check keeps the start depth in `%edx` (2026-10-24)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete i486 ISA audit.

The nonnegative-span endpoint proof no longer copies the starting depth from
`%edx` to `%esi` and back. Its two-operand `imull %ebx,%eax` writes only
`%eax`, so `%edx` remains the original starting depth while the code computes
`(count - 1) * step` and checks the endpoint. Product overflow and a negative
endpoint branch directly to the existing general loop. The successful proof
falls through with `%edx` already holding the first sample.

The control and candidate used DOSBox-X 2026.08.31, the pinned 32 MB i486
profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, identical aggressive selectors, and three uninstrumented
runs. Every run rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean time | Median FPS |
|---|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261024-135041/timedemo-result.json` | 61.058464 / 61.058475 / 61.058434 | 15.870036 / 15.870033 / 15.870044 | 15.870037289 | 15.870036 |
| Candidate | `out/dos-timedemo-20261024-144418/timedemo-result.json` | 61.023524 / 61.023553 / 61.023569 | 15.879122 / 15.879115 / 15.879111 | 15.879115869 | 15.879115 |

The candidate improved the mean by **0.009078579 FPS (+0.05720578%)**; each
candidate sample was faster than each control sample.

The complete strict i486 gate passed:

- 168 project objects and 276,017 instructions, with zero above-i486,
  unclassified, or exempt instructions.
- 314,314 linked instructions matched across 435 executable ranges, with zero
  opcode mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions, with zero exemptions.

Candidate source fingerprint:
`3FDF165531F09707A16D1F4A99FB3BE9081A39527D10F4A98523E6C8F8D23D46`.
Candidate source-tree fingerprint:
`4ECC465407F83250110258C694FB103B4B3D4831C0A8A0629FF27A2E7F861FB1`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-endpoint-preserve-edx-20261024 -NoBootstrap
```
