# Promote caching the edge-drawing `r_dspeeds` truth value

`R_EdgeDrawing_asm486` now keeps the `r_dspeeds` truth result in callee-saved
`EBX` for the rest of the synchronous edge-drawing pass. The CVar is read once
after `R_BeginEdgeFrame`; the world, scan, Z-enable, brush-entity, and sound
update calls do not change it. This removes three repeated helper calls and
their float-bit loads while retaining the same branch decisions.

## Matched timedemo

The current integer-truth helper control and cached-register candidate used
the same pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and i486 assembly selector profile. Both were uninstrumented with
per-frame FPS collection disabled. All six runs rendered 969 frames with
checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Integer-truth helper control | 15.598612, 15.598642, 15.598645 | 15.598633 | 0.000033 |
| Cached truth in `EBX` | 15.598746, 15.598730, 15.598740 | 15.598738667 | 0.000016 |

The candidate gains **+0.000105667 FPS (+0.00067741%)**. Every candidate
sample exceeds every control sample by at least 0.000085 FPS, so the positive
mean qualifies under the any-positive promotion rule.

The candidate passed the full linked strict i486 audit: 313,319 relocated
opcodes, 529 startup instructions, and 9,207 DPMI-provider instructions, with
zero above-i486 opcodes, unknown opcodes, or exemptions. Framebuffer checksum
and timedemo gates passed. `EdgeDrawingImplementation=asm` was already selected
in the i486 profile; this promotes the assembly schedule without changing
selector routing. Full live-frame visual acceptance for the edge-drawing
assembly path remains pending.

Artifacts:

- Control: `out/dos-timedemo-20261022-030124/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-033027/timedemo-result.json`
- Candidate build and ISA reports: `out/local-dos-timedemo-dspeeds-cache-20261022/`

Source-tree fingerprints:

- Control: `D020C6C230DC26ACBDD1DC0676AD47D76CBFDA7B4374FDCCA81FF09E0D020575`
- Candidate: `808865633E2841F1A8D31E41B07CD381AAEB6343A2CB95317941989FDA3FAE09`
