# `R_RenderFace` shared signed-edge address calculation promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

Both the regular and submodel surfedge loops keep the existing strict-positive branch and negate zero or negative indices. They now converge on one scaled edge-address `lea`. This removes the negative path's unconditional jump and duplicate `lea` without changing edge selection, address calculation, cache checks, or clipping behavior.

## Matched timedemo

The committed parent control was `1fbd49e`. All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed parent strict control | `out/dos-timedemo-20261029-013713/timedemo-result.json` | 16.304935 / 16.304928 / 16.304903 | 0.000032 | 16.304922 |
| Candidate parity screen | `out/dos-timedemo-20261029-015321/timedemo-result.json` | 16.309169 / 16.309180 / 16.309169 | 0.000011 | 16.309172667 |
| Strict candidate | `out/dos-timedemo-20261029-021822/timedemo-result.json` | 16.309184 / 16.309167 / 16.309180 | 0.000017 | 16.309177 |

The strict candidate gained **0.004255 FPS (+0.02609641%)** over the committed parent's strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. Both candidate runs used source-tree fingerprint `90A5C3C0FB15DB5D7C0232C7F551D6EA1E73E7295E745F454514446EB045869A` and the pinned profile hash above.

## i486 proof

The complete executable gate passed with 314,219 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
