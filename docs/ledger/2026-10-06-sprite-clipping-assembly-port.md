# Sprite assembly ports (2026-10-06)

This record covers two bounded sprite-renderer routines. It does not close the
sprite pipeline or the overall renderer conversion.

## `R_RotateSprite` beam translation

The original body is retained as `R_RotateSprite_C`; the public
`R_RotateSprite` wrapper selects `R_RotateSprite_asm486` when
`SpriteBeamImplementation=asm`. The assembly applies the beam offset along
`r_spritedesc.vpn`, rounds each scaled component through a single-precision
temporary, then updates `r_entorigin` and `modelorg` in the C source order. It
uses cdecl, one caller argument, caller-clobbered EAX, and a balanced x87 stack.
The assembly's `vpn` offset is 36 in the DJGPP 32-bit layout.

The i486 DOSBox `bench486` fixture directly compares all six resulting vectors
for `zero`, `negative-zero`, `positive`, `negative`, `fractional`, and `small`
beam lengths. Every byte matched. The case checksums were 84878002, 84878002,
1166309850, 1381972085, 157236613, and 84878002, respectively.

## `R_ClipSpriteFace` plane clipping

The original routine remains as `R_ClipSpriteFace_C`; the public entry selects
`R_ClipSpriteFace_asm486` when `SpriteClipImplementation=asm`. The assembly
clips the active five-float winding against one `clipplane_t`, toggles
`clip_current`, writes the wrap vertex, preserves front vertices, and emits
crossings into the other buffer. It uses cdecl arguments, saves EBX/ESI/EDI,
keeps local distances on the stack, and balances the x87 stack on every return.
The globals are externally visible so the separate assembly unit and direct
fixture operate on the same buffers. A compile-time assertion pins the array
stride to 400 bytes and `clipplane_t.dist` to offset 12.

The generated DJGPP C reference was inspected before settling the x87 order.
For each distance, it subtracts the plane distance after the first two dot
products and before adding the third. During crossing interpolation, the C
compiler keeps `frac` in extended precision on the x87 stack across all five
components. The assembly follows both details; storing `frac` to a float local
caused a one-bit difference in the oblique-plane fixture and was removed.

The direct i486 DOSBox fixture byte-compares both complete clip buffers, the
active-buffer index, and the output count in six cases. All passed:

- `all-front-alt-buffer`: count 4, checksum 3288911086
- `all-back`: count 0, checksum 1608341650
- `fractional-crossings`: count 4, checksum 2052450930
- `exact-plane-touch`: count 3, checksum 802520956
- `oblique-five-vertex`: count 5, checksum 3066498616
- `near-plane-crossings`: count 4, checksum 450250582

### Paired render and linked-ISA validation

The C-reference and `i486-asm-selectable` profiles were run on the same source
tree, fingerprint
`E66AE171BF0034AD844642A7A5A0377111E487292B85DAD74AA37EB96002E3A2`. All six
scenarios passed twice per profile: both Demo 1 display modes, fullbright,
reduced viewsize, the Demo 2 entity workload, and the Demo 3 world workload.
The cross-profile report compared 11842 post-warmup frame checksums and 12
320x200 captures. All 64,000 palette indices and all 768 palette bytes matched
in every capture; there were zero pixel-index and palette-byte mismatches.

The paired report is
`out/render-parity-spriteclip-20261006/render-parity-result.json`; the input
reports are under its `reference` and `candidate` directories. The candidate's
linked audit is `out/profile-16d60c00ea764835/isa-audit-linked.json`: it passed
for i486, inspected 338 linked input objects and 235 runtime inputs, verified
245272 linked opcode sites, and reported zero opcode mismatches. The same report
retains the bounded data and non-instruction exemptions; they are not counted
as linked opcodes.

The focused source and selector checks passed, as did the direct
`-SpriteClipOnly` fixture and its object/linked ISA audit. The complete scene
set validates the selected profile's output; the direct fixtures are the tests
that explicitly invoke each sprite helper.

### Remaining sprite-renderer scope

Only beam translation and one-plane sprite-winding clipping have selectable
assembly paths in this record. `R_GetSpriteframe` and
`D_SpriteCalculateGradients` now have their own port records. `R_DrawSprite`,
`R_SetupAndDrawSprite`, sprite transform/projection, and downstream sprite
rasterization remain outside the port. Those and the other unported renderer
paths keep the overall assembly migration in progress.
