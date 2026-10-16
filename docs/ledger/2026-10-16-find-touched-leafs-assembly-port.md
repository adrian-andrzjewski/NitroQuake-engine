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
`R_RenderBmodelFace` alone, `R_DrawSolidClippedSubmodelPolygons` alone, and
`R_RenderBmodelFace` plus the Z-gradient helper. Returning either
`R_DrawSolidClippedSubmodelPolygons` or `R_RenderBmodelFace` to C in the broad
profile did not prevent its early exit; returning the full brush-model
clipping trio to C did not prevent it either. This rules out none of the
remaining interactions and does not identify the failing selector.

The supplied DOSBox-X screenshot reports EIP `0x000e2fa8` and EBP
`0x00400000`, outside the displayed application stack. The screenshot's exact
executable hash is unknown. In the current candidate (`qbench.exe` SHA-256
`25e71df0975e44c6921f54751a897e4240d815c86499a489aedf9877cf2d4bcf`), the
map places `0x000e2fa8` inside `R_RecursiveClipBPoly_asm486`; disassembly shows
it is a valid instruction boundary (`je 0x000e3009`). The next symbol,
`R_DrawSolidClippedSubmodelPolygons_asm486`, begins at `0x000e3030`. This
address mapping cannot prove the screenshot used this executable, and the
reported EIP does not establish which earlier call damaged the frame state.
The all-assembly runtime fault and its cause remain open.
