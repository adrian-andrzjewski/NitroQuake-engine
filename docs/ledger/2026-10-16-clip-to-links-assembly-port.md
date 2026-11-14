# 3D area-link entity clipper in i486 assembly (2026-10-16)

## Function and selector

`ClipToLinksImplementation=c|asm` selects `SV_ClipToLinks`, the area-node
traversal called from `SV_Move`. The current i486 profile selects assembly;
the C-reference profile selects the original C implementation. BENCH retains
the C body as a parity oracle. The assembly procedure is in
`src/collision/sv_cliptolinks_asm.inc`, included by `src/renderer/asm486_experiments.s`.

This is a shared 3D collision path, not a `r_`/`d_` renderer entry. It walks
linked solid entities, applies the movement, solidity, owner, and swept-bounds
filters, chooses regular or monster bounds, calls the selected
`SV_ClipMoveToEntity`, merges the closest trace, and recurses into overlapping
area-node children. `MOVE_NOMONSTERS` still permits BSP entities. Trigger
entities in the solid list retain the original `Sys_Error` behavior.

## ABI and recursive behavior

`src/collision/asm_cliplinks.h` pins the i386 structure sizes and offsets used by the
assembly: `areanode_t` is 32 bytes, `moveclip_t` is 124 bytes, and `trace_t` is
52 bytes. Compile-time assertions cover the node links, inline monster bounds,
edict fields, server edict table, and selector constants.

The procedure preserves `EBX`, `ESI`, `EDI`, and the caller's x87 control word.
It saves the entity-list successor before calling the per-entity clipper, so
the trace merge cannot invalidate list traversal. The monster min/max values
are inline vectors in `moveclip_t`; the assembly passes their addresses to the
clip helper.

## Exact C/ASM parity

The strict DOSBox-X `HullCheckOnly` run compared all 124 bytes of `moveclip_t`
for eight scenarios. They cover `MOVE_NOMONSTERS`, passedict and owner
filtering, point-size filtering, regular and monster bounds, area-node
recursion, and `startsolid` trace merging. The assembly path recorded 10
entries, all guard sentinels remained intact, and there were zero failures.
The same run passed the six-case direct entity-hull fixture and the 14-case
entity/world BSP trace fixture (6 hull-helper cases, 19 entity-helper entries,
3 box-helper entries, 14 clip-wrapper entries, 40 recursion entries, and 16
intact edge sentinels).

The retained strict benchmark result is
`out/dos-bench-20261016-110635/bench-result.json`. It is a correctness run; it
does not measure FPS or time this routine in isolation.

## Strict i486 gates

The strict BENCH gate passed. Project-object auditing covered 242,790
instructions. Linked-object and executable auditing covered 281,087
instructions across 386 objects and 408 source-bound contributions. The
source map verified 2,171 CODE ranges and 25 DATA ranges. Startup proof covered
1,660 loaded bytes and 529 CODE rows; provider proof covered 9,207
instructions. All stages reported zero above-i486 instructions, unknown
encodings, exemptions, or misclassified data.

The strict release gate also passed. Project-object auditing covered 129,467
instructions across 151 objects. Linked-object and executable auditing
covered 167,764 instructions across 386 objects and 394 source-bound
contributions. The source map verified 1,451 CODE ranges and 25 DATA ranges.
Startup and provider checks again covered 529 CODE rows and 9,207
instructions, with zero above-i486 instructions, unknown encodings,
exemptions, or misclassified data.

Both manifests select `clipToLinksImplementation=asm`. The release map defines
`SV_ClipToLinks`; only the BENCH image retains `SV_ClipToLinks_C` for parity.
The C-reference profile remains available. Broader gameplay and visual-scene
acceptance remain open.

## Reproduction and limits

```powershell
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -HullCheckOnly -NoBootstrap
rtk proxy pwsh -NoProfile -File tools/build-dos.ps1 -NoBootstrap
```

The strict runs used `out/profile-b0b63996f725e26c`. They prove exact
`SV_ClipToLinks` state parity and i486 instruction compatibility; they do not
establish a frame-rate gain or complete 3D rendering coverage.
