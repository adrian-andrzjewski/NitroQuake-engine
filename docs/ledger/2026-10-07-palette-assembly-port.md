# Palette generation and update

`src/v_paletteasm.s` owns the public `BuildGammaTable`, `V_CheckGamma`,
`V_SetContentsColor`, `V_CalcPowerupCshift` and `V_UpdatePalette` entries when
`PaletteImplementation=asm`. The reference C implementations remain available
in BENCH486 builds. The selector remains C by default while the complete
renderer profile is being validated.

The assembly preserves gamma-table generation, the original integer blend
order, damage/bonus decay, contents colors, power-up priority, previous-shift
state, palette callback count and all 768 output bytes. It restores the x87
control word and follows the shared cdecl register and stack convention. The
remaining `pow` runtime dependency is included in the linked ISA audit.

## Direct equivalence and ABI checks

`src/bench486_palette.h` exercises 480 gamma/contents/power-up cases and 9,728
update frames, including 8,192 uninterrupted stateful frames and twelve x87
control words. It compares the complete gamma table, color-shift state, output
palette and callback count. Register/stack probes and input/output canaries
pass; a deliberate guard overwrite confirms that the detector rejects a fault.

The isolated accepted report is
`out/palette-worktree-20261007/out/dos-bench-20261007-153916/bench-result.json`.
After reviewed integration, the same fixtures passed in the main checkout:
`out/dos-bench-20261007-163746/bench-result.json`. That run verifies actual
palette and frame-control assembly selection in the build manifest, rather
than inferring selection from the command line.

Before acceptance, the startup fixture exposed a missing typed declaration for
`BuildGammaTable(float)`: a C89 implicit call supplied a double while the
assembly entry consumed a float. `view.c` now declares the float argument, and
the fixture checks the initial identity gamma table. No incorrect startup
result is accepted.

## Paired complete frames

The accepted paired report is
`out/palette-worktree-20261007/out/render-parity-palette-verified-selection-20261007/render-parity-result.json`.
It uses the same source tree for the pure C profile and the focused palette
assembly profile:
`F87A8BF5FE0318FDC16F62C186E3BBD8162016866FFFD6B14FB4A515AA75EB7B`.
Both actual build manifests are checked before execution. Demo1 VGA, demo2
entities and demo3 world traversal each run twice on the configured 486
emulator. All 6,058 post-warmup frame checksums and six captures match exactly.
Each capture compares 64,000 indexed pixels and all 768 palette bytes; there
is no tolerance. Six documented startup frames per run are outside the
post-warmup checksum comparison.

The candidate executable SHA256 is
`E765A0A4B9FBB222D9493FEEE778E13ABEB45659F3EB68415C544E471F27839E`.
The object/runtime/linked audit reports 108 objects, 343 closure inputs,
235 selected runtime members and 224,528 linked instructions, with no enforced
post-i486 or unclassified instructions. External DPMI-host and MZ-loader
verification remains a separate completion requirement.

Reference/candidate median FPS is 12.6821515/12.6714085 for demo1,
12.7816135/12.73230 for demo2 and 12.17485/12.166824 for demo3. The largest
observed reduction is below 0.4%; these are regression observations, not an
optimization or completion criterion.

The reviewed integration allowlist and preimages are retained in
`out/palette-integration-preimages-20261007/manifest.json`. Full combined-profile
parity, expanded full-frame scenarios, soak and visual/gameplay acceptance
remain pending.

## Reproduce

Run `tools/bench-dos.ps1 -NoBootstrap -PaletteImplementation asm -PaletteOnly`
for the direct gate, then `tools/render-parity-dos.ps1 -NoBootstrap
-ReferenceProfile tools/renderer-profiles/i486-c-reference.json
-CandidateProfile tools/renderer-profiles/i486-asm-palette.json
-Scenario demo1-vga-full,demo2-entity-workload,demo3-world-workload
-RunsOverride 2` for complete-frame equivalence. Use the same explicit
`-DataRoot` when running from an isolated checkout.
