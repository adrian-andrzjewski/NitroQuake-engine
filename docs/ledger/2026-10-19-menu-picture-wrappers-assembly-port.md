# Centered menu picture assembly port

The default i486 profile now selects assembly for `M_DrawTransPic`,
`M_DrawPic`, and `M_DrawTransPicTranslate`. Each wrapper applies Quake's
unsigned `(vid.width - 320) >> 1` horizontal centering and forwards the picture
pointer; the translate wrapper also forwards the address of `translationTable`.
The C implementations remain available as BENCH parity oracles.

## Focused parity

The screen-overlay DOSBox-X fixture compares the C wrappers and assembly entry
points over six cases: 320-, 319-, 640-, and 1024-pixel widths, negative menu
origins, all three drawing variants, picture-pointer identity, and translation
table address. ABI and x87 control-word checks are included.

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

All six picture cases passed. The same run also passed the eight overlay
dispatch cases, ten pause/loading cases, seven menu text cases, and the console
draw fixture's nine state/call cases across four x87 rounding modes. This BENCH
run checks correctness; it does not measure FPS.

## Strict i486 release verification

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed project and runtime source proofs for 165 and 235
objects, respectively. The linked object audit decoded 162,906 instructions;
the final executable gate verified the same 162,906 relocated instructions,
529 startup code rows, and the 9,207-instruction CWSDPMI provider. It reported
zero above-i486, unknown, or exempt instructions.

The refreshed non-BENCH release ownership inventory contains 407 directly
reachable renderer entries, of which 29 remain C-owned: 378/407, or 92.9%, are
assembly-owned by reachable-symbol count. The call graph remains incomplete,
with 38 unresolved direct callees. This is a profile-specific symbol-count
estimate, not a weighted measure of effort.

## Remaining validation

The focused C/ASM call-argument parity and strict ISA gates pass. No full-scene
capture or FPS measurement was performed for this wrapper slice. The broader
renderer port and complete call-graph review remain active.
