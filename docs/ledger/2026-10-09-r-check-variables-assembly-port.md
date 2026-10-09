# `R_CheckVariables` assembly port (2026-10-09)

## Per-frame fullbright cache check

`R_CheckVariables` in `src/r_misc.c` compares the current `r_fullbright` value
with its saved value and flushes surface caches when it changes. The assembly
implementation is `src/r_checkvariables_asm.inc`, included by
`src/v_viewcontrolasm.s` under `ASM486_VIEW_CONTROL`; it preserves the C
reference's x87 comparison and cache-flush behavior. The C implementation is
retained as the BENCH486 oracle.

## R_CheckVariables verification

The dedicated raw-float C/assembly fixture passed 180 cases across 12 x87
control modes. The integrated, aggressive BENCH486 profile with all 84
selectors set to assembly passed 18,176 cases across 13 entries and 12 x87
control modes, including 8,192 sequence calls and 16 guard checks.

The full candidate executable and runtime ISA gate passed: 245,178 relocated
instructions, 353 source-bound contributions, and 1,844 linked ranges were
checked, along with 529 startup rows and 9,207 provider instructions. It found
zero instructions above i486 and zero exemptions.

## Parity and scope boundary

Exact C-reference versus 84-selector assembly parity passed under DOSBox-X
i486 emulation in `out/render-parity-rcheck-20261009`. The source-tree
fingerprints match. All three scenarios passed: `demo1-viewsize-50`,
`demo2-entity-workload`, and `demo3-world-workload`. After ignoring six startup
frames per scenario, all 3,029 compared per-frame checksums matched. Each
frame-169 320x200 capture also matched all 64,000 palette indices and the full
palette, with zero mismatches. The report is
`out/render-parity-rcheck-20261009/render-parity-result.json`.

The paired single-run median FPS readings (reference / assembly) were 18.06 /
17.68, 12.78 / 12.70, and 12.17 / 11.92 for those scenarios. They show no
catastrophic regression in this slice, but are not a broad performance survey.
The assembly path remains selectable and this checkpoint does not complete the
renderer migration. An earlier baseline-only diagnostic failure did not use
the integrated profile and is not recorded as an accepted regression.
