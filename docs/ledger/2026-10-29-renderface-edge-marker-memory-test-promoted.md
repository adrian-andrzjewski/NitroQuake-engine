# `R_RenderFace` cached-offset marker memory test promoted (2026-10-29)

Status: promoted after a positive strict three-run mean, exact frame and framebuffer-checksum parity, and the complete executable i486 ISA gate.

The regular edge loop tests the cached-offset high bit directly at `4(%ecx)`. It loads the offset into `%eax` only on the marked path that needs to mask and compare the frame value. The test mask and `je` condition remain unchanged. The earlier 2026-10-27 sign-test screen changed that condition and remains a separate rejected experiment.

## Matched timedemo

The committed parent control was `39cbd5afa97e`. All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486 selector profile, and the pinned 32 MB profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Committed parent strict control | `out/dos-timedemo-20261029-021822/timedemo-result.json` | 16.309184 / 16.309167 / 16.309180 | 0.000017 | 16.309177 |
| Candidate parity screen | `out/dos-timedemo-20261029-022555/timedemo-result.json` | 16.312507 / 16.312545 / 16.312544 | 0.000038 | 16.312532 |
| Strict candidate | `out/dos-timedemo-20261029-025046/timedemo-result.json` | 16.312509 / 16.312549 / 16.312500 | 0.000049 | 16.312519333 |

The strict candidate gained **0.003342333 FPS (+0.02049357%)** over the committed parent's strict control. Every run rendered 969 frames with framebuffer checksum `1047377823`. Both candidate runs used source-tree fingerprint `474DED49C6C293A134023B78F85287A3A86AAA2C435A291B0B24810387AF6DBB` and the pinned profile hash above.

## i486 proof

The complete executable gate passed with 314,219 relocated instructions, 529 startup code rows, and 9,207 DPMI provider instructions, with zero above-i486, unknown, or exempt instructions. It verified 403 exact native/annotated object proofs and mapped 435 source-bound contributions across 2,376 CODE ranges and 35 DATA ranges. The strict result records `isaAuditStatus=PASS` and `visualParityOnly=false`.
