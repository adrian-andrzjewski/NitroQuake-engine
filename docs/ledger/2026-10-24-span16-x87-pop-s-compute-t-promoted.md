# Span16 x87 T calculation after popping S (2026-10-24)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 executable gate.

After the S endpoint is computed into `ST(0)`, store it with `fistpl snext`.
That pop leaves the duplicated Z value at the top of the x87 stack and moves
the saved `t/z` value to `ST(2)`. `fmul %st(2),%st(0)` then computes T directly
into `ST(0)`, followed by `fistpl tnext`. This removes the remaining `FXCH` in
the full-width span endpoint calculation. Both pops leave the same
`1/z | t/z | s/z` stack for the following row setup.

The control is the immediately preceding committed Span16 endpoint schedule.
Both variants used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and three uninstrumented strict runs. Every run rendered 969
frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean duration |
|---|---|---|---|---:|
| Control | `out/dos-timedemo-20261024-131901/timedemo-result.json` | 61.118836 / 61.118947 / 61.118901 | 15.854360 / 15.854331 / 15.854343 | 15.854344311768 |
| Candidate | `out/dos-timedemo-20261024-135041/timedemo-result.json` | 61.058464 / 61.058475 / 61.058434 | 15.870036 / 15.870033 / 15.870044 | 15.870037289347 |

The mean improved by **0.015692977579 FPS (+0.09898219%)**. Each candidate
sample was faster than every control sample.

The complete strict i486 gate passed for the candidate:

- 168 project objects and 276,014 instructions; zero above-i486, unknown, or
  exempt instructions.
- 314,311 linked instructions matched across 435 executable ranges; zero opcode
  mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions; zero exemptions.

Candidate source fingerprint:
`F47D7D2890A17419F08C0B49D58A6A9261242B5A2B951175352ECFB75F202D78`.
Candidate source-tree fingerprint:
`B6430AE25FE9458C03B667DDA6061A4EB4C6F2C9C694AE7E71A5E5D3A06A6C33`.
Candidate executable SHA-256:
`396D0C6D584ECAE1DF14D93E94C2051CB94AEB0E0F9E84AEBBABC2F9CCB23215`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName span16-no-fxch-pop-st-t-txn-20261024 -NoBootstrap
```
