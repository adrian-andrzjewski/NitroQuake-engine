# `R_GenerateSpans` non-bmodel sort pair unroll promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete linked i486 ISA gate.

`Lsortloopnb` now advances and compares two active-surface nodes per back-edge. Each signed less-than check exits directly to `LInsertAndExit`; the back-edge runs only when both checked keys require continuing the search. This preserves the original ordering and signed comparison. The `PROFILE486` iteration counter and `EDGE_SCAN_PROBE_SORT` probe are duplicated at the second compare so their diagnostic counts remain per surface node.

## Matched timedemo

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and pinned profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed strict control | `out/dos-timedemo-20261029-041531/timedemo-result.json` | 16.318161 / 16.318171 / 16.318144 | 0.000027 | 16.318158667 |
| Candidate parity screen | `out/dos-timedemo-20261029-042237/timedemo-result.json` | 16.321043 / 16.321017 / 16.321006 | 0.000037 | 16.321022000 |
| Strict candidate | `out/dos-timedemo-20261029-044946/timedemo-result.json` | 16.321027 / 16.321013 / 16.321006 | 0.000021 | 16.321015333 |

The strict candidate gained **0.002856667 FPS (+0.01750606%)** over the committed strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. The candidate source-tree fingerprint was `EAE07C0EBF62630780302B6A5A6FF3AA9B525DA311952F5AC4C58027EA7F7238`.

## i486 proof

The complete executable gate passed with 314,221 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions; there were zero above-i486, unknown, or exempt instructions. The run verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
