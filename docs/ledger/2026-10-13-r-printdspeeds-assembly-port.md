# R_PrintDSpeeds i486 assembly slice (2026-10-13)

## Original routine and selector

| Reference behavior | Assembly implementation | Exact fixture |
| --- | --- | --- |
| `src/renderer/r_misc.c:R_PrintDSpeeds` | `src/renderer/r_printtimesasm.s:R_PrintDSpeeds` | `src/tests/bench486/bench486_printtimes.h:Bench486PrintDSpeedsCases` |
| The six stage intervals and total frame milliseconds | The original x87 evaluation order, `1000.0f` constant and three truncating integer casts | Six stage-time pairs and fixed timer values compared through Quake's console ring |

`PrintTimesImplementation=asm` now selects both timing diagnostics. The C body
remains the normal implementation when the selector is `c`; in BENCH486 builds,
`R_PrintDSpeeds_C` is retained as the oracle. The assembly calls the existing
fixed-clock hook only in the fixture build and calls `Sys_FloatTime` in a normal
build.

The cdecl routine receives its clock result in x87 `ST(0)`, formats the values in
the same argument order, and calls `Con_Printf`. Each `(int)` conversion saves
the caller's control word, selects truncation toward zero, performs `FISTP`, and
restores the saved word. It uses only 486-valid integer instructions and 387
x87 instructions. It does not write renderer state.

## 24-case console and ABI parity

The fixture compares C and assembly console buffers and state for six cases:
zero, positive fractional intervals, negative intervals, cast boundaries,
large in-range signed integers, and repeated output through the console ring.
Each case runs under all four x87 rounding modes, for 24 exact comparisons. It
also checks untouched stage inputs, console canaries, output pointer, timer-call
count, cdecl register/stack state, x87 control word, and x87 stack depth. All 24
comparisons passed. The existing `R_PrintTimes` fixture also passed its seven
cases in the same DOS run.

## Complete i486 build audit

The selected `PrintTimesImplementation=asm` build passed the strict instruction
gate:

- 174,360 selected-object instructions: zero above i486, unknown, or exempt.
- 212,657 linked-input and relocated-executable instructions: zero above i486,
  unknown, or exempt; no unmapped executable bytes.
- 529 startup instruction rows and 9,207 CWSDPMI provider instructions passed
  with zero exemptions.
- The renderer-ownership report no longer lists `_R_PrintDSpeeds` as C-owned;
  `_Bench486PrintTimesTime` remains only as the BENCH fixture clock hook.

Artifacts are under `out/dos-bench-20261013-024548/` and
`out/profile-ab41339813021047/`. The strict DOSBox-X run reported
`printdspeeds exact console/state PASS (24 comparisons; 0 failures)` and
`486 benchmark correctness PASS`.

## Reproduction command and limits

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -CpuTarget i486 -PrintTimesOnly `
  -PrintTimesImplementation asm -TimeoutSeconds 180
rtk python tools/test-rendering.py
rtk python tools/test-build-dos.py
```

This closes the stage-timing diagnostic entry only. The full screen/update path,
status-bar and menu drawing, broader renderer ownership, and full-gameplay
stability coverage remain open.
