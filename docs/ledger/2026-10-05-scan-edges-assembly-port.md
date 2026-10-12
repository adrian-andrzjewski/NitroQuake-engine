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

## Matched-frame verification (2026-10-12)

The C-reference and candidate profiles were cloned from
`i486-c-reference.json`; `ScanEdgesImplementation` was the only selector
changed (`c` to `asm`). The deterministic DOSBox-X pair is retained in
`out/render-parity-edge-scan-20261012/render-parity-result.json`. It passed
`demo1-vga-full`, `demo2-entity-workload`, and `demo3-world-workload`, with two
runs per scene. All 6,058 post-warmup frame checksums matched, and all six
320x200 indexed framebuffer and palette captures were exact: zero pixel-index
or palette-byte differences. The source-tree fingerprint matched before and
after the pair.

The recorded median rates were 12.1509 FPS C / 12.1456 FPS assembly for Demo 1,
12.2418 / 12.2362 for Demo 2, and 11.7007 / 11.6956 for Demo 3. This is a
0.04-0.05% slowdown in these samples, not a meaningful regression or a speed
claim. The C entry remains available as the oracle and default.

The paired build used `-VisualParityOnly`, so its own ISA field is `SKIPPED`.
A separate strict i486 build used `-ScanEdgesImplementation asm`; its manifest
confirms that selector and its complete executable gate passed: 172,480
project-object instructions, 210,777 linked and relocated instructions, 529
startup CODE rows, and 9,207 provider instructions, with zero post-i486,
unknown, or exempt instructions. Evidence is under
`out/profile-2c95169922010483/isa-qbench/`.

The broad BENCH486 qbench run for that build reached its 180-second timeout
while running the generic surface-cache microbenchmark; it produced no final
`bench-result.json`. This is not a scan-edge parity failure. The scene pair's
timedemo measurements above are the completed performance regression evidence
for this slice.

## Remaining edge-scan closure

Brush-entity polygon clipping, `R_RenderPoly`, and remaining render-time helpers
remain open. Matched-frame output for `R_ScanEdges` is now verified; that does
not close these other edge and renderer dependencies. Keep C selectable and
default while the broader i486 assembly profile and its render-time closure are
validated.
