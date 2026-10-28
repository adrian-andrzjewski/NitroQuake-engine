# Promote the bottom-tested scan-edge span-clear loop

`R_ScanEdges_asm486` now checks for an empty span-clear range once, then clears
each surface and uses a bottom-tested conditional branch. This removes the
per-surface unconditional back-edge while preserving the zero-count case. The
strict three-run mean is positive, all candidate samples beat all controls,
framebuffer checksums match, and the complete i486 audit passed.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the same i486 assembly selector profile, including
`ScanEdgesImplementation=asm`. Runs were uninstrumented with per-frame FPS
collection disabled. All six runs rendered 969 frames with checksum
`1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Existing top-tested loop | 15.600949, 15.600939, 15.600941 | 15.600943 | 0.000010 |
| Bottom-tested loop | 15.601024, 15.601039, 15.601029 | 15.601030667 | 0.000015 |

The candidate gains **0.000087667 FPS (+0.00056193%)**. Every candidate sample
beats every control sample by at least **0.000075 FPS**, so the positive pooled
mean qualifies under the any-positive rule.

The complete strict i486 audit passed: 313,320 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-093238/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edge-clear-loop-bottom-test-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `E822DDF494B99330AB956F539966D953E44204F51B4464DA6C88D007976C215B`
