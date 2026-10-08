# Alias-model skin setup assembly port

## `R_AliasSetupSkin` single and grouped skin resolution

`AliasSetupSkinImplementation=c|asm` selects a 32-bit assembly helper for
resolving an alias model skin descriptor. The public C wrapper retains the
entity skin range diagnostic and fallback to skin zero, then continues to fill
the affine raster descriptor and seam-fixup fields. The C reference and
assembly helper receive the normalized skin index, `cl.time`, and entity
syncbase explicitly.

The helper handles single skins and animated skin groups. Relative offsets,
12-byte descriptor strides, enum values, and the `aliashdr_t` skin-descriptor
field are pinned by compile-time layout assertions. Group time uses the
original x87 addition, period division, truncation-toward-zero quotient, and
strict interval comparison. EBX, ESI, and EDI are preserved, and the x87
control word is restored.

## Skin resolver direct C/assembly fixture and ISA audit

The focused `bench486` fixture compares the returned descriptor pointer with
the C reference and an expected fixture offset. It covers single skins,
three-skin and one-skin groups, exact interval boundaries, period wrap,
negative-time truncation, syncbase, and a large boundary. Four x87 rounding
modes exercise each scenario, for 56 exact pointer comparisons.

Run the fixture with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -AliasSetupSkinOnly -AliasSetupSkinImplementation asm`.
All 56 comparisons passed under DOSBox-X configured as a 486, with the x87
control word preserved. The selected BENCH audit covered 103 objects and
199,423 instruction sites; the complete BENCH object closure covered 338
objects and 240,935 instruction sites. Both gates reported zero enforced
post-i486 instructions and zero unknown opcodes. The linked audit verified
238,185 opcode sites across 235 runtime inputs and 333 executable `.text`
ranges. The focused result is
`out/dos-bench-20261007-003805/bench-result.json`; ISA reports are in
`out/dos-memasm-fillrectasm-zpointasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-aliaskinasm-lightmapstylesasm-fusedlightmapasm-dlightasm/`.

## Skin resolver paired gameplay parity

The focused `i486-asm-alias-skin` profile changes only
`AliasSetupSkinImplementation` from the C reference profile. Both profiles
passed the pinned `demo2-entity-workload`; the shared source-tree fingerprint
is `86EA558304B160F8CA27EA1C17CD4FEB66B677E0C9D4BD0BA7DA11E23EF8EC7F`.

Each profile completed two 985-frame runs and recorded 986 checksum entries
including startup. All 980 post-warmup checksums matched on each repeat. The
frame-169 captures matched exactly on both repeats: 64,000 palette indices
and all 768 palette bytes, with zero pixel or palette differences. The pair
report is `out/render-parity-20261007-003815/render-parity-result.json`. Median
throughput was 12.805405 fps for C and 12.8052125 fps for assembly; this small
difference is not a performance claim.
