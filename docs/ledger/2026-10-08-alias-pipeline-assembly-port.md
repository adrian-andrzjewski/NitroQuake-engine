# Alias pipeline assembly ownership

## Original transforms, clipping and model state are preserved

`r_aliascontrolasm.s` owns nine original alias pipeline entries: bounding-box
acceptance, clipped and unclipped point preparation, transform setup, final
vertex projection, skin/light/frame setup and `R_AliasDrawModel`. Bounds,
transforms, control flow and constants remain separate release/profile include
files. The normal build assembles maintained sources; it does not generate
assembly from C. Original source, function hashes, instruction variants and 103
layout facts are retained in `renderer-assembly/alias-control-provenance.json`
and `alias-control-reference/r_alias.c`.

The implementation retains the original eight bounding-box corners, twelve
near-plane edges, x87 arithmetic/store order, reciprocal-depth scaling, entity
transform cache, animated selection, triangle order and clipping dispatch.
`R_AliasDrawModel` retains its original `regparm(1)` convention: lighting arrives
in EAX. The other eight entries use cdecl. Callee-owned registers, stack, DF and
x87 control word are checked through the outer ABI probe; the tail adapter does
not hide damage. Aligned model scratch remains sized for `MAXALIASVERTS=2000`.
Lifted private vectors and matrices remain shared data, not C render algorithms.

The first fixture exposed two concrete differences. Identifier replacement had
changed diagnostic string literals in the independent C oracle; token-aware
replacement now preserves those bytes. The original `pskindesc` assignment was
absent from the initial compiler-listing scaffold because it had been optimized
away as an unobserved private store. Both maintained assembly variants now
explicitly publish the selected descriptor, matching the original C assignment.
The rejected run and diagnostic screenshot remain in the worktree.

Corrected normal and profiling fixtures each pass 11,648 exact cases, twelve
x87 settings, 8,192 continuous calls and 128 deliberate guard checks, with zero
failures. They exercise 3 through 2,000 vertices, clipped and trivial-accept
paths, invalid/animated skins and frames, lighting, aligned stack scratch,
read-only model data, complete defined live vertex/auxiliary state and typed
triangle/diagnostic calls. Undefined padding and scratch fields never read by
the original algorithm are not used as comparison inputs. Executed binaries
and bindings are retained in `dos-bench-20261008-062139` and
`dos-bench-20261008-064401` under the alias-control worktree.

## ISA and exact scenes pass before reviewed integration

All nine release symbols are owned by `r_aliascontrolasm.s`. Release, benchmark
and profiling module audits decode 1,104, 1,118 and 1,157 i386 instructions,
respectively, with zero unknowns, exemptions or post-486 instructions. Complete
executable gates verify 169,122 release, 238,725 benchmark and 244,685 profiling
instructions. Required runtime objects, the 529-instruction embedded startup,
and the 9,207-instruction provider plus its one runtime branch variant also
pass. All 36 preceding assembly objects retain identical allocated section
bytes and normalized relocations.

`AliasControlImplementation` defaults to C. Its assembly selection requires the
six already accepted alias preparation, bounding-box, matrix, lighting, frame
and skin primitives. The focused reference selects C for these nine pipeline
entries while retaining the same accepted lower routines. All three scenes run
twice per profile: 6,058 post-startup checksum comparisons and six indexed/palette
PCX captures match exactly. Source-tree SHA256 is
`6D871E349A0B93D41442BF34A6DAA87B53E7161C1E86E22C657BB423FAB653B4`.
Executed reference and candidate benchmark SHA256 values are
`B8CCB119A416AB2428BF51E14736A2EE0EA10587CA09D99F00D09BC3122921EA` and
`C13C985A446871E014C37CC3BEA047CEB201999A4379CC1CC48C21F5185E2808`.
All six scene artifacts and their executable, runtime/startup/provider bindings
are retained under `render-parity-alias-control-verified-selection-20261008`.

| Scene | C pipeline FPS | Assembly pipeline FPS |
|---|---:|---:|
| demo1-vesa-full | 12.5583160 | 12.5528095 |
| demo2-entity-workload | 12.7081835 | 12.7029180 |
| demo3-world-workload | 11.9318790 | 11.9268755 |

The small timing difference is not a material regression and does not determine
acceptance. Reviewed integration retains the original default C selection and
records exact file preimages in `out/alias-control-integration-preimages-20261008`.
The release inventory still identifies thirteen reachable C renderer entries,
plus initialization/debug/indirect paths requiring closure. Renderer-wide
complete-byte and uninterrupted-scene acceptance remain separate later gates.
