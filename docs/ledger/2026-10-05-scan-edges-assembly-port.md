# Edge-scan assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of the `R_ScanEdges` scanline loop. It does not close the renderer
conversion or the drawing helpers that `R_ScanEdges` calls.

## `R_ScanEdges` now has a selectable i486 assembly entry

`ScanEdgesImplementation=c|asm` selects the scanline setup and loop. The C
implementation remains the default and is retained as a benchmark reference.
The assembly entry aligns its stack span buffer, initializes the background
edge sentinels, scans each row, dispatches new, removed, and stepped edges,
flushes spans when needed, and invokes the selected span generator and drawing
path. Edge insertion/removal/stepping and span drawing remain independent C or
assembly-selected callees. Compile-time checks pin the `espan_t`, `edge_t`, and
`surf_t` sizes and the `refdef_t` offsets used by the assembly.

The selector contract and DOS smoke passed. The release assembly build passed
the i486 ISA gate at 168 enforced above-i486 instructions versus the 170
baseline. The PROFILE486 qbench build also passed at 176 versus the 177
instrumented baseline. The C timedemo completed 969 frames with checksum `1047377823` in
`59.170256 s`; the assembly timedemo completed the same 969 frames and checksum
in `59.171266 s`. These single samples show no speed gain, so C remains the
default. The final framebuffer checksum is exact; a matched-frame visual
comparison was not captured.

The page-fault screenshot remains unresolved. One staged executable has a
memory read at the supplied EIP, but its saved registers and traceback do not
fit that instruction's surrounding call path, and the screenshot's mounted
executable was not identified. The scan-edge selector has not been established
as the cause or fix for the fault or the reported frame smear.

## Remaining edge-scan closure

Brush-entity polygon clipping, `R_RenderPoly`, remaining render-time helpers,
and matched-frame visual acceptance remain open. Keep C selectable and default
until exact-frame output and a meaningful speed improvement are established.
