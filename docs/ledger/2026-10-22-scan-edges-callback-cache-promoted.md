# Promote caching the scanline callback in `ESI`

`R_ScanEdges_asm486` now loads `pdrawfunc` once into callee-saved `ESI` and
calls it directly on each scanline. The aligned span-buffer base is saved in
the local slot `-28(%ebp)` and read back only when a span flush resets
`span_p`. This removes the per-row global callback load while preserving the
span-buffer reset behavior.

## Matched timedemo

The control and candidate used the same pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and i486 assembly selector profile. Both were uninstrumented with
per-frame FPS collection disabled. All six runs rendered 969 frames with
checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Existing scan loop | 15.598746, 15.598730, 15.598740 | 15.598738667 | 0.000016 |
| Cached callback in `ESI` | 15.599831, 15.599815, 15.599823 | 15.599823 | 0.000016 |

The candidate gains **+0.001084333 FPS (+0.00695142%)**. Every candidate
sample exceeds every control sample by at least 0.001069 FPS, so the positive
mean qualifies under the any-positive promotion rule.

The candidate passed the full linked strict i486 audit: 313,319 relocated
opcodes, 529 startup instructions, and 9,207 DPMI-provider instructions, with
zero above-i486 opcodes, unknown opcodes, or exemptions. Exact framebuffer
checksum parity passed. `ScanEdgesImplementation=asm` was already selected in
the i486 profile; this promotes the schedule without changing selector
routing. Full live-frame visual acceptance for the scan-edge assembly path
remains pending.

Artifacts:

- Control: `out/dos-timedemo-20261022-033027/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-042420/timedemo-result.json`
- Candidate build and ISA reports: `out/local-dos-timedemo-scan-callback-cache-20261022/`

Source-tree fingerprints:

- Control: `808865633E2841F1A8D31E41B07CD381AAEB6343A2CB95317941989FDA3FAE09`
- Candidate: `202E705EF2E2F52A392F76BCDDCD597D14C2FAD656506AB0B542A10A5DF5EAB7`
