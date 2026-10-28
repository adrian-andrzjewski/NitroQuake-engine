# Surface-cache style1 sentinel direct compare (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

On the cache-key path, compare `styles[1]` directly against the unused-style
sentinel (`255`). Load the byte into `%eax` only when it is not the sentinel
and is needed to index `d_lightstylevalue`. This avoids loading the index on
the sentinel path while preserving the active-style lookup.

## Matched timedemo

Both variants used `demo1`, DOSBox-X 2026.08.31, the aggressive optimization
profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every run completed 969 frames with framebuffer checksum `1047377823` and
matching renderer event traces.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Strict control | `out/dos-timedemo-20261028-190329/timedemo-result.json` | 16.241101 / 16.241141 / 16.241140 | 16.241127333 | 16.241140 |
| Direct style1 sentinel compare | `out/dos-timedemo-20261028-193608/timedemo-result.json` | 16.241473 / 16.241484 / 16.241490 | 16.241482333 | 16.241484 |

The candidate gained **0.000355 FPS (+0.00218581%) by mean**. All three
candidate samples exceeded all three control samples.

## i486 audit

The strict result has `visualParityOnly=false` and `isaAuditStatus=PASS`. The
complete gate verified 314,224 relocated instructions, 529 startup code rows,
and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt
instructions. The source map verified 403 exact object proofs and 435
source-bound contributions across 2,376 CODE ranges and 35 DATA ranges.

- Source fingerprint: `FA4166FCFCEF07B5A52920954F78DDDF9CFA44D7089EE5AAD85716A54662D7AF`
- Source-tree fingerprint: `2F4B56E075B701C0ADDDDB4CC9C6D2098C713EEEC236FA1EA5D77A636CE8A75E`
- Build manifest SHA-256: `393130E3728281A0120A2B58E85DE95633D30DD64355C387CB3CD72749D62CDC`
- Executable SHA-256: `C4B4AA8CC11069129D8618F9B0F7C404705A9CDC46388B9020BC1D1C181FA60B`
- Linked report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`
- Final strict report: `out/profile-107ff6406936b458/isa-qbench/relocated-20261028-203014320/strict-isa.json`
