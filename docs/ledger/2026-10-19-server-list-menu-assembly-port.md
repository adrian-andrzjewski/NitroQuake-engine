# Server-list menu drawing moves to i486 assembly (2026-10-19)

## Behavior and selector

`M_ServerList_Draw` now selects i486 assembly through
`ScreenOverlaysImplementation=asm`. BENCH retains the C renderer as
`M_ServerList_Draw_C`; the C-reference profile continues to use the original C
entry.

The assembly routine sorts the host cache once when `slist_sorted` is clear,
using unsigned-byte name ordering compatible with `strcmp` and swapping each
complete 96-byte host record. It then draws the cached multiplayer title,
formats visible host rows with the original C format strings, animates the
selection cursor from `realtime`, and prints any return reason in white.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 1,920 exact C/assembly cases.
The matrix covers host-cache counts 0, 1, 2, 5, and 8; already-sorted and
unsorted state; duplicate and high-byte names; row formatting; viewport and
title widths; cursor extremes; return-reason text; three x87 precisions and
four rounding modes; and ABI sentinels. It compares sorted cache records,
picture and text traces, x87 state, and register/stack guards. The full
screen-overlay run also reports `486 benchmark correctness PASS`.

The run report is `out/dos-bench-20261019-201349/quake/bench486.txt`. The
runner used a private temporary 32 MB DOSBox config because the generated
16 MB profile did not produce a report in this environment; the pinned
DOSBox profile was not changed. This is a correctness run and does not measure
FPS.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict release manifest selects `ScreenOverlaysImplementation=asm` and
records `isaAuditStatus=PASS`. The source-bound object audit reports 122,938
instructions, zero unclassified instructions, zero violations, and zero
exemptions. The linked executable proof verifies all 161,235 relocated
instructions with zero opcode mismatches; the startup proof covers 529 CODE
rows, and the maintained runtime provider proof covers 9,207 instructions.
The release map resolves `M_ServerList_Draw` from
`screen_overlaysasm.obj` and contains no C oracle symbol.

The fresh ownership report is
`out/profile-41090bd4aa6cb655/renderer-ownership-release-20261019-serverlist.json`.
It contains 602 renderer entries and 417 directly reachable entries, with two
remaining direct C dependencies: `_M_Menu_LanConfig_f` and
`_M_Menu_ServerList_f`. By direct reachable-symbol count, 415/417, or 99.5%,
are assembly-owned. The inventory has 38 unresolved direct callees and an
incomplete call graph, so the percentage is profile-specific rather than a
whole-codebase completion measure.

## Scope and remaining work

This slice ports the server-list drawing routine, including its one-time sort.
The two remaining directly reachable C dependencies are menu state-entry
routines; other C routines and unresolved call edges remain outside this
direct-entry count. Full renderer ownership and FPS/visual acceptance remain
open.
