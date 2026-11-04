# RenderFace clip-plane argument hoist promoted (2026-11-04)

## Optimization

Status: retained after exact frame and captured-image parity, a complete strict
i486 audit, and a positive three-run uninstrumented mean.

`R_RenderFace_asm486` now writes the face's constant clip-plane pointer into
the reserved third `R_ClipEdge` argument slot once before the edge loops.
Regular and submodel edge clipping no longer reloads the pointer from the local
frame and stores it for every edge. Boundary-tail calls still replace all
three argument slots.

The control source fingerprint is
`B48AA70A67170A9978D234586F3A4C90E4F20AF44511CDCC6825A0CC9B346AC7`; the
candidate fingerprint is
`18AFCA2B8029544C4A7D390F3E96F058821E860A67D195A10DF013CBD979640D`.

## Matched timing

Both variants used DOSBox-X `2026.08.31`, profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and 969-frame uninstrumented runs. Each run selected
`RenderFaceImplementation=asm` and `SurfaceCacheImplementation=asm`; every
run ended at framebuffer checksum `1047377823`.

| Variant | Run artifacts | FPS samples | Mean FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261104-133514`, `...-133630`, `...-133754` | 16.378050 / 16.378045 / 16.378046 | 16.378047 |
| Candidate | `out/dos-timedemo-20261104-140654/timedemo-result.json` | 16.388054 / 16.388079 / 16.388071 | 16.388068 |

The candidate mean increased by **0.010021 FPS (+0.0611856%)**. Every candidate
sample exceeded every control sample.

## Correctness and compatibility

A fixed-step `host_framerate 0.0783` replay recorded 970 checksums with zero
overflow for each variant. The checksum streams were byte-identical with SHA-256
`3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B`; captured
frame 695 PCX files were byte-identical with SHA-256
`BC9A0C6E6FB6A4436DA9FDF59595385D475692B4B344DB0D8269D69D779555D5`.

The candidate passed the complete strict i486 executable gate: 314,630
relocated instructions, 529 startup rows, and 9,207 DPMI provider instructions;
zero above-i486, unknown, or exempt instructions.

## Artifacts

- Control timing runs: `out/dos-timedemo-20261104-133514`,
  `out/dos-timedemo-20261104-133630`, and
  `out/dos-timedemo-20261104-133754`.
- Candidate timing result: `out/dos-timedemo-20261104-140654/timedemo-result.json`.
- Fixed-step replay: `out/dos-timedemo-20261104-133254` (control) and
  `out/dos-timedemo-20261104-140446` (candidate).
- Strict candidate build: `out/local-local-renderface-cliparg-hoist-candidate-20261104/`.
- Source snapshots: `out/asm486-before-renderface-cliparg-hoist-20261104.s`
  and `out/asm486-renderface-cliparg-hoist-candidate-20261104.s`.
