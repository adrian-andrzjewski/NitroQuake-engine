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
| i486 release assembly | `172864 + 128 * world_depth` bytes | `236880 + 128 * world_depth` bytes |
| C reference | `172788 + 124 * world_depth` bytes | `236804 + 124 * world_depth` bytes |
| PROFILE486 assembly | `172988 + 136 * world_depth` bytes | `237004 + 136 * world_depth` bytes |

The fixed normal requirement includes the generated `R_RenderView_`, edge,
world, and deepest polygon-path frames plus two cdecl return addresses. The
fallback adds its 64,012-byte frame and one call return address. Release frames
are 12 bytes for `R_RenderView_`, 128,176 bytes for `R_EdgeDrawing`, 40,020
bytes for the world renderer, and 4,648 bytes for the polygon path. The C
reference uses 12, 128,108, 40,012, and 4,648 bytes respectively. PROFILE486
assembly includes its measured callback paths: 40-byte view, 128,224-byte edge,
and 40,068-byte world frames. The 64,012-byte fallback consists of its saved
`ebx` and 64,008-byte local reservation.

The recursion step is 128 bytes for release assembly, 124 bytes for C
reference, and 136 bytes for instrumented assembly. It bounds clipped-bmodel
recursion and recursive world traversal. `world_depth` is measured by a
nonrecursive parent-link walk of the loaded BSP and cached until the next map.
The walk follows internal nodes only: BSP leaf zero can be shared across
branches, so its parent pointer cannot be used to traverse back to a unique
parent. It includes a terminal leaf frame below the deepest internal node.
The whole-world depth bounds both recursive world rendering and clipped
bmodel traversal without adding an environment-specific reserve.

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
generated-frame formulas gives:

| Profile | Normal requirement | Fallback requirement | Fallback headroom |
| --- | ---: | ---: | ---: |
| i486 release assembly | 182,080 | 246,096 | 277,676 |
| C reference | 181,716 | 245,732 | 277,988 |

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
