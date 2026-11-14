# `Con_DrawInput` -> i486 console-input overlay candidate (2026-10-10)

## Original C behavior and ownership boundary

`src/client/console.c:Con_DrawInput` returns without touching input state or pixels
when the console is neither the active key destination nor forced visible. When
visible, it writes the cursor character as
`10 + ((int)(realtime * con_cursorspeed) & 1)`, blanks the rest of the visible
input line, scrolls the text start when `key_linepos >= con_linewidth`, draws
`con_linewidth` glyphs at `x = (i + 1) << 3` and `y = con_vislines - 16`, then
clears the original cursor cell while retaining the blank tail.

This slice owns that input-line orchestration only. The assembly calls the
existing `Draw_Character` symbol for each glyph; glyph rasterization and its
selected drawing backend remain a separate ownership item. `Con_DrawConsole`,
`Con_DrawNotify`, other console overlays, and the `screen.c` update path are not
part of this conversion.

## Assembly mapping and x87 behavior

`src/client/con_inputasm.s:Con_DrawInput_asm486` is the direct replacement, and
`ConsoleImplementation=asm` selects it for public `Con_DrawInput`. The original
C body remains available as `Con_DrawInput_Console_C` in BENCH486 builds. The
assembly uses the 32-bit DJGPP cdecl convention, preserves EBX/ESI/EDI/EBP and
uses EAX/ECX/EDX plus x87 as scratch.

The cursor calculation deliberately follows the reference's x87 computation.
It multiplies the loaded cursor speed by the double `realtime` while the
incoming x87 rounding mode is active, then temporarily selects round-toward-
zero for `FISTP`, which implements the C cast's truncation toward zero, and
restores the caller's control word. It does not use `FISTTP`; the source pins
`.arch i486` and `.arch .387`.

## Direct C/assembly fixture

`src/tests/bench486/bench486_console_input.h:Bench486ConsoleInputCases` compares the C oracle,
direct assembly entry, and selected public entry through the ABI checker. Its
21 directed cases are evaluated under all four x87 rounding modes. They cover
hidden and forced-visible input, both cursor parities, truncation boundaries,
blank tails, scroll boundaries, clipping, and the last byte of a command line.
The fixture compares console state and the bounded indexed framebuffer, checks
frame/font canaries, and restores the saved globals and x87 environment. The
DOSBox-X i486 run passed all 21 cases under all four rounding modes: C oracle,
direct assembly, and public entry state/framebuffer comparisons were exact,
with zero ABI, canary, or parity failures.

## ISA validation and current status

The focused i486 profile passed the complete executable compatibility gate.
The audit examined 372 linked objects (208,750 instructions), matched all 366
source-bound executable text contributions and 208,750 relocated instructions,
and decoded 208,750 instructions from the final executable. It found zero
post-i486 instructions, unknown instructions, exemptions, or unexplained text
bytes. The embedded startup proof covered 529 instruction rows, and the
maintained CWSDPMI provider passed for 9,207 instructions with one runtime
variant. The complete command was
`tools/bench-dos.ps1 -ConsoleInputOnly -ConsoleImplementation asm -CpuTarget i486 -NoBootstrap`;
its DOSBox-X run and all audits passed. The tested `qbench.exe` SHA-256 was
`189F5035EF3C1D033364A61AB860598FE907F2B4573BC323B7B458CDD518578C`. This
evidence applies to the selected executable and its linked/support/runtime path.
It does not establish full-scene visual parity or complete renderer conversion.

## Traceability and remaining scope

| Reference behavior | Assembly implementation | Correctness fixture | Compatibility check |
| --- | --- | --- | --- |
| `src/client/console.c:Con_DrawInput` | `src/client/con_inputasm.s:Con_DrawInput_asm486` | `src/tests/bench486/bench486_console_input.h:Bench486ConsoleInputCases`; 21 directed cases x four x87 modes, exact C/ASM/public state and framebuffer parity in DOSBox-X | Strict linked-object, final-executable, startup and provider i486 audits passed; zero violations or exemptions |

This candidate covers one console input overlay routine. It does not close
console text/background/notify drawing, status-bar or menu overlays, screen
update ownership, or full renderer parity.
