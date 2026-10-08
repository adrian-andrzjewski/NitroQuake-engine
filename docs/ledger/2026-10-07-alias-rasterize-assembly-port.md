# Alias-model triangle rasterization assembly port

## `D_RasterizeAliasPolySmooth` setup and span orchestration

`AliasRasterizeImplementation=c|asm` selects the retained C routine or
`D_RasterizeAliasPolySmooth_asm486` in `src/d_polysa.s`. Assembly is the i486
default; selecting C adds the `aliasrasterizec` profile token so it cannot
overwrite the retained release directory.

The assembly routine follows the original `D_RasterizeAliasPolySmooth` order:
load the edge-table vertices and heights, calculate shared triangle gradients,
initialize the top left span, optionally initialize the second left segment,
walk the right edge to fill span counts, then optionally draw its lower segment.
The existing 32-byte `spanpackage_t` layout and six-word vertex layout are used
directly. The C body remains available as `D_RasterizeAliasPolySmooth_C` for
benchmark/reference builds. No interpolation, rounding, clipping, lighting,
texture, or depth behavior was intentionally changed.

`D_RasterizeAliasPolySmooth_asm486` is cdecl and preserves EBX, ESI, EDI, and
EBP. Its 60-byte local area holds the four edge pointers, two edge heights,
the original right-edge span count, and temporary base/extra fixed-point
steps. It calls the existing gradient and line-scan selectors and the existing
left-edge and span-draw routines. Profile builds route those calls through the
same `PROFILE486` wrappers as the C path. The arithmetic in this orchestration
uses 386 integer instructions; x87 behavior stays in the existing gradient
implementation.

## Selected-object and linked 486 ISA audit

The focused alias rasterization candidate passed the normal i486 build gate.
The selected object audit examined 103 objects and 180,895 instruction sites;
the complete object closure examined 338 objects and 222,407 sites. The linked
audit verified 219,677 opcodes across 235 runtime inputs and 333 executable
`.text` ranges. No enforced instruction above i486 was found. The renderer
objects had no unclassified instructions; the linked closure's existing
third-party runtime and data exemptions remain listed in the build report.

The generated report is under
`out/dos-turbc-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasc-aliasbboxc-aliastransformc-aliasmatrixc-aliasgradientc-aliasedgetablec-aliasskintablec-textureanimc-lightmapc-edgelistc/`
(`isa-audit.json`, `isa-audit-linked-objects.json`, and
`isa-audit-linked.json`).

## Two-repeat Demo 2 parity and timing

The focused `i486-asm-alias-rasterize` profile changes only
`AliasRasterizeImplementation` from `i486-c-reference`. Both profiles passed
`demo2-entity-workload` using the same source-tree fingerprint
`EDB3D076C66B00CBF097E0872A0A28F1A5DCE39EBA7B8563F0CDD71F8A8C980A`.

Each profile completed two 985-frame runs. Both repeats matched all 980
post-warmup frame checksums exactly. Frame-169 captures were exact on both
repeats: all 64,000 indexed pixels and all 768 palette bytes matched. The report
is `out/render-parity-20261007-033544/render-parity-result.json`.

The diagnostic median was 12.784987 fps for C and 12.767031 fps for assembly,
about 0.14% lower for assembly in this run. This is within ordinary timedemo
variation and is not an optimization claim. The implementation remains because
it moves the triangle span setup into inspectable, 486-compatible assembly while
preserving exact output.
