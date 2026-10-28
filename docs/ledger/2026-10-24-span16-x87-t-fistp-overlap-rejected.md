# Reject delaying the Span16 T endpoint pop across integer setup (2026-10-24)

The assembly-only candidate issued the T endpoint multiply, then moved the
independent texel fetch, count update, adjustment loads, and first destination
store before `fistpl tnext` and the endpoint reloads. This was intended to let
integer work overlap the x87 result. It preserved the endpoint values and
framebuffer, but the matched strict mean was lower, so the committed order has
been restored.

Both variants used DOSBox-X 2026.08.31, the pinned i486 profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`demo1`, CWSDPMI, and three uninstrumented strict runs. Every run rendered 969
frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS from mean duration |
|---|---|---|---|---:|
| Control | `out/dos-timedemo-20261024-135041/timedemo-result.json` | 61.058464 / 61.058475 / 61.058434 | 15.870036 / 15.870033 / 15.870044 | 15.870037289347 |
| Candidate | `out/dos-timedemo-20261024-141624/timedemo-result.json` | 61.058498 / 61.058493 / 61.058461 | 15.870027 / 15.870028 / 15.870037 | 15.870030444909 |

The mean regressed by **0.000006844438 FPS (-0.00004313%)**. The complete strict
i486 gate passed, and all six runs retained exact frame and checksum parity.

Candidate source fingerprint:
`5BE9AAFCACB77BFB09767D760EA457020CCB52E0EB8AB4447C944E07338EE298`.
Candidate source-tree fingerprint:
`868E26CC19348C24B43DE25F5A15E3D3B63A6ED82EDE92E10273DFF9BB18B53E`.

Strict reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName span16-overlap-x87-t-fistp-20261024 -NoBootstrap
```
