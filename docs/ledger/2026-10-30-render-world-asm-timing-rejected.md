# RenderWorld assembly selector timing rejected (2026-10-30)

## Comparison

`RenderWorldImplementation=c` and `RenderWorldImplementation=asm` were
benchmarked as the only selector difference. Both builds used the current
worktree and passed the complete strict i486 gate. The benchmark used DOSBox-X
2026.08.31, `cputype=486`, the pinned
`tools/dosbox-x-486-high.conf` profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, `-stdvid`, `testdata/id1`, 969 frames, and uninstrumented runs with
FPS statistics disabled. This is 320x200 only.

| Pair | C FPS | Assembly FPS | Assembly minus C |
|---:|---:|---:|---:|
| 1 | 16.329200 | 16.329120 | -0.000080 |
| 2 | 16.329204 | 16.329116 | -0.000088 |
| 3 | 16.329191 | 16.329107 | -0.000084 |
| **Mean** | **16.329198333** | **16.329114333** | **-0.000084 (-0.0005144%)** |

Assembly was slower in all three pairs. Both variants' run spreads were
0.000013 FPS. All six runs rendered 969 frames and reported final framebuffer
checksum `1047377823`. The three-pair negative mean rejects the assembly
selector; C remains the default.

## Audit and selector verification

The C build passed with 314,280 linked executable instructions, 529 startup
code rows, and 9,207 CWSDPMI provider instructions. The assembly build passed
with 314,332 linked executable instructions, 529 startup code rows, and 9,207
provider instructions. Both had zero above-i486, unknown, or exempt
instructions. Each build proved 168 source objects and 403 installed runtime
objects. The build manifests differ only at `renderWorldImplementation`.

Two earlier pilot invocations omitted the explicit C selector. The aggressive
profile therefore selected assembly for both binaries; those runs are not part
of the timing comparison. The later three pairs explicitly selected C and
assembly and reused the separately audited executables.

## Artifacts

- C build: `out/local-rworld-control-c-20261030-a/qbench.exe`
- Assembly build: `out/local-rworld-asm-20261030-a/qbench.exe`
- C runs: `out/dos-timedemo-20261030-043913/timedemo-result.json`, `out/dos-timedemo-20261030-044149/timedemo-result.json`, `out/dos-timedemo-20261030-044518/timedemo-result.json`
- Assembly runs: `out/dos-timedemo-20261030-044028/timedemo-result.json`, `out/dos-timedemo-20261030-044306/timedemo-result.json`, `out/dos-timedemo-20261030-044640/timedemo-result.json`
- Excluded pilots: `out/dos-timedemo-20261030-041008/timedemo-result.json` and `out/dos-timedemo-20261030-042359/timedemo-result.json`
