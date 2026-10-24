# D_DrawZSpans positive-gradient endpoint overflow guard (2026-10-24)

Status: promoted after a positive strict three-run mean, exact checksum parity,
and the complete i486 ISA audit.

The i486 long-span positive-gradient path in `LZDraw` previously used a
64-bit product followed by an add/carry chain and high-word checks to prove
that every depth sample remained nonnegative. It now uses a signed 32-bit
multiply, falls back if the product overflows, adds the starting depth, and
falls back if the endpoint is negative. A product outside the signed range
cannot be brought back to a valid endpoint by the nonnegative starting depth;
all uncertain cases retain the original per-pair sign-checking loop.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, 64-bit endpoint proof | `out/dos-timedemo-20261024-092021/timedemo-result.json` | 61.232817 / 61.232836 / 61.232879 | 15.824847 / 15.824842 / 15.824831 | 15.824840668844 | 969 / `1047377823` every run |
| Candidate, parity screen | `out/dos-timedemo-20261024-095237/timedemo-result.json` | 61.180934 / 61.180887 / 61.180976 | 15.838267 / 15.838280 / 15.838256 | 15.838267954476 | 969 / `1047377823` every run |
| Candidate, strict audited | `out/dos-timedemo-20261024-101516/timedemo-result.json` | 61.180931 / 61.180882 / 61.180939 | 15.838268 / 15.838281 / 15.838266 | 15.838271837615 | 969 / `1047377823` every run |

The strict mean improved by **0.013431168771 FPS (+0.08487396%)** over
control. The parity screen skipped the ISA audit; the strict candidate passed
the full audit and exact parity gates:

- project-source proof: 168 objects and 276,016 instructions;
- linked input to executable audit: 314,313 instructions matched across 435
  executable ranges, with zero above-i486, unknown, exempt, or unmatched
  instructions;
- runtime proof: 403 exact native/annotated object proofs, plus 529 startup
  rows and 9,207 DPMI-provider instructions, with zero exemptions.

The candidate uses the pinned DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

- Candidate source fingerprint:
  `A43F104CE267B2E8BC08CAD2A43E3854D3F057609A0D798555202629B1B0CCA3`.
- Candidate source tree fingerprint:
  `69226FA48EC5FC10690900E38F9F589F7D233011010F843442FF9FCBDF45B12E`.
- Strict build executable: `out/profile-9eea9650c5c9c4f1/qbench.exe`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -NoBootstrap
```
