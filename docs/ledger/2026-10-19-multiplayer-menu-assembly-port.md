# Multiplayer menu page moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_MultiPlayer_Draw` now selects assembly in the default i486 screen-overlay
profile. It reuses the shared assembly page renderer already used by the main
and single-player pages for the plaque, centered title, content picture, and
animated menu dot. It then checks serial, IPX, and TCP/IP availability and draws
the centered “No Communications Available” message only when all three are
unavailable. The C implementation remains the BENCH parity oracle.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 1,152 exact C/assembly cases
across all six animation frames, four viewport widths, three x87 precisions,
all four rounding modes, and four network states (offline, serial, IPX, and
TCP/IP). The fixture compares ordered cache/picture events, title centering,
cursor placement, offline message glyphs and placement, read-only state, ABI
sentinels, and x87 control-word preservation. The other overlay, menu,
text-box, dispatch, and console-draw fixtures pass in the same run.

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
executable ISA gate. It verified 162,368 relocated instructions, 529 startup
rows, and 9,207 CWSDPMI provider instructions with no above-i486, unknown,
exempt, or unclassified instructions or bytes. The refreshed release inventory
confirms `_M_MultiPlayer_Draw` is assembly-owned by `screen_overlaysasm.s`.

The report contains 409 directly reachable renderer entries, of which 22
remain C-owned: 387/409, or 94.6%, are assembly-owned by reachable-symbol
count. The call graph remains incomplete, with 38 unresolved direct callees.
This is a profile-specific symbol-count estimate, not a weighted measure of
implementation effort.

## Scope and remaining work

This slice ports the multiplayer page draw path and reuses the common page
renderer for the assets and animated cursor. It does not measure FPS or
establish complete-scene image parity; the broader renderer port and call-graph
review remain open.
