# `Con_DrawNotify` i486 assembly port (2026-10-17)

## Behavior and selector

`src/console.c:Con_DrawNotify` draws up to four recent console lines from the
timestamp ring, skips expired entries, updates the notification dirty-state,
and optionally draws the `say:` prefix, chat text and blinking cursor. The new
`src/con_inputasm.s:Con_DrawNotify_asm486` implements that logic while retaining
the original x87 timestamp comparison and the cursor conversion behavior.
Glyph and string rendering stay on the public `Draw_Character` and `Draw_String`
entry points.

`ConsoleImplementation=asm` now selects the assembly public entry through
`ASM486_CONSOLE_NOTIFY`. BENCH builds retain the C oracle as
`Con_DrawNotify_Console_C`; C selector builds keep the public C implementation.
Compile-time layout checks cover the message key, four-entry timestamp ring and
`con_notifytime.value` offset.

## Direct C/assembly parity

`Bench486ConsoleNotifyCases` covers no lines, recent messages, four-slot ring
wrap, exact and expired timestamps, empty chat, a cursor boundary and mixed
message/chat output. Each of eight cases runs under all four x87 rounding modes.
The fixture compares the complete indexed framebuffer, notification and screen
state, ABI results, frame/font guards, the direct assembly entry and the
selected public entry against the C oracle. It restores the original globals,
framebuffer and x87 environment afterward.

The DOSBox-X fixture passed with zero failures. In the same run, the existing
console-input suite passed 21 cases across four x87 modes and the console-draw
suite passed all five framebuffer/state cases.

## Strict i486 build and execution

The command was
`tools/bench-dos.ps1 -ConsoleInputOnly -ConsoleImplementation asm -CpuTarget i486 -NoBootstrap`.
The BENCH executable SHA-256 was
`9706094077393F6E3C1638A44E146120E717322F80D9B31440913DC56A96EAB6`.

The object audit checked 241,891 instructions across 151 objects. The linked
object and executable audit verified 280,188 instructions across 386 objects,
with zero instructions above i486, unknown encodings, exemptions,
non-instruction bytes or relocation data sites. The complete executable gate
also passed for 529 startup instruction
rows and 9,207 CWSDPMI provider instructions. Runtime source proof validated
235 installed objects, and final mapping bound 411 source contributions. The
DOSBox-X run exited with code 0 and reported `486 benchmark correctness PASS`.

The refreshed renderer ownership report lists 74 directly reachable renderer
C entries and no longer lists `Con_DrawNotify`. Its only direct `D_` C entries
are the DOS direct-rectangle video wrappers; production 3D `R_`/`D_` procedures
remain assembly-backed in this selected profile. This focused fixture did not
measure whole-game FPS.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/console.c:Con_DrawNotify` | `src/con_inputasm.s:Con_DrawNotify_asm486` | Eight exact C/assembly/public framebuffer and state cases across four x87 modes | Strict linked-object, final-executable, startup and provider gates pass with zero exemptions |

This is a 2D console overlay, not a 3D procedure. It does not close the
remaining console printing, menu, video/cache and screen-support ownership, or
full-screen stress and long-run validation.
