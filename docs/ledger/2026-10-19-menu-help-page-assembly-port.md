# Help menu pages move to i486 assembly (2026-10-19)

## Behavior and selector

`M_Help_Draw` now uses the screen-overlay assembly profile. The routine formats
the active `help_page` path, loads the matching cached picture, and draws it
through the existing centered menu-picture entry. The C implementation remains
available as the C-reference version and BENCH parity oracle.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 96 exact C/assembly cases across
all six help pages, four viewport widths, and all four x87 rounding modes. The
fixture compares the cached asset and ordered draw event, centered placement,
read-only page/viewport state, ABI sentinels, and x87 control-word preservation.
The existing overlay dispatch, pause/loading, menu text, centered-picture,
main/single-player page, text-box, menu-frame, and console-draw fixtures also
pass in the same run.

Run the focused parity fixture with:

```powershell
tools/bench-dos.ps1 -ScreenOverlaysImplementation asm -ScreenOverlaysOnly `
  -CpuTarget i486 -NoBootstrap -SkipIsaAudit -TimeoutSeconds 180
```

`-SkipIsaAudit` makes this a diagnostic runtime run; the release gate below
provides the i486 instruction proof.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict build passed project proofs for 165 objects, runtime proofs for 235
sources and 400 exact native/annotated object proofs, plus the complete linked
executable ISA gate. It verified 162,466 relocated instructions, 529 startup
rows, and 9,207 CWSDPMI provider instructions with no above-i486, unknown,
exempt, or unclassified instructions or bytes. The refreshed ownership report
confirms `_M_Help_Draw` is owned by `screen_overlaysasm.s` as assembly.

The report contains 409 directly reachable renderer entries, of which 25
remain C-owned: 384/409, or 93.9%, are assembly-owned by reachable-symbol
count. The call graph remains incomplete, with 38 unresolved direct callees.
This is a profile-specific symbol-count estimate, not a weighted measure of
implementation effort.

## Scope and remaining work

This slice ports the six help-page draw path and keeps the shared picture
cache and draw primitives as dependencies. Other menu pages remain C-owned.
It does not measure FPS or establish complete-scene image parity; the broader
renderer port and call-graph review remain open.
