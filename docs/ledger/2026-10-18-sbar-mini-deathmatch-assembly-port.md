# Widescreen mini-deathmatch scoreboard i486 assembly port (2026-10-18)

## Behavior and selector

`Sbar_MiniDeathmatchOverlay` draws the compact deathmatch list on wide status
bars. `src/sbar_draw_asm.inc` now provides its assembly implementation, called
from the existing `Sbar_Draw` assembly dispatcher. The default
`i486-asm-selectable-current` profile selects `SbarDrawImplementation=asm`;
the C-reference profile keeps the original C implementation. BENCH retains the
C body as `Sbar_MiniDeathmatchOverlay_C` and the selected assembly entry as the
parity target.

The assembly path preserves the width and bar-line guards, frag ordering,
viewer-centered row window and clamping, background colors, `%3i` digit layout,
local-player marker, name position and eight-pixel row spacing. `Sbar_SortFrags`
remains the selected sorter; the BENCH C oracle calls `Sbar_SortFrags_C`.

## Direct C/assembly parity

Eight focused cases compare the sorted score indexes, all captured draw event
types and arguments, resulting globals, and callee-saved-register ABI. They
cover the wide-screen threshold, zero and short bar layouts, centered negative
frags, missing viewer fallback, bottom-window clamp, tied scores and player
marker, and an empty score list. All eight cases pass. The broader status-bar
draw and face fixture also passes.

The strict focused command was:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -SbarDrawOnly -SbarDrawImplementation asm-fixture `
  -SbarFragsImplementation asm -SbarInventoryImplementation asm `
  -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

DOSBox-X exited with code 0 and reported `486 benchmark correctness PASS`. Its
result is `out/dos-bench-20261018-081140/bench-result.json`.

## Strict i486 gate and current ownership

The focused BENCH executable passed the strict object, linked executable,
startup and CWSDPMI provider gates. The gate verified 286,415 relocated
instructions, 529 startup rows and 9,207 provider instructions, with zero
above-i486 or unknown instructions and zero exemptions.

The refreshed full assembly-profile ownership report at
`out/profile-c8482542de108dbc/renderer-ownership-qbench.json` lists 378
directly reachable renderer entries and 54 C dependencies. That is 324/378, or
about 85.7% assembly-owned by reachable-symbol count. The inventory also has
66 unresolved direct callees and `completeCallGraph=false`, so this remains a
profile-specific proxy rather than a source-size completion percentage.

The current full-profile strict build also passed its ISA gates, but its
all-suite DOSBox benchmark exceeded the 180-second runner limit while executing
surface-cache experiments. No full-suite benchmark PASS or FPS result is
claimed from that run. The focused status-bar fixture above is the accepted
correctness result for this port.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/sbar.c:Sbar_MiniDeathmatchOverlay` | `src/sbar_draw_asm.inc:Sbar_MiniDeathmatchOverlay` | Eight exact score-order, draw-event, state and ABI cases | Focused strict BENCH object, linked executable, startup and provider audits pass |

This ports the widescreen mini-scoreboard routine only. The face, full
deathmatch scoreboard, intermission and finale paths remain separate work.
The fixtures measure correctness, not FPS.
