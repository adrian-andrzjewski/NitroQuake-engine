# Console scrollback insertion i486 assembly port (2026-10-18)

## Behavior and selector

`src/client/console.c:Con_Print` performs word-boundary wrapping, writes bytes into
the scrollback ring, tracks carriage returns and color markers, advances
console rows, and marks the notify timestamps. `Con_Linefeed` advances and
clears one ring row. Both now have i486 implementations in
`src/client/con_inputasm.s`, selected by the existing
`ConsoleImplementation=asm` profile. The C-reference profile continues to
select the original C routines, and BENCH keeps independent C oracle state.
The talk marker still calls `S_LocalSound("misc/talk.wav")` in release builds;
the direct fixture routes that call through a recording hook.

## Direct C/assembly parity

The focused fixture compares the complete 16 KiB scrollback, guard words,
line/current/backscroll state, carriage-return state, all notify timestamps,
sound calls and callee-saved-register ABI. Nine cases cover word wrapping,
newline, ring wrap, both color markers, talk-sound dispatch, carriage returns
across calls, high-bit bytes, pending carriage-return state, and empty input.
All nine cases pass across four x87 rounding modes. A separate direct
`Con_Linefeed` case compares the complete buffer and state.

The focused command was:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 `
  -ConsoleInputOnly -ConsoleImplementation asm -CpuTarget i486 `
  -NoBootstrap -TimeoutSeconds 180
```

DOSBox-X exited with code 0 and reported `486 benchmark correctness PASS`.
The result is `out/dos-bench-20261018-090425/bench-result.json`.

## Strict i486 verification and current ownership

The focused BENCH executable passed its complete strict gates: 247,600 project
object instructions, 285,897 linked object instructions, 285,897 relocated
executable instructions, 529 startup rows and 9,207 CWSDPMI provider
instructions. The audit found no above-i486 or unknown instructions, exemptions,
unmatched sites or undecoded bytes.

The refreshed full assembly-profile ownership report at
`out/profile-c8482542de108dbc/renderer-ownership-qbench.json` lists 379
directly reachable renderer entries and 53 directly reachable C dependencies.
That is 326/379, or about 86.0% assembly-owned by reachable-symbol count. The
inventory has 67 unresolved direct callees and `completeCallGraph=false`, so
this remains a rough profile-specific estimate, not a code-size or complexity
percentage.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/client/console.c:Con_Print` | `src/client/con_inputasm.s:Con_Print` | Nine exact scrollback, wrapping, notify-time, marker, guard and ABI cases across four x87 rounding modes | Strict BENCH object, linked executable, startup and provider gates pass |
| `src/client/console.c:Con_Linefeed` | `src/client/con_inputasm.s:Con_Linefeed` | Complete ring-buffer, guard, state and ABI comparison; also exercised by every print case that starts a new row | Strict BENCH object, linked executable, startup and provider gates pass |

This ports console text insertion and linefeed. Formatting in `Con_Printf`,
debug logging, console rendering composition and unrelated menu/video paths
remain separate work. The fixture verifies exact behavior; it does not report
FPS.
