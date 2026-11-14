# Full intermission deathmatch scoreboard i486 assembly port (2026-10-18)

## Behavior and selector

`Sbar_DeathmatchOverlay` draws the full frag ranking during deathmatch
intermission. `src/client/sbar_draw_asm.inc` now owns the selected implementation as
`Sbar_DeathmatchOverlay` / `Sbar_DeathmatchOverlay_asm486`; the default i486
selector profile sets `SbarDrawImplementation=asm`. The BENCH build retains
`Sbar_DeathmatchOverlay_C` as the C oracle. The C
`Sbar_IntermissionOverlay` dispatcher calls the selected scoreboard entry.

The assembly path updates `scr_copyeverything` and `scr_fullupdate`, loads and
centers `gfx/ranking.lmp`, calls the selected frag sorter, then draws each
active player's color bands, first three `%3i` characters, local-player glyph,
name, and ten-pixel row step. It preserves the original unsigned `vid.width`
centering arithmetic, including the width-319 edge case. The fixture reuses
the existing 16-player scoreboard storage rather than allocating a duplicate
table.

## Direct C/assembly parity

Six exact cases compare score order, picture identity and location, every draw
event and argument, state changes, and callee-saved-register ABI. They cover
classic centering and the local marker, sub-320 unsigned centering, widescreen
tied scores with no viewer, an empty roster, all 16 slots with signed and
three-character frag formats, and one player with negative frags. All six
cases pass. The existing 14 status-bar draw cases, 14 face cases, and eight
mini-deathmatch cases also pass.

## Strict i486 verification

The strict focused BENCH run passed the 165-object project audit, all 400
object proofs, and the complete linked executable gate. It verified 288,315
linked instructions, 529 startup rows, and 9,207 CWSDPMI provider
instructions, with zero above-i486 instructions, unknown instructions, or
exemptions. Final mapping passed with 431 source-bound contributions, 2,290
CODE ranges, and 34 DATA ranges. DOSBox-X exited with code 0 and reported
`486 benchmark correctness PASS`.

Reproduction:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -SbarDrawOnly -SbarDrawImplementation asm-fixture `
  -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180
```

The result is `out/dos-bench-20261018-184053/bench-result.json`.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/client/sbar.c:Sbar_DeathmatchOverlay` | `src/client/sbar_draw_asm.inc:Sbar_DeathmatchOverlay` | Six exact score-order, picture, draw-event, state, and ABI cases | Strict BENCH object, linked executable, startup, and provider gates pass |

This ports the full deathmatch score drawing routine. The C intermission
dispatcher, finale path, menu and screen dependencies, and other directly
reachable C renderer entries remain outside this slice. The fixture verifies
correctness; it does not measure FPS or close the full-renderer port.
