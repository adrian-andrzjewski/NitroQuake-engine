# Status-bar dispatcher i486 assembly slice (2026-10-16)

## Scope and selection

`Sbar_Draw` now has an i486 assembly implementation in
`src/client/sbar_draw_asm.inc`, included by `src/client/sbarasm.s`. The default
`i486-asm-selectable-current` profile selects `SbarDrawImplementation=asm`;
`i486-c-reference` selects the original C implementation. BENCH builds retain
`Sbar_Draw_C` as the direct oracle and can select `asm-fixture` to route helper
calls into the parity observer.

The dispatcher ports the top-level branches for full-screen console handling,
console/page limits, copy flags, widescreen tile clearing, inventory and frag
dispatch, scoreboard selection, Hipnotic keys, invulnerability, armor and ammo
priorities, face/health drawing, and the widescreen deathmatch mini-overlay.
Those called drawing routines remain separately owned and are outside this
slice.

## Direct C/assembly parity

`Bench486SbarDrawCases` checks 14 cases through the C and assembly entries. The
cases cover full console, saturated updates, fractional console height,
compact and widescreen HUD branches, Hipnotic inventory, armor/ammo priorities,
low stats, Rogue fallbacks, scoreboard/dead-player selection, deathmatch
mini-overlay, and inventory thresholds. DOSBox-X reports all 14 cases passing
with zero failures:

```text
out/dos-bench-20261016-210035/bench-result.json
```

## Strict i486 gate

The default assembly profile passed the strict benchmark build at
`out/profile-a166cf63a9f3711b`. The linked executable audit decoded 278,473
relocated instructions with zero above-i486 instructions, unknown encodings,
or exemptions. The startup audit covered 529 rows and the CWSDPMI provider
audit covered 9,207 instructions. The report is
`out/strict-build-sbar.log`.

## Demo 1 render and exact parity

The default candidate passed two full `demo1-vesa-full` runs. The report at
`out/render-validation-20261016-212600/render-validation-result.json` records
970 frames per run, no checksum overflow, final checksum `1047377823`, and
12.02 FPS for that timedemo run. Its capture matched the golden palette and
remained within the existing image tolerance.

The paired C-reference/assembly run passed at
`out/render-parity-20261016-214353/render-parity-result.json`. After six warmup
frames, 964 of 964 frame checksums matched; the final indexed framebuffer and
palette were byte-identical, with zero pixel-index or palette mismatches. The
timing figures are run-specific measurements, not a performance acceptance
claim.

## Remaining work

This slice converts the `Sbar_Draw` dispatcher only. Its inventory, face, frag,
scoreboard, intermission and finale callees still have their own ownership
status, and the software renderer port remains incomplete.
