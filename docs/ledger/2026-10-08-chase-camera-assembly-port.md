# Chase camera assembly ownership

## Original collision and camera behavior is preserved

`v_chaseasm.s` and `v_chase_reference.inc` own `Chase_Init`, `Chase_Reset`,
`TraceLine` and `Chase_Update`. The maintained 32-bit instruction stream retains
the original zeroed trace, hull zero, destination offsets, distance clamp,
atan-based pitch and final origin copy. Twenty-three compile-time layout
assertions bind the client, model, hull, trace, viewport and cvar storage.
The source and function traceability are retained in
`docs/renderer-assembly/chase-provenance.json` and `chase-reference/chase.c`.

The original C call has no hull-check prototype. Its integer literals `0, 1`
are passed as stack words `00000000, 00000001` to the callee's float parameters.
The second word is a float denormal, not float 1.0. The assembly deliberately
preserves those bits. Adding a prototype to the original call would change the
reference behavior. A separately named, typed link alias in the BENCH486 adapter
copies those exact words into floats before calling the original hull checker.

An initial fixture run timed out because its adapter used an implicit call
which promoted float arguments to doubles and shifted the pointer arguments.
That run is invalid acceptance evidence; its failure analysis is retained in
`out/chase-worktree-20261008/out/dos-bench-20261008-034324/failure-analysis.json`.
The corrected normal and profiling fixtures each pass 14,336 exact cases,
twelve x87 control words, 8,192 continuous camera calls and 48 guard checks,
with zero failures. They cover real axial/nonaxial hull traversal, solid/open/
water leaves, aliased impact pointers, large coordinates, destination clamping,
complete state and trace bytes, immutable inputs and register/stack/DF/x87 ABI.
Executed binaries and bindings are retained with the corrected fixture runs
`dos-bench-20261008-042505` and `dos-bench-20261008-042634` in the chase worktree.

## ISA, active-camera scenes and reviewed integration pass

The four release entries are assembly-owned. The release, benchmark and
profiling module audits each decode 141 i386 instructions with no unknowns or
exemptions. Complete executable gates verify 169,322 release, 234,866 benchmark
and 240,909 profiling instructions, all within i486. Startup adds 529 audited
instructions; the provider adds 9,207 and one runtime branch variant. All 35
preceding assembly modules retain identical allocated bytes and relocations.
The corrected release SHA256 is
`FAC6408547CF9908EE0D6871BBA58CF2694A83E63DE83C7F2E17487983A6F863`.
Its difference from the earlier release is confined to ten literal bytes in
Quake's original compile-time version strings; the containing code/data proofs
confirm that no instructions changed.

All three deterministic scenes explicitly enable chase with different back,
right and up offsets, including a distant camera. Both profiles run twice.
All 6,058 post-startup frame checksums and six raw indexed/palette PCX captures
match exactly. Evidence, provider/startup bindings and immutable executed
artifacts are in
`out/chase-worktree-20261008/out/render-parity-chase-verified-selection-20261008`.
Identical source-tree SHA256:
`941E6BBE9E88DD19B3AA0F0A2F63E136B5FB53A12E78DFB44A51A19C8FF88C45`.
Reference and assembly benchmark SHA256 values are
`FAF27A731CCD4AE74E9CB50292DC342C0352A3921F37CDD28434E00817C71B8C` and
`F2B89A1486962729543648C3635505C9D55FCE6ECE7DEBE38D7E783F0934E8DF`.

| Active-camera scene | C camera FPS | Assembly camera FPS |
|---|---:|---:|
| demo1-vesa-full-chase | 11.8092705 | 11.8089060 |
| demo2-entity-workload-chase | 11.7711730 | 11.7708075 |
| demo3-world-workload-chase | 8.7692470 | 8.7690425 |

There is no material performance regression. Performance does not determine
conversion acceptance. `ChaseImplementation` defaults to C; the complete
candidate profile selects assembly. Integration preserves the main smoke
runner's newer selector coverage and records its allowlist and preimages in
`out/chase-integration-preimages-20261008/manifest.json`. The expanded release
inventory still identifies eighteen directly reachable C renderer entries,
plus initialization/debug/indirect paths requiring closure. Complete frame-byte
capture, actual display palettes and dedicated full-renderer soak acceptance
remain separate outstanding gates.
