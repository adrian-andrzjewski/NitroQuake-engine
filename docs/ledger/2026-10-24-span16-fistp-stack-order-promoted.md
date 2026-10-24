# Span16 x87 endpoint stores in stack order (2026-10-24)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 executable gate.

In `LNotLastSegment`, the two multiplies leave the computed T endpoint in
`ST(0)` and S in `ST(1)`. The old sequence exchanged those values only to store
S first. Store `tnext` from `ST(0)` and then `snext` from `ST(0)` after the pop;
the integer reloads and all following endpoint clamps stay unchanged. This
removes one `FXCH` from every full-width span without changing either rounded
integer result.

Both variants used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and three uninstrumented strict runs. Every run rendered 969
frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean duration |
|---|---|---|---|---:|
| Control | `out/dos-timedemo-20261024-125558/timedemo-result.json` | 61.179569 / 61.179617 / 61.179640 | 15.838621 / 15.838608 / 15.838602 | 15.838610627269 |
| Candidate | `out/dos-timedemo-20261024-131901/timedemo-result.json` | 61.118836 / 61.118947 / 61.118901 | 15.854360 / 15.854331 / 15.854343 | 15.854344311768 |

The mean improved by **0.015733684499 FPS (+0.09933753%)**. Each candidate
sample was faster than every control sample.

The complete strict i486 gate passed for the candidate:

- 168 project objects and 276,014 instructions; zero above-i486, unknown, or
  exempt instructions.
- 314,311 linked instructions matched across 435 executable ranges; zero opcode
  mismatches, data exemptions, or unmatched instructions.
- 403 exact native/annotated object proofs, 529 startup rows, and 9,207 DPMI
  provider instructions; zero exemptions.

Candidate source fingerprint:
`67F6F0AC12182A12E60A849314882383C905BF4B700B518BF5D24B86D594B235`.
Candidate source-tree fingerprint:
`ACD4D39027088632AC3BC3EC6760668F3D47D39B67047878826912C61C559209`.
Candidate executable SHA-256:
`21138E1D18B2A13891F25494765B7EFBAE21BEE62DA3BF546496BB8C44AC240A`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName span16-fistp-order-txn-20261024 -NoBootstrap
```
