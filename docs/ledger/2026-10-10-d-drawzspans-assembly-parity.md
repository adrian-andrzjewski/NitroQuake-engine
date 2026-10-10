# `D_DrawZSpans` -> exact i486 assembly parity (2026-10-10)

## Traceability and scope

`src/d_scan.c:D_DrawZSpans` is the C reference and
`src/d_draw.s:D_DrawZSpans` is the active 32-bit assembly routine. The C body is
retained as `D_DrawZSpans_C` in BENCH486 builds for direct comparison; normal
non-`id386` builds retain the original C symbol. This work verifies and corrects
the existing assembly-owned depth-span path; it does not convert the rest of
the surface renderer.

The trace is:

| Reference or implementation | Role | Verification |
| --- | --- | --- |
| `src/d_scan.c:D_DrawZSpans_C` | Original C depth-step and packed-word behavior | `src/bench486_zspans.h` direct fixture |
| `src/d_draw.s:D_DrawZSpans` | Runtime i486 depth-span routine | Exact DOSBox-X fixture and strict executable audit |
| `D_DrawSurfaces` in `src/d_edge.c` | Supplies gradients and negative `SURF_DRAWBACKGROUND` depth | `background-depth` fixture case |

## Arithmetic, stores, and ABI

The routine computes the initial inverse depth and horizontal step in x87, then
stores the high 16 bits of each 32-bit fixed-point sample. The C float-to-int
casts truncate toward zero. The assembly therefore saves the incoming x87
control word, selects truncate mode for each `FISTP`, and restores the original
word. It also restores the caller's x87 stack depth and the cdecl callee-saved
registers.

The C pair-store expression uses signed `izi >> 16` before ORing in the next
sample. For negative inverse depth that sign-extends the upper word to `0xffff`.
This output is observable: `D_DrawSurfaces` sets `d_ziorigin` to `-0.9` for
`SURF_DRAWBACKGROUND`. The assembly preserves that packed output for both
gradient and zero-step spans. The span-pair loops are kept direct and readable;
the previous unrolled sequence reused a pair's terminal sample as the next
pair's starting value. Its unused `ZSpanNegativeUnroll` option was retired with
the unrolled path.

## Direct differential fixture

The fixture compares complete guarded depth buffers for nine gradients: flat,
positive and negative horizontal gradients, negative depth, a fractional
truncate boundary, the maximum-depth clamp boundary, positive and negative
vertical gradients, and Quake's `-0.9` background depth. It crosses thirteen
span lengths (1 through 33, including word and pair boundaries), three linked
spans, both destination alignments and multiple x87 state checks. It compares
every buffer byte and checks callee-saved-register status, x87 control-word
restoration and x87 stack top.

DOSBox-X on the i486-target build passed **117 exact buffer cases with zero
mismatches**. The report is
`out/dos-bench-20261010-190048/quake/bench486.txt`; the runner result is
`out/dos-bench-20261010-190048/bench-result.json`.

## Strict i486 audit

The normal `-CpuTarget i486` build and runtime gate passed without exemptions:

- 140 initial objects: 171,848 decoded instructions, zero above i486 and zero
  unknown.
- 375 linked-input objects: 210,145 instructions, zero above i486 and zero
  unknown.
- Linked executable: all 210,145 mapped opcodes checked across 368 executable
  ranges; zero unknown bytes, post-i486 instructions, or exemptions.
- Startup loader: 1,660 loaded bytes and 529 audited CODE rows. `sbrk16`,
  `exit16`, and the 9,207-instruction CWSDPMI provider also passed.

The reports live under `out/profile-1981d7617a5f4c91/isa-qbench/`, including
`isa-audit.json`, `isa-audit-linked-objects.json`, `isa-audit-linked.json`, the
relocated `strict-isa.json`, startup helper reports and `provider-proof.json`.

## Reproduction and limits

From `quake/`, rerun the focused fixture and full strict gate with:

```powershell
rtk python tools/test-rendering.py
rtk pwsh -NoProfile -ExecutionPolicy Bypass -File tools/bench-dos.ps1 -CpuTarget i486 -ZSpansOnly -NoBootstrap -DataRoot testdata\id1 -TimeoutSeconds 240
```

This is exact routine-level depth-buffer parity on a 486DX-class x87 target and
strict machine-code evidence for the selected executable and providers. It is
not a full-scene acceptance run, physical 486 hardware test, or completion of
the broader renderer migration.
