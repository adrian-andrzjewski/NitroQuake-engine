# Edge-list maintenance assembly port

Status: ongoing renderer port. This entry records selectable C, legacy
assembly, and replacement i486 assembly paths for active-edge insertion,
removal, and U stepping. It does not close the renderer conversion.

## Edge-list maintenance now has explicit implementation choices

`EdgeListMaintenanceImplementation=legacy|c|asm` selects the implementation.
`legacy` remains the build default and preserves the original `id386` routines
in `src/r_edgea.s`. `c` compiles the reference routines from `src/r_edge.c`
even in the DOS `id386` build. `asm` selects the new hand-written
`R_InsertNewEdges_asm486`, `R_RemoveEdges_asm486`, and
`R_StepActiveU_asm486` routines in `src/asm486_experiments.s`.

Both explicit C and replacement-assembly builds passed the pinned 969-frame
timedemo with framebuffer checksum `1047377823`. The original single samples
were not comparative performance evidence. A 2026-10-22 three-run schedule A/B
promoted target-U load caching inside the replacement assembly path at
**+0.009274 FPS (+0.0596208%)**, with exact checksum parity. A separate
three-run selector comparison measured the replacement assembly at
**0.2192759% slower** than `legacy`; the legacy default therefore remains.
The strict candidate passed the linked i486 audit with zero violations,
unknowns, or exemptions. See the
[`target-U cache promotion ledger`](2026-10-22-edge-list-target-u-cache-promoted.md)
for run values and artifacts.

The checksum establishes deterministic framebuffer parity for the pinned
workload; it does not resolve the supplied page fault or the separately
reported smear. The screenshot's mounted executable remains unidentified, and
matched-frame visual acceptance is open.

## Remaining active-edge maintenance closure

Brush-entity polygon clipping, `R_RenderPoly`, remaining render-time helpers,
and matched-frame visual acceptance remain open. Keep the legacy default while
the replacement assembly selector measures slower. Any future positive pooled
mean from three matched, uninstrumented runs qualifies regardless of its size;
matched-frame visual acceptance remains a separate open gate.
