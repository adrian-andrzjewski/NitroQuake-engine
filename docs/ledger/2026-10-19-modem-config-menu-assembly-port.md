# Modem configuration menu moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_ModemConfig_Draw` now selects the assembly renderer in the default i486
screen-overlay profile. It draws the plaque and multiplayer title, dialing mode,
Clear/Init/Hangup fields and text boxes, the OK button, edit cursors, and the
animated menu cursor. The C implementation remains available as a BENCH parity
oracle.

The assembly path calls the shared menu picture, text, and text-box renderers.
It computes the cursor phase with C-compatible truncation and restores the x87
control word after the conversion.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 2,880 exact C/assembly cases.
The matrix covers five cursor positions, both dialing modes, empty/short/maximum
field strings, four viewport widths, both cursor-animation phases, three x87
precisions, and all four rounding modes. The fixture checks the cache and draw
event stream, textbox tiles, every glyph value and coordinate, ABI sentinels,
and x87 control-word preservation. The other screen-overlay, menu, textbox,
dispatch, and console-draw fixtures pass in the same run.

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

The strict build passed project proofs for 165 objects and runtime proofs for
235 installed sources, verifying 400 exact native/annotated object proofs. The
complete executable ISA gate passed with 162,321 relocated instructions, 529
startup rows, and 9,207 provider instructions; it found no above-i486,
unclassified, or exempt instructions.

The refreshed release inventory confirms `_M_ModemConfig_Draw` is assembly-owned
by `screen_overlaysasm.s`. It contains 409 directly reachable renderer entries,
of which 20 remain C-owned: 389/409, or 95.1%, are assembly-owned by
reachable-symbol count. The call graph remains incomplete, with 38 unresolved
direct callees. This is a profile-specific symbol-count estimate, not a weighted
measure of implementation effort. No directly reachable cache or zone-heap C
owners appear in this profile.

## Scope and remaining work

This slice ports the modem configuration page drawing routine. The remaining
direct C-owned renderer dependencies are console printing/debug paths, ten
other menu draw paths, the status-bar change notifier, and DOS/VESA video lifecycle
and palette routines. Full-scene parity, FPS measurement, and completion of the
renderer call graph remain open.
