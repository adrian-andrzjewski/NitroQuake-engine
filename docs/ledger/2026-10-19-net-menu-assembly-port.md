# Network menu page moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_Net_Draw` now selects assembly in the default i486 screen-overlay profile.
It draws the shared plaque and multiplayer title, selects active or dimmed
serial, direct, IPX, and TCP/IP pictures, preserves the optional fifth row,
renders the four-line help box and selected help text, and draws the animated
menu cursor. Its C implementation remains the BENCH parity oracle.

The routine uses the existing assembly menu text-box renderer and restores the
x87 control word after calculating the animated cursor frame.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 4,616 exact C/assembly cases.
The fixture covers all eight serial/IPX/TCP/IP availability combinations,
four cursor/help pages, the standard and optional fifth-row layouts, four
viewport widths, six animation frames, three x87 precisions, and all four
rounding modes. It checks cache paths and picture order/placement, the complete
text-box tile sequence, all help-text glyphs and positions, preserved state,
ABI sentinels, and x87 control-word preservation. The other overlay, menu,
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
executable ISA gate. It verified 162,351 relocated instructions, 529 startup
rows, and 9,207 CWSDPMI provider instructions with no above-i486, unknown,
exempt, or unclassified instructions or bytes. The refreshed release inventory
confirms `_M_Net_Draw` is assembly-owned by `screen_overlaysasm.s`.

The report contains 409 directly reachable renderer entries, of which 21
remain C-owned: 388/409, or 94.9%, are assembly-owned by reachable-symbol
count. The call graph remains incomplete, with 38 unresolved direct callees.
This is a profile-specific symbol-count estimate, not a weighted measure of
implementation effort.

## Scope and remaining work

This slice ports the protocol-selection menu and help-panel drawing path. It
does not port the serial, modem, or LAN configuration pages. It does not measure
FPS or establish complete-scene image parity; the broader renderer port and
call-graph review remain open.
