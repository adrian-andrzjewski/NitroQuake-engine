# `R_RenderFace` near-z-only direct compare promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

`R_RenderFace` compares `C(r_nearzionly)` directly with zero, replacing the register load and `testl`; the value is only used by the branch to the near-z-only return.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Fresh strict control | `out/dos-timedemo-20261028-235504/timedemo-result.json` | 16.301341 / 16.301350 / 16.301356 | 0.000015 | 16.301349 |
| Candidate parity screen | `out/dos-timedemo-20261029-000240/timedemo-result.json` | 16.304300 / 16.304285 / 16.304280 | 0.000020 | 16.304288333 |
| Strict candidate | `out/dos-timedemo-20261029-002805/timedemo-result.json` | 16.304284 / 16.304281 / 16.304284 | 0.000003 | 16.304283 |

The strict candidate gained **0.002934 FPS (+0.0179985%)** over the fresh strict control. Every control, screen, and strict candidate run rendered 969 frames with framebuffer checksum `1047377823`.

## i486 proof

The complete executable gate passed with 314,223 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. Compact reports are retained under `out/local-renderface-nearzionly-directcmp-strict-20261029`.

The candidate source-tree fingerprint was `25CE8F34FDD61E9BA957091B6A5DE85684F6CB4889B8CEA3AED0CC61012408B1`.
