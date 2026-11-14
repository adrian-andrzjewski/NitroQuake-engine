# Alias-model gradient setup assembly verification

## `D_PolysetCalcGradients` x87 gradient setup

`AliasGradientImplementation=c|asm` selects between the retained C reference and
the existing `D_PolysetCalcGradients_asm486` routine in `src/renderer/d_polysa.s`. The
i486 default remains assembly, matching the pre-selector path. The C helper
keeps the reference formula available for direct testing and paired renders.

The legacy edge walker leaves the integer triangle determinant in
`d_xdenom_int` and the reciprocal float bits in `d_xdenom`. The C reference
consumes the integer determinant, while the assembly gradient path consumes
the reciprocal. The wrapper temporarily presents the integer value to C and
restores the reciprocal afterward, keeping both call boundaries explicit.
The assembly path uses the existing x87 operation sequence and its established
control-word behavior; the fixture checks C's caller-control-word preservation
and the assembly path's `single_cw` result.

## Gradient direct fixture and 486 ISA audit

`-benchaliasgradients` compares eleven gradient outputs between C and assembly
in eight deterministic cases. The outputs cover light, S/T/Z X and Y steps,
and the derived affine steps. All eight cases passed under DOSBox-X configured
as an i486. The focused BENCH object audit covered 103 objects and 200,496
instruction sites; the complete object closure covered 338 objects and
242,008 sites. The linked audit verified 239,251 opcode sites across 235
runtime inputs and 333 executable ranges. The gates reported zero enforced
above-i486 instructions in the selected renderer objects and linked executable;
enumerated third-party runtime and data exemptions remain visible in the
reports. Results are in `out/dos-bench-20261007-010431/bench-result.json` and
the associated `isa-audit*.json` files.

## Gradient paired gameplay parity

The focused `i486-asm-alias-gradient` profile changes only
`AliasGradientImplementation` from `i486-c-reference`. Both profiles passed
`demo2-entity-workload` with the same source-tree fingerprint
`DAAD43E3DA35EB1A82846643E99CE371B333D406604FBD5172116BDA16783A14`.

Each profile completed two 985-frame runs. All 980 post-warmup frame checksums
matched on both repeats. The frame-169 captures were exact on both repeats:
64,000 palette indices and all 768 palette bytes matched. The paired report is
`out/render-parity-20261007-010817/render-parity-result.json`. Reported median
throughput was 12.79 fps for C and 12.80 fps for assembly; this small difference
is not a performance claim.
