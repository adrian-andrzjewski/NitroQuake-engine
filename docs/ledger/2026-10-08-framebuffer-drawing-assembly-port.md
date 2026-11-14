# Framebuffer drawing assembly ownership

## Drawing algorithms and direct fixtures

`src/renderer/d_drawingasm.s` owns all eighteen original `draw.c` routines, including
picture/cache initialization, glyphs and strings, transparent/translated pictures,
console backgrounds, rectangle copies, tiles, fills, fades and disc rectangles.
Separate maintained normal and profiling includes preserve the reference's
loop, stride, clipping, palette, transparency and integer division behavior.
Normal builds assemble these sources directly. The private glyph helper uses
its original EAX/EDX/ECX arguments; public routines use the documented cdecl ABI.
Thirty-two compile-time storage facts bind all structures addressed by assembly.
The original source, function mapping and hashes are retained in
`docs/renderer-assembly/drawing-provenance.json` and `drawing-reference/draw.c`.

Both normal and profiling fixtures pass 11,648 exact cases across twelve x87
control words, including 8,192 uninterrupted calls and 128 deliberate guard
checks. Cases compare complete pixel buffers, caches, initialization and call
traces for both pixel formats, padded strides, top clipping, transparent index
255, console scaling, partial tiles, version text and cache reloads. The original
DOS buffer-lock macros expand to nothing; the C test oracle preserves that
behavior. No assembly change was needed for the initial trace-only fixture
failure. Accepted executions and hash-bound artifacts are retained under
`out/drawing-worktree-20261008/out/dos-bench-20261008-021219` and
`dos-bench-20261008-021445`.

All eighteen public entries are assembly-owned. All 34 preceding assembly
modules retain identical allocated bytes, properties and normalized relocations.
Strict module audits decode 1,885 release and 1,888 benchmark/profiling
instructions, all i386-compatible, with no unknowns, post-486 instructions or
exemptions. Release executable SHA256:
`7EC6BAECE1B9217EA04D79A6347FA9B27B2B84551CF90E354D98B2FA3C87096E`.

## Drawing scene acceptance and reviewed integration

The three-scene pair runs each implementation twice and matches all 6,058
post-warmup frame checksums and six complete indexed-pixel/palette captures
exactly. Evidence and execution-bound immutable artifacts are retained in
`out/drawing-worktree-20261008/out/render-parity-drawing-verified-selection-20261008-2`.
The source tree SHA256 is
`8446E995914922EA4AED652A5BF57A6DC8ABFA2E3968073C35EF56B6A5A4B019`.
C and assembly executable SHA256 values are
`06D4C2259C6A3CBC500D895EAA489D9A1F32FD9E1A68BE028A1E9EC4535180A4` and
`674D5F56BD71A78D11CE12DF46AA35288AE4097B0C940737B9B44C20DB9C9317`.

| Scene | C drawing FPS | Assembly drawing FPS |
|---|---:|---:|
| demo1-vga-full | 12.5558895 | 12.5558915 |
| demo2-entity-workload | 12.7081640 | 12.7081990 |
| demo3-world-workload | 11.9318720 | 11.9318910 |

No material performance regression was observed. Compatibility and exact
correctness determine acceptance. `DrawingImplementation` retains the C
reference option; `i486-asm-drawing.json` selects all accepted assembly ports.
The reviewed integration allowlist and preimages are recorded in
`out/drawing-integration-preimages-20261008/manifest.json`.
The expanded four-root ownership inventory now finds nineteen reachable C
renderer entries; initialization, indirect targets and complete gameplay/soak
coverage still require explicit closure.
