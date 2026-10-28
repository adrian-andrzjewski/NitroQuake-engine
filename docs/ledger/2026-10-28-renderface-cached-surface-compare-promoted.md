# R_RenderFace cached surface compare (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

In the cached-edge path, replace the zero-extended 16-bit surface load and
32-bit test with one direct `cmpw $0,16(%edx)`. The branch and surface
selection are unchanged; `%eax` is overwritten before its next use. This
removes one instruction from the cached-edge surface check.

## Matched timedemo

Both variants used `demo1`, DOSBox-X 2026.08.31, the aggressive optimization
profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823` and
matching renderer event traces.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Strict control | `out/dos-timedemo-20261028-163106/timedemo-result.json` | 16.240105 / 16.240105 / 16.240118 | 16.240109333 | 16.240105 |
| Cached surface compare | `out/dos-timedemo-20261028-182200/timedemo-result.json` | 16.241123 / 16.241128 / 16.241092 | 16.241114333 | 16.241123 |

The candidate gained **0.001005 FPS (+0.006188%) by mean**. All three
candidate samples exceeded all three control samples.

## i486 audit

The strict result has `visualParityOnly=false` and `isaAuditStatus=PASS`. The
complete gate verified 314,224 relocated instructions, 529 startup code rows,
and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. The source map verified 403 exact object proofs and 435
source-bound contributions across 2,376 CODE ranges and 35 DATA ranges.

- Source fingerprint: `D0AF4CB96508B7FFEE5878A4DEC63D5F5D216A7F5A35D12C4C58BCE1307A32A2`
- Source-tree fingerprint: `22DBD23403A4D3B789F778F89FE8B5B98C8BA4989FCD10111F4DF32C1A2C36F6`
- Build manifest SHA-256: `D7F2FCB5748DDE378B31A925C3D0283DEAC3F22F1799E374A937FB10AD50DE64`
- Executable SHA-256: `CEE1FE179403A319BE9C51E1FFF6A6E2CF18B0961D12FCAE1C971724AC9D414F`
- Linked report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`
- Final strict report: `out/profile-107ff6406936b458/isa-qbench/relocated-20261028-191521306/strict-isa.json`
