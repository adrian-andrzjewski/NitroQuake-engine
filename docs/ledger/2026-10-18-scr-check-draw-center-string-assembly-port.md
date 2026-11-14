# `SCR_CheckDrawCenterString` i486 assembly port (2026-10-18)

## Behavior and selector

`src/client/screen.c:SCR_CheckDrawCenterString` sets `scr_copytop`, grows
`scr_erase_lines` to cover the current center string, subtracts the double
`host_frametime` from the float center-message timer, preserves live messages
during intermission, and draws only while the game owns the key destination.

`src/client/screen_centerasm.s:SCR_CheckDrawCenterString` now owns this per-frame
timer and dispatch under `ScreenCenterStringImplementation=asm`. Its x87
subtraction preserves the C double-timestep/float-result behavior. The selected
release omits the C body; BENCH retains it as
`SCR_CheckDrawCenterString_Screen_C` for direct comparison.

## Direct C/assembly parity

`Bench486ScreenCenterCheckCases` compares 11 timer, intermission, key-destination,
erase-line and draw-dispatch states. It checks the resulting globals, exact
timer bits, unchanged frame-time bits, draw count, x87 control word, and
callee-saved-register ABI. The cases include timer expiry boundaries, negative
zero, the single-precision subtraction boundary, and the smallest positive
subnormal.

All 11 cases passed for each of three x87 precision modes and four rounding
modes. The existing center-string fixture also passed its 19 cases, along with
the live 8/16-bit character framebuffer check and `486 benchmark correctness
PASS`.

## Strict i486 build and execution

The command was
`tools/bench-dos.ps1 -ScreenCenterStringOnly -ScreenCenterStringImplementation asm -CpuTarget i486 -NoBootstrap -TimeoutSeconds 180`.
DOSBox-X exited with code 0. The strict gate verified 246,214 project-object
instructions and 284,511 linked-object and relocated executable instructions,
plus 529 startup instruction rows and 9,207 CWSDPMI provider instructions. It
found zero above-i486 or unknown instructions and zero exemptions, skipped
instruction bytes, or unmatched sites.

The result is recorded in
`out/dos-bench-20261018-071154/bench-result.json`. The refreshed ownership
report, `out/profile-c8482542de108dbc/renderer-ownership-qbench.json`, contains
378 directly reachable renderer entries, 55 directly reachable C entries, and
66 unresolved direct callees. That is approximately 85.4% assembly-owned by
reachable-symbol count. This remains a profile-specific proxy because the call
graph is incomplete and it does not weight routines by size or complexity.

## Traceability and remaining scope

| C reference | Assembly entry | Direct fixture | i486 evidence |
| --- | --- | --- | --- |
| `src/client/screen.c:SCR_CheckDrawCenterString` | `src/client/screen_centerasm.s:SCR_CheckDrawCenterString` | Eleven timer/state/draw/ABI cases across 12 x87 settings | Focused strict BENCH i486 object, linked executable, startup, and provider audits pass with zero exemptions |

This slice ports the center-message timer and draw decision. It records
correctness and instruction compatibility, not an FPS measurement. Other
screen/menu composition and unresolved renderer call paths remain open.
