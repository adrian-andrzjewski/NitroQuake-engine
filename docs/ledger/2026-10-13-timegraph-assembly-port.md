# R_TimeGraph i486 assembly slice (2026-10-13)

## Mapping

| Reference behavior | Assembly implementation | Exact fixture |
| --- | --- | --- |
| `src/renderer/r_misc.c:R_TimeGraph` | `src/renderer/r_timegraphasm.s:R_TimeGraph` / `R_TimeGraph_asm486` | `src/tests/bench486/bench486_timegraph.h:Bench486TimeGraphCases` |
| 100-byte history ring and `timex` | `r_timegraph_state.h`, with offsets pinned in `asm_timegraph.h` | independent ring and pixel model in `bench486_timegraph.h` |
| Calls `R_LineGraph` for each history column | public `R_LineGraph` entry, selected independently by its own selector | TimeGraph ASM run keeps `LineGraphImplementation=c` |

The assembly keeps the source expression order: `Sys_FloatTime()`, subtract
`r_time1`, multiply by the single-precision `100.0` constant, then convert with
`FISTP` while the x87 control word temporarily selects truncation toward zero.
It stores the result as a byte, places up to 100 columns using the original
viewport-width rule, walks the ring backward, stops at x=0, and advances the
ring index with the same modulo-100 behavior.

The cdecl routine takes no arguments, preserves EBX/ESI/EDI/EBP, restores the
x87 control word, and returns with the same x87 stack depth. The source declares
`.arch i486` and `.arch .387`; the build's exact-object and linked-executable
audits check the emitted code and support/runtime inputs.

## Deterministic parity

`bench486_timegraph.h` runs 257 consecutive frames under each of the four x87
rounding modes. Its input sequence crosses the 100-entry ring twice and includes
positive, negative, fractional, byte-wrapping, and greater-than-graph-height
samples. Five viewport widths cover the left-edge early exit and full-width
history placement. An independent model paints the expected indexed pixels and
tracks expected ring state. C and assembly results are checked after every
frame, byte-for-byte, including row padding and outer canaries. The test also
checks the x87 control word and stack top before and after every call. Progress
is reported every 64 frames.

The C reference-only run passed 1,028 frames. The assembly run passed the same
1,028 frames with zero pixel, ring, canary, control-word, or x87-depth
mismatches. Both DOSBox-X runs exited with code 0 and reported
`486 benchmark correctness PASS`.

## i486 verification

The assembly benchmark's complete gate reported:

- 173,382 project-object instructions: zero above i486, unknown, or exempted.
- 211,679 linked object instructions and 211,679 relocated executable
  instructions: zero above i486, unknown, exempted, or unmapped bytes.
- DOS startup and CRT helper checks passed; all 529 startup CODE rows and 9,207
  provider instructions were checked with zero exemptions.
- Source-to-binary mapping passed for 370 linked contributions.

The retained run artifacts are under
`out/profile-7f8c12ab28a5de06/isa-qbench/` and
`out/dos-bench-20261013-005106/`. The matching C reference run is under
`out/dos-bench-20261013-002929/`.

## Reproduction instructions

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -CpuTarget i486 -TimeGraphOnly `
  -TimeGraphImplementation asm -LineGraphImplementation c `
  -TimeoutSeconds 180
```

Run the reference fixture with `-TimeGraphImplementation c`. The benchmark
runner performs the exact object, linked executable, startup, and provider ISA
checks before launching DOSBox-X. The source/selector and profile gates are
`rtk python tools/test-build-dos.py`,
`rtk python tools/test-rendering.py`, and
`rtk pwsh -NoProfile -File tools/test-renderer-profile-completeness.ps1`.

This slice covers the optional frame-time graph overlay. It does not establish
completion of the remaining Quake renderer conversion or full-scene parity for
every renderer subsystem.
