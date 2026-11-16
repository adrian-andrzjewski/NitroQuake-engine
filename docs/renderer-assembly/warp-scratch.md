# Renderer stack bounds and warp scratch

`R_Init` allocates the 64,000-byte warp image once and keeps it for the
renderer lifetime. `R_RenderView_` no longer reserves the image in its normal
frame. Before entering any renderer path, `R_RenderViewDispatch` reads the
current ESP and checks it against DJGPP's `__djgpp_stack_limit` and
`__djgpp_stack_top`. If the loaded world's conservative stack requirement does
not fit, it skips the whole render and reports the requirement, available
bytes, and shortfall. If the normal path fits but the allocation-failure warp
fallback does not, it renders with waterwarp temporarily disabled.

The build checks generated release, C-reference, and instrumented assembly
frames before linking. The checked bounds are:

| Profile | Normal renderer | Warp fallback |
| --- | --- | --- |
| i486 release assembly | `172868 + 128 * world_depth` bytes | `236884 + 128 * world_depth` bytes |
| C reference | `172792 + 124 * world_depth` bytes | `236808 + 124 * world_depth` bytes |
| PROFILE486 assembly | `172992 + 136 * world_depth` bytes | `237008 + 136 * world_depth` bytes |

## Call-path ledger

| Model term | Caller and callee path | Charged stack | Build check |
| --- | --- | --- | --- |
| Preflight | `R_RenderView` → `R_RenderViewDispatch` → `R_RenderStackRequirement` → `R_WarpWorldTreeDepth` | Dispatcher and requirement frames stay below 512 bytes each; this work completes before the large render path. | Generated frame checks in `tools/renderer-stack-budget.py`. |
| Fixed renderer frames | `R_RenderView_` → `R_EdgeDrawing` → `R_RenderWorld` | Selected generated view, edge, and world frames. | Release/C-reference/profile selectors choose the matching generated entry. |
| Renderer call returns | `R_RenderView_` → `R_EdgeDrawing` → `R_RenderWorld`; dispatch → render callback | Two 4-byte returns for view-to-edge and edge-to-world, plus one 4-byte callback return. The callback word covers the no-warp recovery call without relying on the tail jumps used by the common allocated and fallback branches. | `R_RenderStackRequirement` charges three `R_WARP_CALL_BYTES`. |
| Polygon path | `R_RecursiveWorldNode` or `R_RenderWorld` → `R_RenderPoly` → `TransformVector` | Generated `R_RenderPoly` frame, 8 bytes of caller arguments and one return word, then the `TransformVector` frame, 8 argument bytes, and one return word. The current polygon path is 4,648 bytes. | The checker reads both generated leaf frames and compares the complete path with the pinned bound. `D_DrawPoly` is also checked as the alternate child path. |
| World BSP traversal | `R_RenderWorld` → `R_RecursiveWorldNode_C` recursion, or `R_RecursiveWorldNode_asm486` continuation records | C uses its generated recursive frame plus one return word per depth. The assembly walker adds its 64-byte generated frame and entry return to the fixed term, then its generated continuation-record size and deepest helper path per depth. | The generated world traversal path must fit within the selected clipped-bmodel tree step; the assembly walker record is read from generated `.equ` data. |
| Clipped-bmodel recursion | `R_DrawBEntitiesOnList` → `R_RecursiveClipBPoly` recursion | Generated clip frame, 12 bytes of cdecl arguments, and one return word per depth. This is 124 bytes for C reference, 128 for release assembly, and 136 with PROFILE486 instrumentation. | Exact selected frame plus argument/return costs are checked before linking. |
| Warp fallback | `R_RenderViewDispatch` → `R_RenderViewStackFallback` → render callback | Adds the 64,012-byte fallback frame and one callback return. The fixed normal term conservatively retains the dispatch callback return even though the fallback branch currently tail-jumps into the helper. | The generated fallback frame is pinned at 64,012 bytes; runtime checks use current ESP and DJGPP stack bounds. |

The fixed normal requirement is the sum of the selected `R_RenderView_`, edge,
world, and polygon-path costs, the renderer and dispatch return words, and the
assembly BSP walk's fixed frame when selected. The C-reference profile uses
12-byte view, 128,108-byte edge, 40,012-byte world, and 4,648-byte polygon-path
terms. Release uses 12, 128,176, 40,020, and 4,648 bytes. PROFILE486 assembly
uses 40-byte view, 128,224-byte edge, 40,068-byte world, and 4,648-byte
polygon-path terms. The fallback frame consists of its saved `ebx` and
64,008-byte local reservation.

`world_depth` is measured by a nonrecursive parent-link walk of the loaded BSP
and cached until the next map. The walk follows internal nodes only: BSP leaf
zero can be shared across branches, so its parent pointer cannot be used to
traverse back to a unique parent. It includes a terminal leaf frame below the
deepest internal node. The checker compares the generated world-walk cost with
the clipped-bmodel recursion cost; if either path exceeds the runtime tree
step, the build fails before linking.

The dispatcher reports normal-path headroom on its first successful check.
When the allocation-failure fallback is considered, it reports that separate
requirement and headroom too. BENCH486 retains the selected warp mode and
fallback measurements in `warp-stack.txt`. The checks read ESP directly and do
not use the disabled DOS stack-fill/high-water scan.

## DOSBox-X checks

The existing warp parity scenarios in
`benchmarks/tools/render-scenarios-warp-memory.json` cover allocated storage,
the guarded fallback, an insufficient fallback capacity, and waterwarp
disabled. The `benchwarp_short` scenario forces the test capacity to zero only
after confirming the real DJGPP bounds; it does not change those bounds.

After adding the normal-path preflight, all four scenarios were rerun with the
`i486-asm-selectable-current` renderer selector profile and `con_notifytime -1`
on DOSBox-X 2026.08.31/CWSDPMI. Allocated storage, guarded fallback,
forced-insufficient fallback, and waterwarp-disabled output each matched the
committed 320x200 reference exactly: 985 frames, checksum `1843917972`, and
zero changed pixels out of 64,000.

The 2026-11-14 DOSBox-X 2026.08.31/CWSDPMI parity run used a measured
`world_depth` of 72. The earlier runtime reports recorded 523,720 available
bytes for C reference and 523,772 for release assembly. Applying the current
generated-frame formulas, including the dispatch callback return word, gives:

| Profile | Normal requirement | Fallback requirement | Fallback headroom |
| --- | ---: | ---: | ---: |
| i486 release assembly | 182,084 | 246,100 | 277,672 |
| C reference | 181,720 | 245,736 | 277,984 |

These available-stack and headroom values describe that DOSBox/DPMI setup;
they are not real-hardware measurements. The source and runtime formulas are
checked against the generated frames by `tools/renderer-stack-budget.py`.

A reduced-stack executable was also exercised on that DOSBox-X/CWSDPMI setup.
The audited PROFILE486 executable was copied to an isolated staging directory
and its DJGPP stub minimum stack field was set to 192 KiB; the 985-frame demo2
run completed with world, edge, and surface profiling active. Setting the
staged copy to 160 KiB also completed all 985 frames, while the profile
reported zero world nodes, edge scans, and rendered surfaces. This confirms the
normal renderer was skipped at the lower setting and that the game continued
without entering its large render frames. The test changed only the staged
executable's stub minimum-stack field; it did not alter the checked-in binary.
