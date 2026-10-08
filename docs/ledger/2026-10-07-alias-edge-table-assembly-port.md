# Alias-model edge-table assembly port

## D_PolysetSetEdgeTable 12-way triangle edge selection

`AliasEdgeTableImplementation=c|asm` selects the C reference or
`D_PolysetSetEdgeTable_asm486`. Assembly is the i486 default. It applies the
original signed Y comparisons, including all equal-Y cases, and stores the
selected pointer from the existing 12-entry `edgetables` array. A compile-time
assertion pins the C table entry to 36 bytes, the layout used by the assembly
address calculation. The helper uses only 386 integer instructions and caller-
saved registers; it has no x87 or stack state.

## Direct edge-selection fixture and 486 ISA audit

`-benchaliasedgetable` compares the C and assembly table pointers for every
combination of seven signed Y values, including `INT_MIN`, `INT_MAX`, ties, and
strict orderings, under all four x87 rounding modes. The 1,372 cases passed
with zero mismatches and no rounding-control changes.

The focused BENCH audit covered 103 objects and 181,126 instruction sites; the
complete object closure covered 338 objects and 222,638 sites. The linked audit
verified 219,881 opcode sites across 235 runtime inputs and 333 executable
`.text` ranges. The selected renderer gate reported zero enforced above-i486
instructions and zero unknown opcodes. Enumerated third-party runtime and data
exemptions remain visible in the reports. Results are in
`out/dos-bench-20261007-022734/bench-result.json` and its `isa-audit*.json`
files.

## Edge-table paired gameplay parity

The focused `i486-asm-alias-edge-table` profile changes only
`AliasEdgeTableImplementation` from `i486-c-reference`. Both profiles passed
`demo2-entity-workload` with the same source-tree fingerprint
`60CAA57C0B9E9878E29A131E72E0286A4BC8F836D4747855F106CCFF4BF693FE`.

Each profile completed two 985-frame timedemo runs. All 980 post-warmup frame
checksums matched on both repeats. Frame-169 captures were exact on both
repeats: all 64,000 palette indices and all 768 palette bytes matched. The
report is `out/render-parity-20261007-022802/render-parity-result.json`.
Both profiles measured 12.79 fps median; this is diagnostic only.
