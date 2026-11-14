# `R_PrintAliasStats` -> i486 assembly port (2026-10-09)

## Alias-stat leaf behavior and ownership

`R_PrintAliasStats` in `src/renderer/r_misc.c` prints `r_amodels_drawn` using the exact
format string `%3i polygon model drawn\n`. The assembly leaf in
`src/renderer/r_aliasstatsasm.s` preserves this behavior by pushing the count and same
format string as cdecl varargs to `Con_Printf`. Formatting, console-buffer
updates, and output policy remain owned by the existing C console routine.
The assembly function uses only baseline 486 integer instructions and exports
`R_PrintAliasStats_asm486` for the direct fixture call. The C oracle remains
available as `R_PrintAliasStats_C` in BENCH486 assembly builds.

## Alias-stat selector and oracle

`AliasStatsImplementation=c|asm` maps to `ASM486_ALIAS_STATS`. The focused
profile is `tools/renderer-profiles/i486-asm-alias-stats.json`; its only change
from `i486-c-reference.json` is this selector. The current combined opt-in
profile is `i486-asm-selectable-86.json`; historical selectable-84 and
selectable-85 profiles are retained unchanged.

`Bench486AliasStatsCases` in `src/tests/bench486/bench486_aliasstats.h`, invoked with
`-benchaliasstats`, redirects console writes into a guarded static 80 by 8
ring. Each C and assembly call starts from identical bytes and console state.
Cases cover zero, positive, negative, wide, signed-minimum, and signed-maximum
counts plus ring wrap. The fixture compares all ring bytes and captured console
state against an independent formatted-line oracle, and verifies both guard
regions. It pins time, disables file logging, suppresses screen updates, and
uses a newline to reset `Con_Print`'s private carriage-return state before each
trial. The fixture checks the assembly call boundary and output contract;
`Con_Printf` and its runtime formatting dependencies remain separately subject
to the build's compiler/runtime ISA audit.

## Alias-stat validation status

The focused i486 build passed with the alias-stats assembly selected. Object,
runtime, linked-input, linked-executable, relocated-executable, startup-helper,
and provider ISA checks all passed: 203,365 renderer/runtime instructions were
verified in the executable, with zero post-i486, unknown, or exempted
instructions. The separate startup and provider checks also passed.

DOSBox-X completed the `-benchaliasstats` run with all nine deterministic cases
passing and exact console-state comparison reporting zero failures. This
validates this leaf's console contract; it does not claim framebuffer parity for
the wider renderer. Reproduce the focused build and fixture with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 `
  -AliasStatsImplementation asm -Benchmark -NoBootstrap
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -AliasStatsOnly -AliasStatsImplementation asm -SkipBuild -NoBootstrap
```
