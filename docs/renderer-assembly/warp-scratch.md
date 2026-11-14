# Renderer warp scratch and stack fallback

`R_Init` allocates the 64,000-byte warp image once and keeps it for the
renderer lifetime. `R_RenderView_` no longer reserves the image in its frame:
the i486 release frame is 12 bytes and the profiled frame is 36 bytes. If the
allocation fails, `R_RenderViewDispatch` checks the current ESP against
DJGPP's `__djgpp_stack_limit` and `__djgpp_stack_top` before entering the
separate stack-backed helper. An invalid BSP depth or insufficient stack skips
waterwarp for that render and restores the original cvar afterward.

The release and C-reference i486 generated code gives a conservative
fallback requirement of `236804 + step_bytes * world_depth` bytes. The
selected step is 128 bytes in release assembly and 124 bytes in the C reference:

- 64,012 bytes for the fallback helper (`push ebx` plus its 64,008-byte local
  reservation).
- 12 bytes for the release `R_RenderView_` frame.
- 128,108 bytes for `R_EdgeDrawing` and 40,012 bytes for C-reference
  `R_RenderWorld`.
- 4,648 bytes for the deepest `R_RenderPoly` to `TransformVector` path.
- Three four-byte return addresses for fallback-to-render, render-to-edge,
  and edge-to-world calls.
- 128 bytes per BSP level in release assembly (112-byte
  `R_RecursiveClipBPoly_asm486` frame plus 12 bytes of cdecl arguments and its
  return address), or 124 bytes in the C reference (108-byte C frame plus the
  same call area). Both values bound the measured C world-node and recursive
  light-point steps. The instrumented assembly clip path uses a 136-byte step.

The final release and C-reference generated `r_main.s` files show the 64,008
byte local reservation only in `R_RenderViewStackFallback` (plus its saved
`ebx`, for 64,012 bytes total). The normal release `R_RenderView_` frame is 12
bytes; the profiled assembly frame is 36 bytes. `R_RenderViewDispatch` restores
its own frame before tail-jumping to the fallback helper. This confirms the
large array is isolated to the fallback frame.

`world_depth` is measured by a nonrecursive parent-link walk of the loaded
world BSP and cached until the next map. The walk follows internal nodes only:
BSP leaf zero can be shared across branches, so its parent pointer cannot be
used to traverse back to a unique parent. The measured depth includes one
terminal leaf frame below the deepest internal node. The bound uses the whole
world tree depth, so it safely covers recursive world rendering and clipped
bmodel traversal. It does not apply a separate fixed safety reserve. When the
fallback is used, the console reports the calculated requirement, current
available stack, and remaining headroom from the actual DJGPP limits. BENCH486
runs also write the selected mode and those measurements to `warp-stack.txt`
in the staged game directory. The check reads ESP directly so a local stack
marker cannot overstate available bytes; it does not use the DOS high-water
scan.

`benchmarks/tools/render-scenarios-warp-memory.json` exercises allocated
storage, the guarded fallback, a deterministic insufficient-stack result, and
waterwarp disabled. The `benchwarp_short` command only overrides the available
capacity after the runtime has confirmed the real DJGPP stack bounds; it does
not alter the bounds or enter the fallback.

On 2026-11-14, the fallback was exercised under DOSBox-X 2026.08.31 with the
i486 high profile and CWSdpmi (`FF3501B50BCF320E6615E025BDFF94261A087F83212858D4B12E42C19C7E3883`).
The C-reference profile reported 245,732 required bytes, 523,720 available, and
277,988 bytes of headroom. The assembly profile reported 246,020 required,
523,772 available, and 277,752 bytes of headroom. Their demo2 runs matched
exactly after six warmup frames: all 980 compared frame checksums matched, and
the captured 320x200 framebuffer and palette had zero differing bytes. Both
reported checksum `1843917972`. The two requirements both correspond to a
measured `world_depth` of 72. These stack figures describe this DOSBox/DPMI
environment; they are not a real-hardware stack measurement.

The allocated-buffer scenario logged `storage=available` in both profiles. Its
capture and checksum stream were byte-identical to the fallback scenario in
each profile. The forced-short scenario logged `stack=insufficient` with the
real stack capacities above, a test capacity of zero, and `forced=1`; it did
not enter the fallback. Its captures and checksum streams were byte-identical
to a separate `r_waterwarp 0` run in both profiles. C-reference and assembly
also matched exactly for both scenarios. The short-stack probe exercises the
skip branch after validating the real DJGPP bounds; it does not simulate a
smaller DOS stack.
