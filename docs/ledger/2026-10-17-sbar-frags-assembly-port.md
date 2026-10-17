# Status-bar frag strip and sorter i486 assembly port (2026-10-17)

## Behavior and selector

`src/sbar_frags_asm.inc` now implements `Sbar_DrawFrags`, and
`src/sbar_sortfrags_asm.inc` implements its stable scoreboard sort. The current
assembly profile selects both through `SbarFragsImplementation=asm`; the
C-reference profile continues to select C. BENCH builds retain
`Sbar_DrawFrags_C` and `Sbar_SortFrags_C` as direct parity oracles.

The assembly preserves the source's player-slot collection order, signed frag
comparison, stable ties, four-player display cap, local-player brackets,
color expansion, and signed three-column number formatting. In deathmatch the
strip starts at the original fixed x coordinate; in cooperative play the
viewport offset uses the source's logical half-width calculation. Drawing
calls remain at the same C boundary.

## Direct C/assembly parity

`src/bench486_sbarfrags.h` compares sort output and ordered drawing events for
six cases: empty scoreboard, deathmatch self and zero frags, wide cooperative
ties with a blank name, signed extremes and the four-player cap, a narrow
centered viewport, and all 16 scoreboard slots with stable ties. All six passed
in the strict DOSBox-X BENCH run with the expected event counts `0, 7, 22, 20,
12, 20` and zero parity failures:

```text
out/dos-bench-20261017-050509/bench-result.json
```

## Strict i486 verification

The strict build passed source-object, linked-object, relocated executable,
startup and maintained CWSDPMI provider gates. The linked executable proof
verified 281,922 opcodes across 411 source-bound contributions, with zero
above-i486 or unknown instructions and zero data-site exemptions. Startup
verification covered 1,660 loaded bytes and 529 CODE rows; the provider proof
covered 9,207 instructions with zero exemptions. The final `qbench.exe` ran
all six parity cases successfully in DOSBox-X.

This focused BENCH run checks the frag implementation and its strict build. It
does not refresh full-scene framebuffer parity or FPS measurements.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | Runtime evidence |
| --- | --- | --- | --- |
| `src/sbar.c:Sbar_SortFrags` and `Sbar_DrawFrags` | `src/sbar_sortfrags_asm.inc:_Sbar_SortFrags_asm486` and `src/sbar_frags_asm.inc:_Sbar_DrawFrags_asm486` | Six exact C/assembly sort and draw-event cases | Strict i486 gates pass; all six DOSBox-X cases pass |

This ports the status bar's top frag strip and its sort helper. The scoreboard,
intermission and finale composition remain separate work; the overall
status-bar and renderer ports are still active.
