# 3D entity BSP leaf traversal in i486 assembly (2026-10-16)

## Function and selector

`FindTouchedLeafsImplementation=c|asm` selects `SV_FindTouchedLeafs`, called
from `SV_LinkEdict` to record the BSP leaves touched by a modeled entity for
visibility/PVS processing. The current i486 profile selects assembly; the
C-reference profile selects the original C body. BENCH retains the C body as a
parity oracle. The implementation is in
`src/sv_findtouchedleafs_asm.inc`, included by `src/asm486_experiments.s`.

## ABI and recursive behavior

`src/asm_findtouchedleafs.h` pins the 32-bit ABI and offsets used by the
assembly, including 40-byte nodes, 48-byte leaves, 20-byte planes, the entity
leaf fields and bounds, `sv.worldmodel`, and the model leaf array. Compile-time
assertions also pin the 16-leaf limit and solid contents value.

The procedure preserves `EBX`, `ESI`, and `EDI`, recurses into both selected
children in C order, and stops at solid nodes or when the entity reaches
`MAX_ENT_LEAFS`. Axial splitting follows the inclusive bounds in
`BOX_ON_PLANE_SIDE`; non-axial splitting calls the shared `BoxOnPlaneSide`
helper. Leaf-number conversion uses a reciprocal multiply instead of integer
division and retains Quake's subtraction of the solid world leaf.

## Exact C/ASM parity

The strict DOSBox-X `HullCheckOnly` run compared the full edict and surrounding
guard words over ten cases. They cover solid nodes, each single-child path,
both-child recursion, the leaf-count limit and saturation boundary, direct
leaf input, and axial and non-axial plane-boundary equality. The selected
assembly entry ran 31 times; all edict bytes and guards matched, with zero
failures. The same run passed the six-case entity-hull helper, eight-case
area-link clipper, and fourteen-case entity/world trace fixtures.

## Strict i486 gates

The strict BENCH gate passed. Project-object auditing covered 243,476
instructions. Linked-object and executable auditing covered 281,773
instructions across 386 objects. The source map verified 408 contributions,
2,173 CODE ranges, and 25 DATA ranges. Startup proof covered 1,660 loaded
bytes and 529 CODE rows; provider proof covered 9,207 instructions. Every
stage reported zero above-i486 instructions, unknown encodings, exemptions,
or misclassified data.

The strict Release gate also passed. Project-object auditing covered 129,441
instructions. Linked-object and executable auditing covered 167,738
instructions across 386 objects. The source map verified 394 contributions,
1,451 CODE ranges, and 25 DATA ranges. Startup and provider checks again
covered 529 CODE rows and 9,207 instructions, with zero above-i486
instructions, unknown encodings, exemptions, or misclassified data. The
release selector uses assembly and omits the C oracle body.

## Reproduction and limits

```powershell
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -HullCheckOnly -NoBootstrap
rtk proxy pwsh -NoProfile -File tools/build-dos.ps1 -NoBootstrap
```

Both strict runs used `out/profile-907251d478dae3d7`; the focused BENCH result
is `out/dos-bench-20261016-133314/bench-result.json`. These checks establish
exact function-state parity and i486 compatibility, not full-scene parity or
an FPS gain.

The full C-reference Demo 2 run passed all 985 frames with checksum
`1887495667`. The current all-assembly profile exits before writing its first
frame checksum. Returning only `FindTouchedLeafsImplementation` to C did not
prevent that failure, so this run does not implicate the touched-leaf port.

Several isolated 3D assembly selections complete the same 985-frame scene
with checksum `1887495667`: `R_RenderWorld` plus the BSP walker,
`R_RenderBmodelFace` alone, `R_DrawSolidClippedSubmodelPolygons` alone,
`R_RecursiveClipBPoly` alone, and `R_RenderBmodelFace` plus the Z-gradient
helper. The clipper-only run completed twice at 12.18 median FPS; both
320x200 indexed captures and palettes matched the golden image exactly.
Returning either
`R_DrawSolidClippedSubmodelPolygons` or `R_RenderBmodelFace` to C in the broad
profile did not prevent its early exit; returning the full brush-model
clipping trio to C did not prevent it either. This rules out none of the
remaining interactions and does not identify the failing selector.

The saved `half1` and `half2` selector profiles each pass the complete scene.
A renderer/geometry-focused profile selecting 92 assembly procedures also
passes one full run at 12.18 FPS; the complementary 24-selector profile passes
with `SurfaceDispatcherImplementation=c` at 12.19 FPS. Both report checksum
`1887495667` and exact indexed captures and palettes. Combining those groups
with `SurfaceDispatcherImplementation=c` still exits before producing
`timedemo.txt`. The 12-selector control and screen subsets each remained alive
through a 30-second emulator window, then timed out before scene completion;
those probes are not parity results. With the screen set enabled, adding
`DrawingDriver`, `ViewControl`, and `DamageParse` likewise survived until the
30-second timeout, while adding `PrintTimes`, `WorldControl`, and `Drawing`
exited before `timedemo.txt` was written. That last subset is now the smallest
reproducing group tested, but it does not establish which procedure is
responsible. Each single selector and pair from that group also survived only
until the 30-second timeout, so those are not parity results.

The decisive broad-profile check passes when only
`WorldControlImplementation` is changed to C: the other 116 selectors remain
assembly, all 985 Demo 2 frames complete, the framebuffer and palette match
exactly, the final checksum is `1887495667`, and the measured median is 12.17
FPS. Changing only `PrintTimesImplementation` to C still exits before
`timedemo.txt`, so `PrintTimes` is not the sole cause. `WorldControlImplementation`
selects nine procedures across model rotation, entity-fragment BSP traversal,
and edge-frame setup: `R_EntityRotate`, `R_RotateBmodel`,
`R_RotateBmodelCached`, `R_RemoveEfrags`, `R_SplitEntityOnNode`,
`R_SplitEntityOnNode2`, `R_AddEfrags`, `R_DrawCulledPolys`, and
`R_BeginEdgeFrame`. Their direct C/ASM fixture passes twelve x87 control words
and an 8,192-call rotation-cache sequence, but that fixture does not reproduce
the failing full-scene integration. The current fault is narrowed to the
WorldControl assembly group or a call-path interaction that requires it; its
individual procedure is not yet isolated.

QBench-only mixed-dispatch probes redirected each complete WorldControl
subgroup (rotation, efrag traversal, or edge setup), and each of the three
subgroup pairs, to its `_WorldControl_C` copies while leaving
`ASM486_WORLD_CONTROL` enabled. All six variants still exited before
`timedemo.txt` after 47–50 seconds. These shims retain assembly-selected
compile-time state and benchmark call hooks, so the result does not prove that
each subgroup independently fails in a production build or isolate an
individual entry. Only changing the production selector for the entire
WorldControl group to C currently passes.

The supplied DOSBox-X screenshot reports EIP `0x000e2fa8` and EBP
`0x00400000`. Its file timestamp (2026-10-16 12:41 Warsaw time) and guest
program path correlate with `out/dos-bench-20261016-104040`, staged around
12:40 Warsaw time. That run's `dosbox-x-bench.conf` mounts the staged directory
as `C:`; its `quake\qbench.exe` SHA-256 is
`7D7B0368A9C6A33CE90850DE2A59AAE46C0F2F72F9BD1B5F4D5A33954270BC28`.
`bench.bat` starts `qbench.exe ... +bench486 -benchhullcheck -benchexit`, and
the staged `BENCH486.TXT` ends after the entity-hull fixture passes and a
partial `clip-links case 2` result. This ties the screenshot to that older
BENCH fixture run. The staged bundle contains no link map or build manifest,
so the exact EIP cannot be mapped to a function from this evidence. Maps from
other candidates that place the same EIP in either
`R_RecursiveClipBPoly_asm486` or `D_DrawZSpans` are not evidence for this
binary.

The later six-case hull and eight-case area-link fixtures pass, as do the
fourteen-case entity/world trace fixture and the strict i486 gates. The
current all-assembly Demo 2 run completes all 985 frames with the exact
framebuffer and palette, checksum `1887495667`, and a measured 12.17 FPS.
This historical BENCH screenshot does not establish a current production
renderer crash.
