# `Con_DrawConsole` i486 assembly port (2026-10-17)

## Behavior and selector

`src/client/console.c:Con_DrawConsole` returns without drawing when `lines <= 0`.
Otherwise it draws the console background, sets `con_vislines`, derives the
text row count and starting Y coordinate, applies `con_backscroll` to each
scrollback row, and draws each glyph through `Draw_Character`. It calls
`Con_DrawInput` only when requested.

`src/client/con_inputasm.s:Con_DrawConsole_asm486` now implements that orchestration
with 32-bit DJGPP cdecl, preserving EBX/ESI/EDI/EBP. The row shift is arithmetic
to match the i486 C build; scrollback indexing uses signed division after
clamping the row to zero. Existing background, glyph, and input drawing routines
remain the callees. `ConsoleImplementation=asm` selects both `Con_DrawConsole`
and `Con_DrawInput`; the C implementation is retained as
`Con_DrawConsole_Console_C` in BENCH486 builds and is omitted from the selected
release. `ConsoleImplementation=c` keeps both C entry points selected.

## Direct C/assembly parity

`src/tests/bench486/bench486_console_input.h:Bench486ConsoleDrawCases` runs the retained C
oracle and direct assembly entry against the live DOS video and scrollback
state for one-line, partial-row, one-row, multi-row, and full-console heights.
It compares the full indexed framebuffer, visible-line state, unchanged video
configuration and scrollback values, and the ABI result, then restores the
original framebuffer. Input drawing is disabled in this fixture; the adjacent
input fixture separately exercises that callee across cursor and x87 cases.

The DOSBox-X run passed the existing 21 input cases under all four x87 rounding
modes and the five new console-draw cases. Both reported exact C/assembly state
and framebuffer parity with zero failures.

## Strict i486 build and execution

The command was
`tools/bench-dos.ps1 -ConsoleInputOnly -ConsoleImplementation asm -CpuTarget i486 -NoBootstrap`.
The BENCH executable SHA-256 was
`2D513B2DF22BC0443C7577C4AEF9C53280AE44E03975537AC6B9A75D062481B8`.
The strict gate passed for 151 project objects, 386 linked/runtime objects,
278,962 relocated executable instructions, 529 startup instruction rows, and
9,207 CWSDPMI provider instructions. It found zero above-i486 or unknown
instructions, exemptions, skipped bytes, or unmatched instruction sites.
DOSBox-X exited with code 0 and reported `486 benchmark correctness PASS`.

The refreshed ownership report,
`out/profile-a166cf63a9f3711b/renderer-ownership-qbench.json`, lists 75 directly
reachable renderer C entries, one fewer than the prior snapshot. It no longer
lists `Con_DrawConsole`; notification drawing and other console, menu, and
video/cache support remain C-owned.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/client/console.c:Con_DrawConsole` | `src/client/con_inputasm.s:Con_DrawConsole_asm486` | Five exact framebuffer/state cases through DOSBox-X; input callee separately passes 21 cases x four x87 modes | Strict linked-object, final-executable, startup, and provider gates pass with zero exemptions |

This is console composition support, not a 3D rendering routine. It does not
cover `Con_DrawNotify`, logging, menu composition, complete screen stress, or a
new whole-game FPS measurement. The 3D procedures selected by the current
i486 assembly profile were already assembly-backed before this support slice.
