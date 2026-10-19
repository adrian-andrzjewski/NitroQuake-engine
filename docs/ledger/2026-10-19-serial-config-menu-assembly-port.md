# Serial configuration menu moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_SerialConfig_Draw` now selects the i486 assembly renderer through
`ScreenOverlaysImplementation=asm`. BENCH keeps the C oracle as
`M_SerialConfig_Draw_C`; the C-reference profile uses the original C
`M_SerialConfig_Draw` entry.

The assembly path preserves plaque and title ordering, the centered title,
COM/IRQ/baud labels and values, the conditional modem setup and phone fields,
the Connect/OK textbox, both animated cursors, and the return-reason text. It
uses the shared menu picture, text, and textbox helpers.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 3,456 exact C/assembly cases.
The matrix covers serial/direct configuration, starting/joining, cursor
positions, viewport and title widths, changing phone/return-reason strings,
multiple x87 precision and rounding modes, and ABI sentinels. The fixture
compares cache and draw events, textbox tiles, glyph values and coordinates,
state, x87 control-word preservation, and stack/register guards. The full
screen-overlay run also passes the adjacent menu, textbox, dispatch, and console
draw fixtures, followed by `486 benchmark correctness PASS`.

The run report is `out/dos-bench-20261019-201349/quake/bench486.txt`. The
generated DOSBox profile uses 16 MB and did not produce a report in this
environment; replaying the staged `bench.bat` with a private 32 MB config copy
completed with exit code 0. The pinned DOSBox profile was not changed. This is
a correctness run and does not measure FPS.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict release gate passed 161,249 relocated instructions, 529 startup
CODE rows, and 9,207 runtime-provider instructions with zero above-i486,
unknown, or exempt instructions. The build manifest selects
`ScreenOverlaysImplementation=asm`; the production map resolves
`M_SerialConfig_Draw` to `screen_overlaysasm.obj` and contains no C oracle
symbol.

The fresh release inventory at
`out/profile-41090bd4aa6cb655/renderer-ownership-release-20261019-serialconfig.json`
contains 602 renderer entries and 417 directly reachable entries, of which
three remain C-owned: `_M_Menu_LanConfig_f`, `_M_Menu_ServerList_f`, and
`_M_ServerList_Draw`. That is 414/417, or 99.3%, assembly-owned by direct
symbol count. The inventory has 38 unresolved direct callees and an incomplete
call graph; this percentage is profile-specific and is not a whole-codebase
completion measure.

## Scope and remaining work

This slice ports the serial configuration page drawing routine. The three
remaining directly reachable C renderer dependencies are the LAN configuration
entry, server-list entry, and server-list draw routine. Other C routines and
unresolved call edges remain outside this direct-entry count. Full renderer
ownership and FPS/visual acceptance remain open.
