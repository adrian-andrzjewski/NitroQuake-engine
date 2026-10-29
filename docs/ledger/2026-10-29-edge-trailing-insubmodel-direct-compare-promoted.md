# `TrailingEdge` bmodel direct compare promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

`TrailingEdge` compares `st_insubmodel(%esi)` directly with zero before loading the patched `surfaces[1].st_next` pointer. The memory compare sets the branch flags; the intervening `movl` preserves them. This removes the register load and `testl` while keeping `LPatch0` immediately after the patched load.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Fresh strict control | `out/dos-timedemo-20261028-232413/timedemo-result.json` | 16.281858 / 16.281856 / 16.281845 | 0.000013 | 16.281853 |
| Candidate parity screen | `out/dos-timedemo-20261028-232849/timedemo-result.json` | 16.301329 / 16.301349 / 16.301346 | 0.000020 | 16.301341333 |
| Strict candidate | `out/dos-timedemo-20261028-235504/timedemo-result.json` | 16.301341 / 16.301350 / 16.301356 | 0.000015 | 16.301349 |

The strict candidate gained **0.019496 FPS (+0.1197407%)** over the fresh strict control. Every control, screen, and strict candidate run rendered 969 frames with framebuffer checksum `1047377823`.

## i486 proof

The complete executable gate passed with 314,224 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. Compact reports are retained under `out/local-edge-trailing-insubmodel-strict-20261029`.

The candidate source-tree fingerprint was `54275CD1B9052A7663FF8DADF83CDED2FA93B4305D6B5A9F9E18ADDADE87E0C6`.
