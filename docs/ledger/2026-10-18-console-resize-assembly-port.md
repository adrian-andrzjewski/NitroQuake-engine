# `Con_CheckResize` i486 assembly port (2026-10-18)

## Behavior and selector

`src/console.c:Con_CheckResize` recalculates the character width from
`vid.width`, reformats the retained console ring-buffer rows when the width
changes, fills unused cells with spaces, resets notification times, and clears
backscroll. Before video initialization it falls back to a 38-character width.

`src/screen_consolesetupasm.s:Con_CheckResize` now implements this behavior in
i486 assembly under the existing `ScreenConsoleSetupImplementation=asm`
selector. It snapshots the full 16 KiB text buffer on its stack before clearing
and reflowing rows, preserving the newest lines and characters just like the C
reference. The selected release omits the C body; BENCH keeps it as
`Con_CheckResize_C` for direct comparison.

## Direct C/assembly parity

`src/bench486_conresize.h:Bench486ConsoleResizeCases` compares the C oracle and
assembly routine for seven states: unchanged width, wider and narrower
scrollback, wrapped current-line position, one-character width, pre-video
fallback, and initial buffer setup. The fixture compares the entire text buffer
with guards, console width/line/current/backscroll/cursor state, notification
time bytes, preserved text pointer, and callee-saved-register ABI state.

All seven direct cases passed with failure mask `0x0`. The existing console
setup fixture also passed 14 cases across 12 x87 precision and rounding modes.

## Strict i486 build and execution

The command was
`tools/bench-dos.ps1 -ScreenConsoleSetupOnly -ScreenConsoleSetupImplementation asm -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180`.
DOSBox-X reported both parity fixtures passing and `486 benchmark correctness
PASS`. The strict audit checked 245,486 project-object instructions, 283,783
linked-object instructions, 283,783 relocated executable instructions, 529
startup instruction rows, and 9,207 CWSDPMI provider instructions. It found
zero above-i486 or unknown instructions, exemptions, skipped bytes, or
unmatched instruction sites.

The focused ownership report at
`out/profile-c8482542de108dbc/renderer-ownership-qbench.json` contains 382
directly reachable renderer entries and 57 C entries, approximately 85.1%
assembly-owned by reachable-symbol count. This is a rough, profile-specific
proxy: the report has 64 unresolved direct callees and
`completeCallGraph=false`, and it does not weight functions by size or
complexity.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/console.c:Con_CheckResize` | `src/screen_consolesetupasm.s:Con_CheckResize` | Seven exact scrollback, state, guard, notification-time and ABI cases | Focused strict BENCH i486 build, executable and provider gates pass with zero exemptions |

This slice ports console resize and ring-buffer memory reflow. Console output,
logging, menus, higher-level status-bar composition, and other video/cache and
screen support remain outside this routine. The ownership estimate above is not
a completion percentage for execution time or code complexity.
