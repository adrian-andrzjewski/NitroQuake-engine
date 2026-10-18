# Menu text-box assembly port

The default i486 profile now selects assembly for `M_DrawTextBox`. The routine
preserves the original left, middle, and right tile order, repeats middle
columns while `width > 0`, draws each interior row while `n < lines`, and uses
`box_mm2.lmp` beginning on the second interior row. The C implementation remains
available as a BENCH parity oracle.

## Focused parity

The screen-overlay DOSBox-X fixture captures both cache-picture requests and
picture draw calls. Five C/ASM cases cover zero and negative widths, one and
multiple center columns, odd width, different `vid.width` values, negative
origins, zero to four interior rows, and the `box_mm2` substitution. It compares
the full ordered cache/draw trace, expected edge coordinates, ABI, and x87
control word.

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

All five text-box cases passed. The same fixture passed the overlay dispatch,
pause/loading, menu glyph, centered menu picture, and console draw parity cases.
This BENCH run checks correctness; it does not measure FPS.

## Strict i486 release verification

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed project and runtime source proofs for 165 and 235
objects. The linked object audit decoded 162,581 instructions; the final
executable gate verified all 162,581 relocated instructions, 529 startup code
rows, and the 9,207-instruction CWSDPMI provider. It reported zero above-i486,
unknown, or exempt instructions.

The refreshed non-BENCH release inventory contains 407 directly reachable
renderer entries, of which 28 remain C-owned: 379/407, or 93.1%, are
assembly-owned by reachable-symbol count. The call graph remains incomplete,
with 38 unresolved direct callees. This is a profile-specific symbol-count
estimate, not a weighted measure of effort.

## Remaining validation

The five-case cache/draw parity and strict ISA gates pass. No full-scene capture
or FPS measurement was performed for this menu utility. The broader renderer
port and complete call-graph review remain active.
