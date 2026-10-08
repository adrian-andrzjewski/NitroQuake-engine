# Alias-model vertex preparation assembly path

## `R_AliasPreparePoints` per-vertex transform and clip setup

`AliasPrepareImplementation=control|local|asm` selects the C reference loop,
the local C-loop variant, or `R_AliasPreparePointsVertices_asm486` in
`src/asm486_experiments.s`. Assembly is now the i486 default. `control` and
`local` receive distinct profile suffixes, so neither can overwrite the
release build.

The assembly loop walks the same final-vertex, auxiliary-vertex, source-vertex,
and texture-vertex arrays. It calls the independently selected final-vertex
transform and project routines, compares the transformed depth with the
original 5.0 near plane, and sets the same Z and screen-edge clip bits. It
publishes the advanced source-vertex pointer to `r_apverts`, matching the C
loop's post-increment state. The entry uses cdecl, preserves EBX, ESI, EDI, and
EBP, and has an eight-byte local area for its texture-vertex cursor and count.

## i486 object audit and exact Demo 2 parity

The focused `i486-asm-alias-prepare` profile changes only
`AliasPrepareImplementation` from `i486-c-reference`. Its selected object audit
examined 103 objects and 180,786 instruction sites; the complete object closure
examined 338 objects and 222,298 sites. The linked audit verified 219,568
opcodes across 235 runtime inputs and 333 executable `.text` ranges. No
enforced instruction above i486 was found. Selected renderer objects had no
unclassified instructions; the third-party runtime and data exemptions remain
enumerated in the build report.

Both profiles passed `demo2-entity-workload` using the same source-tree
fingerprint
`EDB3D076C66B00CBF097E0872A0A28F1A5DCE39EBA7B8563F0CDD71F8A8C980A`. Each
completed two 985-frame runs, with all 980 post-warmup frame checksums matching
exactly on both repeats. Frame-169 captures also matched exactly: all 64,000
indexed pixels and all 768 palette bytes. The report is
`out/render-parity-20261007-035422/render-parity-result.json`.

## Release-default timing note

The diagnostic median was 12.784987 fps for the C control path and 12.766575
fps for assembly, about 0.14% lower in this run. This small difference is not
an optimization claim. The assembly path becomes the default because the
two-repeat pixel and checksum comparisons were exact and the emitted code
passed the i486 gate.
