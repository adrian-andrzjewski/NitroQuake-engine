# Status-bar primitive i486 assembly slice (2026-10-15)

## Reference mapping and selector

| Reference behavior | Assembly implementation | C parity oracle |
| --- | --- | --- |
| `Sbar_DrawPic`, `Sbar_DrawTransPic`, `Sbar_DrawCharacter`, `Sbar_DrawString` in `src/sbar.c` | `src/sbarasm.s`, selected by `SbarPrimitiveImplementation=asm` | The C entry points are retained only in BENCH builds as `*_C` oracle functions |
| `Sbar_itoa` and `Sbar_DrawNum` in `src/sbar.c` | 486 integer formatter and digit-frame dispatcher in `src/sbarasm.s` | BENCH-only C formatter and number drawer |

The default i486 profile selects the assembly path; the i486 C-reference
profile selects C. The assembly uses only i386-and-earlier integer
instructions, including reciprocal-multiply division for decimal conversion.
`src/asm_sbar.h` pins the `client_state_t.gametype`, `vid.width`, `vid.height`,
digit-table layout, deathmatch constant and 32-bit pointer size at compile time.

The HUD centering expression uses the unsigned `vid.width` field. The first
focused capture exposed that widths below 320 therefore require a logical
right shift. The assembly now uses `SHR`, matching the C wraparound result for
those widths as well as ordinary 320-pixel and wider viewports.

## Direct C/assembly parity

`Bench486SbarPrimitiveCases` compares transformed draw-call captures and
formatted numeric output without dereferencing synthetic picture pointers. The
fixture covers normal/deathmatch positioning at four viewport widths, both
digit colors, one through four requested digits, positive and negative
numbers, truncation/padding, and the signed 32-bit formatter bounds.

The accepted DOSBox-X report says:

```text
sbar number and coordinate primitives C/ASM PASS (0 failures; 18 formatter and 544 scene-state cases)
486 benchmark correctness PASS
```

Reproduce the focused guest fixture with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -SbarPrimitivesOnly
```

## Strict i486 verification

The accepted benchmark build passed source reproduction for 151 project
objects and 235 installed runtime objects. Its linked-object and executable
audits decoded 278,938 instructions with zero above-i486 instructions, unknown
encodings or exemptions. The final release build passed 167,757 relocated
instructions, 529 startup rows, CRT helpers and 9,207 provider instructions,
again with zero exemptions. `tools/guard-i486-release.py` passes for 151
objects plus `quake.exe`; the deliberate assembly change is recorded in the
release hash manifest.

## Remaining C ownership

This slice ports the per-call HUD primitives, not the status-bar composition.
`Sbar_Draw`, `Sbar_DrawInventory`, `Sbar_DrawFace`, `Sbar_DrawFrags`,
`Sbar_DrawScoreboard`, scoreboard sorting, and the intermission/finale overlay
decisions remain C-owned. They are the remaining status-bar feature logic to
port before describing the HUD as assembly-owned.
