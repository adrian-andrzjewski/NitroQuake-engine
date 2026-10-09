# `R_LineGraph` -> `R_LineGraph_asm486` port (2026-10-09)

## Leaf behavior and ownership

`R_LineGraph` in `src/r_misc.c` is called by `R_TimeGraph` to paint the timing
overlay. It adds `r_refdef.vrect.x/y` to the input coordinates, computes the
destination from `vid.buffer + vid.rowbytes * y + x`, and converts
`r_graphheight.value` to `int` by truncation toward zero. It clamps `h` only
when signed `h > s`. The first loop writes `0xff` at `dest` and `0x30` one row
above for `i < h`; the second writes `0x30` to both locations for `i < s`.
Each loop advances `dest` by two rowbytes after its stores, preserving the
original store order and signed behavior for negative bounds.

The assembly implementation is `src/r_linegraphasm.s`. `_R_LineGraph` and
`_R_LineGraph_asm486` share the same entry. It uses 32-bit cdecl with
caller-saved EAX/ECX/EDX and preserved EBX/ESI/EDI/EBP. It saves the x87
control word, selects truncate mode for `FISTP`, restores the word, and leaves
the x87 stack depth unchanged. `src/asm_draw.h` defines the video, viewport,
and cvar offsets; `src/r_misc.c` checks them with `offsetof` when
`ASM486_LINE_GRAPH` is enabled.

## Selection and oracle

`LineGraphImplementation=c|asm` maps to `ASM486_LINE_GRAPH`. The focused
profile is `tools/renderer-profiles/i486-asm-line-graph.json`; its matching
C reference is `i486-c-reference.json`. The combined opt-in profile is
`i486-asm-selectable-85.json`. BENCH486 assembly builds retain the C body as
`R_LineGraph_C`. The direct-fixture entry point is
`Bench486LineGraphCases` in `src/bench486_linegraph.h`, invoked by
`-benchlinegraph`. Its seven cases compare the C oracle and assembly against an
independent expected framebuffer. They use a 72-byte stride with 64 visible
columns, check outer guards and row-padding canaries, and print progress before
each case.

## Acceptance status

The focused i486 build passed its selected-object, linked-object, executable,
startup, and runtime-provider ISA gates. The object audit decoded 164,350
instructions across 124 selected objects. The linked-object audit decoded
202,615 instructions across 359 objects; the executable audit verified the
same 202,615 relocated opcodes across 341 text ranges. Startup validation
covered 529 code rows, and the runtime provider audit covered 9,207
instructions. Every gate reported zero above-i486 instructions, unknown
opcodes, and exemptions.

The focused fixture passed in DOSBox-X with `cputype=486` and fixed 33,445
cycles. All seven cases matched byte-for-byte across the C oracle, assembly,
and independent expected framebuffer; outer guards and row-padding canaries
remained intact. The checksum was `2473286080`. The run printed a case-by-case
progress line and exited with `486 benchmark correctness PASS`.

This is direct parity evidence for the `R_LineGraph` leaf, not a whole-scene
renderer capture. `R_TimeGraph` and the broader renderer migration remain in
C and are still in progress. Reproduce the checks with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 `
  -Benchmark -LineGraphImplementation asm -NoBootstrap
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -LineGraphOnly -LineGraphImplementation asm -SkipBuild -NoBootstrap
```

The generated build and DOSBox staging directories were removed after these
results were recorded; rerunning the commands above recreates them.
