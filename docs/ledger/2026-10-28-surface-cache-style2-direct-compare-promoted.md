# Surface-cache style2 sentinel direct compare (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

On the cache-key path, compare `styles[2]` directly against the unused-style
sentinel (`255`). Load the byte into `%eax` only when it is not the sentinel
and is needed to index `d_lightstylevalue`. This removes the zero-extension
from the sentinel path while preserving the active-style lookup.

## Matched timedemo

Both variants used `demo1`, DOSBox-X 2026.08.31, the aggressive optimization
profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823` and
matching renderer event traces.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Strict control | `out/dos-timedemo-20261028-182200/timedemo-result.json` | 16.241123 / 16.241128 / 16.241092 | 16.241114333 | 16.241123 |
| Direct style2 sentinel compare | `out/dos-timedemo-20261028-190329/timedemo-result.json` | 16.241101 / 16.241141 / 16.241140 | 16.241127333 | 16.241140 |

The candidate gained **0.000013 FPS (+0.00008004%) by mean**. The gain is
smaller than the observed run spread; it qualifies under the project's
positive-mean promotion rule.

## i486 audit

The strict result has `visualParityOnly=false` and `isaAuditStatus=PASS`. The
complete gate verified 314,224 relocated instructions, 529 startup code rows,
and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. The source map verified 403 exact object proofs and 435
source-bound contributions across 2,376 CODE ranges and 35 DATA ranges.

- Source fingerprint: `CFF20780D671048C0B8B6B25159C03B4DEF1833CA2F6BE442B1B8F92A46C4BF5`
- Source-tree fingerprint: `B14769FC6FEDCCC3F4C927AB7A05AD42095B3C8A519108B8886F413ED69E7992`
- Build manifest SHA-256: `3E7A65B59DCDB63E5AB3ADEE2E6950CE28F124B210AA0EFFD19CEBEF00864BF3`
- Executable SHA-256: `F8F200CA997FBCAF2216055A1A97F71EB4ABD1040A49073C93B509D95D692E92`
- Linked report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`
- Final strict report: `out/profile-107ff6406936b458/isa-qbench/relocated-20261028-195742765/strict-isa.json`
