# D_DrawZSpans positive-gradient cutoff lowered to 21 pixels (2026-10-24)

Status: promoted after a positive strict three-run mean, exact framebuffer parity,
and the complete i486 ISA audit.

The positive-gradient `LZDraw` fast path now starts at 21 pixels instead of 22.
The existing signed-product overflow and nonnegative-endpoint checks prove that
all fixed-step samples stay nonnegative; spans that fail either check still use
the general sign-checking loop. This extends the proven fast path to one more
length without changing the depth calculation or stores.

Both variants used DOSBox-X 2026.08.31, the pinned 486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and three uninstrumented runs. Every run completed 969 frames
with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from recorded times | Spread |
|---|---|---|---|---:|---:|
| Control, cutoff 22 | `out/dos-timedemo-20261024-110240/timedemo-result.json` | 61.180945 / 61.180913 / 61.180887 | 15.838264 / 15.838273 / 15.838279 | 15.838272441662 | 0.000015014809 |
| Candidate, cutoff 21 | `out/dos-timedemo-20261024-112522/timedemo-result.json` | 61.179588 / 61.179649 / 61.179574 | 15.838616 / 15.838600 / 15.838620 | 15.838611921709 | 0.000019416530 |

The strict mean improved by **0.000339480047 FPS (+0.00214342%)**. Every
candidate sample exceeded every sample in the repeated control block.

An earlier strict control block, `out/dos-timedemo-20261024-105823`, contained
one isolated 61.641881-second run. Its frames, checksum, and ISA audit passed;
the same already-audited control executable was then rerun for the stable
three-sample comparison above. The original artifact is retained.

The candidate passed the complete strict i486 gate:

- 168 project objects and 276,016 instructions; zero above-i486, unknown, or
  exempt instructions.
- 314,313 linked instructions matched across 435 executable ranges; zero
  opcode mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions; zero exemptions.

Candidate source fingerprint:
`041997DB21EC1B87130A230BC99C120A694BDDFAB4A3A7656ED5BD88D62DA578`.
Candidate source-tree fingerprint:
`6520C75346DC831B1E7CB2346A21F933DBAE3D789416BA593B72DA62CD2440D9`.
Control source-tree fingerprint:
`69226FA48EC5FC10690900E38F9F589F7D233011010F843442FF9FCBDF45B12E`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-cutoff21-candidate-20261024 -NoBootstrap
```
