# Menu state entries move to i486 assembly (2026-10-19)

## Behavior and selector

`M_Menu_LanConfig_f` and `M_Menu_ServerList_f` now select i486 assembly through
`ScreenOverlaysImplementation=asm`. BENCH retains their original C bodies as
`M_Menu_LanConfig_f_C` and `M_Menu_ServerList_f_C`; the C-reference profile
continues to use the original public C entries.

The LAN entry preserves the existing Joining Game/TCP/IP and Starting Game
cursor rules, switches to the LAN menu, updates its flags, copies the default
host port, formats its decimal text for the valid 0 through 65,535 port range,
and clears only the first byte of the return-reason buffer. The server-list
entry initializes the menu destination/state, sound flag, cursor, error state,
return-reason first byte, and one-time sort flag.

## Direct C/assembly parity

The focused DOSBox-X screen-overlay run passes 1,280 exact C/assembly cases:
640 input combinations for each state entry. The matrix varies multiplayer,
network and LAN cursor state, eight valid port values, existing menu flags,
return-reason tail bytes, port-name sentinels, and server-list state. It checks
full result arrays and untouched state as well as stack/register and x87
control-word preservation. The complete screen-overlay suite also passes,
including the 1,920-case server-list drawing fixture, and reports
`486 benchmark correctness PASS`.

Two additional assembly-only boundary cases exercise negative and ten-digit
port values through bounded truncation. The C `sprintf` reference is not called
for those cases because its six-byte destination would overflow, which is
undefined behavior.

The run report is `out/dos-bench-20261019-213143/quake/bench486.txt`. The
generated 16 MB DOSBox config exited without producing a report; replaying the
staged batch with a private temporary 32 MB config completed with exit code 0.
The pinned DOSBox profile was not changed. This is a correctness run and does
not measure FPS.

## Strict i486 release verification and ownership

```powershell
tools/build-dos.ps1 -ScreenOverlaysImplementation asm `
  -CpuTarget i486 -NoBootstrap
```

The strict release manifest selects `ScreenOverlaysImplementation=asm` and
records `isaAuditStatus=PASS`. The source-bound object audit verifies 122,865
instructions with zero above-i486, unknown, or exempt instructions. The linked
release verifies 161,162 relocated instructions across 420 executable ranges
with zero opcode mismatches or data exemptions. The startup proof covers 529
CODE rows and 1,660 loaded bytes; the maintained runtime provider proof covers
9,207 instructions. The release map resolves both public entries from
`screen_overlaysasm.obj` and contains neither C oracle symbol.

The fresh inventory is
`out/profile-41090bd4aa6cb655/renderer-ownership-release-20261019-menuentry.json`.
It contains 602 renderer entries, 417 directly reachable entries, and no
directly reachable C renderer entries: 417/417, or 100.0%, are assembly-owned
by direct symbol count. The scan still reports 38 unresolved direct callees and
an incomplete call graph; 185 inventory entries are outside the traced roots.
This percentage is profile-specific and does not establish whole-codebase
completion.

## Scope and remaining work

This slice ports the LAN configuration and server-list state-entry routines.
No direct C renderer entries remain in this profile. Unresolved call edges and
renderer inventory entries outside the traced roots remain to be reviewed;
this does not close the full renderer-port objective or FPS/visual acceptance.
