# Alias-model skin-table assembly port

## D_PolysetUpdateTables cached skin-row lookup

`AliasSkinTableImplementation=c|asm` selects the C reference or
`D_PolysetUpdateTables_asm486`. Assembly is the i486 default. The routine
compares the same two cache-key values, `skinwidth` and `skinstart`, then fills
the existing 480-entry pointer table with byte-stride rows. A compile-time
assertion pins the table count. The assembly preserves EBX, ESI, and EDI and
uses only 386 integer instructions.

## Direct skin-table fixture and 486 ISA audit

`-benchaliasskintable` checks four legal skin widths, cache hits, width-only
misses, pointer-only misses, and combined misses. It compares all 480 row
pointers and the cached values under four x87 rounding modes. All 64 cases
passed with zero mismatches.

The focused BENCH audit covered 103 objects and 181,488 instruction sites; the
complete object closure covered 338 objects and 223,000 sites. The linked
audit verified 220,266 opcode sites across 235 runtime inputs and 333
executable `.text` ranges. The selected renderer gate reported zero enforced
above-i486 instructions and zero unknown opcodes. Enumerated third-party
runtime and data exemptions remain visible in the reports. Results are in
`out/dos-bench-20261007-025507/bench-result.json` and its `isa-audit*.json`
files.

## Skin-table paired gameplay parity

The focused `i486-asm-alias-skin-table` profile changes only
`AliasSkinTableImplementation` from `i486-c-reference`. Both profiles passed
`demo2-entity-workload` with the same source-tree fingerprint
`C7FCD3C88A2E621B9483D9E61B25EDDD1114F46A1B33F0FDA1FC2563F3807066`.

Each profile completed two 985-frame timedemo runs. All 980 post-warmup frame
checksums matched on both repeats. Frame-169 captures were exact on both
repeats: all 64,000 palette indices and all 768 palette bytes matched. The
report is `out/render-parity-20261007-025523/render-parity-result.json`.
Both profiles measured 12.79 fps median; this is diagnostic only.
