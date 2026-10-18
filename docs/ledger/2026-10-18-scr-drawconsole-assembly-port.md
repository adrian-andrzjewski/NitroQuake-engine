# `SCR_DrawConsole` i486 assembly port (2026-10-18)

## Behavior and selector

`src/screen.c:SCR_DrawConsole` draws the visible console when
`scr_con_current` is nonzero. It sets `scr_copyeverything`, converts the
floating line height to an integer, calls `Con_DrawConsole` with input enabled,
and resets `clearconsole`. With no console height, it calls `Con_DrawNotify`
only for game and message key destinations.

`src/screen_overlaysasm.s:SCR_DrawConsole` now owns this per-frame dispatch when
`ScreenOverlaysImplementation=asm`. Its x87 conversion temporarily selects
round-toward-zero to match the C float-to-int conversion, then restores the
caller's control word. The selected release omits the C body; BENCH retains it
as `SCR_DrawConsole_Screen_C` and records the downstream call and arguments.

## Direct C/assembly parity

`Bench486ScreenConsoleDrawCases` checks nine states: positive and negative zero,
game/message notification, console/menu suppression, positive and negative
fractional heights, sub-unit heights, and a whole-number height. It compares
downstream call choice and arguments, redraw/clear state, input flag, key
destination, original float value, callee-saved ABI, and x87 control word. All
nine cases passed in each of the four x87 rounding modes, with exact C/assembly
state and call parity.

The existing overlay dispatcher fixture passed its eight branch/event cases,
and the menu text fixture passed its seven cases in the same DOSBox-X run.

## Strict i486 build and execution

The command was
`tools/bench-dos.ps1 -ScreenOverlaysOnly -ScreenOverlaysImplementation asm -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180`.
DOSBox-X exited with code 0 and reported `486 benchmark correctness PASS`.
The strict gate audited 246,262 project-object instructions and 284,559
linked, relocated executable instructions, plus 529 startup rows and 9,207
CWSDPMI provider instructions. It found zero above-i486 or unknown
instructions, exemptions, skipped bytes, or unmatched instruction sites.
The result is recorded in
`out/dos-bench-20261018-064417/bench-result.json`.

The refreshed ownership report,
`out/profile-c8482542de108dbc/renderer-ownership-qbench.json`, contains 379
directly reachable renderer entries and 56 directly reachable C entries,
approximately 85.2% assembly-owned by symbol count. It remains a
profile-specific proxy: 66 direct callees are unresolved and
`completeCallGraph=false`; routine size and complexity are not weighted.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/screen.c:SCR_DrawConsole` | `src/screen_overlaysasm.s:SCR_DrawConsole` | Nine call, argument, state, and ABI cases across four x87 rounding modes | Focused strict BENCH i486 object, executable, startup, and provider audits pass with zero exemptions |

This ports the screen's per-frame console/notify selection. The called console
draw routines have their own assembly paths and parity fixtures. Menu and
status-bar composition, console printing/logging, video mode support, and the
remaining screen helpers are still separate C ownership work. This run records
correctness and instruction compatibility, not a new FPS measurement.
