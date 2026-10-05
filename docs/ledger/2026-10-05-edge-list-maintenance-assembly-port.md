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
timedemo with framebuffer checksum `1047377823`. The C sample took
`59.216375 s`; the assembly sample took `59.334247 s`. These single samples
show no speed gain, so the legacy default remains unchanged. The release
assembly build passed the i486 ISA gate at 168 enforced above-i486 instructions
versus the 170 baseline. The PROFILE486 build passed at 176 versus the 177
instrumented baseline. The assembly selector also passed the DOS smoke launch.

The checksum establishes deterministic framebuffer parity for the pinned
workload; it does not resolve the supplied page fault or the separately
reported smear. The screenshot's mounted executable remains unidentified, and
matched-frame visual acceptance is open.

## Remaining active-edge maintenance closure

Brush-entity polygon clipping, `R_RenderPoly`, remaining render-time helpers,
and matched-frame visual acceptance remain open. Keep the legacy default until
repeated alternating timings show a meaningful gain and visual acceptance is
complete.
