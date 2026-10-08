# Alias-model line-scan setup assembly port

## `D_PolysetSetUpForLineScan` edge-step setup

`AliasLineScanImplementation=c|asm` selects the C reference or
`D_PolysetSetUpForLineScan_asm486`. Assembly is the i486 default. For
`tm,tn` in the original `[-31,32]` window it reads the same 64-by-64
`adivtab` entries, including the table's historical values for non-positive
small heights. A compile-time size assertion pins each table entry to two
32-bit integers. Larger positive heights use 32-bit `idiv` and the original
floor quotient/remainder correction. The non-positive large-height case calls
the C helper so its `FloorDivMod` error path remains intact.

The assembly routine uses cdecl arguments and preserves EBP. It does not use
the x87 unit. Its negative-edge branch follows the reference compiler's
32-bit quotient and magnitude-remainder sequence, including the tested
`INT_MIN` case. No post-i486 instructions are used.

## Direct fixture and 486 ISA audit

`-benchaliaslinescan` compares `ubasestep`, `erroradjustup`,
`erroradjustdown`, and `errorterm` from C and assembly. It sweeps all 4,096
small-table pairs in four x87 rounding modes, then tests eight longer positive
edges, including `INT_MIN` and `INT_MAX` coordinates. All 16,416 comparisons
passed with zero mismatches. Large non-positive heights are excluded because
the reference calls `FloorDivMod`, which reports an error for those inputs.

The focused BENCH object audit covered 103 objects and 180,751 instruction
sites; the complete object closure covered 338 objects and 222,263 sites. The
linked audit verified 219,516 opcode sites across 235 runtime inputs and 333
executable `.text` ranges. The selected renderer gate reported zero enforced
above-i486 instructions and zero unknown opcodes. Enumerated third-party
runtime and data exemptions remain visible in the reports. Results are in
`out/dos-bench-20261007-014828/bench-result.json` and the associated
`isa-audit*.json` files.

## Paired gameplay parity

The focused `i486-asm-alias-line-scan` profile changes only
`AliasLineScanImplementation` from `i486-c-reference`. Both profiles passed
`demo2-entity-workload` with the same source-tree fingerprint
`C3A0ED276C05FD4940F1220BFE40CB7FA48ACE319AFD2266C58DB1291E564EAD`.

Each profile completed two 985-frame runs. All 980 post-warmup frame checksums
matched on both repeats. Frame-169 captures were exact on both repeats: all
64,000 palette indices and all 768 palette bytes matched. The report is
`out/render-parity-20261007-014849/render-parity-result.json`. Median
throughput was 12.79 fps for C and 12.75 fps for assembly; this small difference
is diagnostic only.
