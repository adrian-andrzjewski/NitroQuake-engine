# Main and single-player menu pages move to i486 assembly (2026-10-19)

## Behavior and selector

`M_Main_Draw` and `M_SinglePlayer_Draw` now select the shared assembly page
renderer in the default i486 profile. It loads the plaque, title, page picture,
and animated menu dot, then uses the existing centered picture drawing paths.
The C versions remain available as the C-reference implementation and as
BENCH parity oracles.

The shared routine preserves each page's asset order, title centering, fixed
picture coordinates, cursor position, and animated dot selection. Its x87
conversion temporarily uses round-toward-zero to match the compiled C
expression and restores the caller's control word.

## Direct C/assembly parity

The focused DOSBox-X overlay benchmark passes 144 main/single-player page
cases. The fixture covers all six animation frames, multiple cursor positions,
viewport widths, x87 precisions, and all four rounding modes. It compares the
ordered cache and draw events, picture pointers and placement, ABI sentinels,
and x87 control-word preservation against both the C oracle and expected
results. The existing focused overlay, menu text, centered-picture, text-box,
frame-dispatch, and console-draw fixtures pass in the same run.

Run the focused parity fixture with:

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the i486 instruction proof.

## Strict i486 release verification

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed project proofs for 165 objects, runtime proofs for 235
sources and 400 exact native/annotated object proofs, plus the complete linked
executable ISA gate. It verified 162,474 relocated instructions, 529 startup
rows, and 9,207 CWSDPMI provider instructions with no above-i486, unknown,
exempt, or unclassified instructions or bytes.

The refreshed non-BENCH release ownership inventory contains 409 directly
reachable renderer entries, of which 27 remain C-owned: 382/409, or 93.4%, are
assembly-owned by reachable-symbol count. The call graph remains incomplete,
with 38 unresolved direct callees. This is a profile-specific symbol-count
estimate, not a weighted measure of implementation effort.

## Scope and remaining work

This slice ports the two top-level page draw routines and keeps the existing
asset cache and picture primitives as dependencies. Other menu page routines
remain C-owned. It does not measure FPS or establish complete-scene image
parity; the broader renderer port and full call-graph review remain open.
