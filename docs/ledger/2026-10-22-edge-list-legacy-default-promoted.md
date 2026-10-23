# Retain legacy edge-list assembly as the i486 default

The legacy handwritten edge-list assembly is now the selected i486 default.
The replacement `EdgeListMaintenanceImplementation=asm` path remains
selectable, but the matched timedemo comparison was slower than legacy. This
corrects the default selector profile, which had been selecting the slower
replacement despite the measured result.

Both variants used source-tree fingerprint
`DB27F40690187D296BAB82BCB2BACFDB10BA309F34B3E5054BC7E22FE5E30689`, the same
pinned DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
`RenderFaceImplementation=asm`, and three uninstrumented `demo1` runs.
Every run rendered 969 frames with checksum `1047377823`.

| Variant | FPS samples | Mean |
|---|---|---:|
| Legacy handwritten assembly | 15.598456, 15.598468, 15.598469 | 15.598464333 |
| Replacement i486 assembly | 15.564262, 15.564259, 15.564253 | 15.564258 |

Legacy is **+0.034206333 FPS (+0.21977491%)** faster; every legacy sample beat
every replacement sample. Both variants passed the full linked strict i486
audit with zero above-i486 instructions, unknown opcodes, or exemptions. The
legacy build verified 313,327 linked instructions; the replacement build
verified 313,315. Both included the 529-instruction startup and 9,207-instruction
DPMI-provider proofs.

Artifacts:

- Legacy default: `out/dos-timedemo-20261022-023110/timedemo-result.json`
- Replacement assembly: `out/dos-timedemo-20261022-001256/timedemo-result.json`

The i486 assembly profile now selects `legacy`; its release flags omit
`ASM486_EDGE_LIST` and keep the original assembly in `src/r_edgea.s` active.
Explicit `asm` replacement and `c` reference selections remain available. The
small target-U schedule improvement remains promoted within the replacement
assembly itself, but does not outweigh the faster legacy route.
