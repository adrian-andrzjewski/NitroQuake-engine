# `R_ClipSpriteFace` clip-current direct compare promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

`R_ClipSpriteFace_asm486` compares `clip_current` directly with zero before selecting the input and output buffers. This replaces a global load into `%eax` plus a register `test`; both arms overwrite `%eax` while forming the buffer pointers. The strict timedemo records `spriteClipImplementation=asm`.

## Matched timedemo

The current parent source had the same assembly as commit `63d74958829f`; the intervening `7ae21e47681b` commit only recorded a rejected experiment. All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed parent strict control | `out/dos-timedemo-20261029-025046/timedemo-result.json` | 16.312509 / 16.312549 / 16.312500 | 0.000049 | 16.312519333 |
| Candidate parity screen | `out/dos-timedemo-20261029-030418/timedemo-result.json` | 16.312510 / 16.312539 / 16.312555 | 0.000045 | 16.312534667 |
| Strict candidate | `out/dos-timedemo-20261029-032931/timedemo-result.json` | 16.312516 / 16.312559 / 16.312559 | 0.000043 | 16.312544667 |

The strict candidate gained **0.000025333 FPS (+0.00015530%)** over the committed parent's strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. Both candidate runs used source-tree fingerprint `A630A04BF3A82AF1B671E7981248420627B5432A5A6E08B9916E7A217628C751` and the pinned profile hash above.

## i486 proof

The complete executable gate passed with 314,218 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
