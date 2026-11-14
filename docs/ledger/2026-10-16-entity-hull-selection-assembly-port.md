# 3D entity BSP hull selection in i486 assembly (2026-10-16)

## Function and selection boundary

`HullForEntityImplementation=c|asm` selects the code used by
`SV_HullForEntity` and its six-plane box builder, `SV_HullForBox`. The default
i486 profile selects assembly; the C-reference profile selects the original C
functions. BENCH builds retain both implementations for direct parity checks.
The implementation lives in `src/collision/sv_hullforentity_asm.inc`, included from
`src/renderer/asm486_experiments.s`. `src/collision/asm_hullforentity.h` pins the 32-bit ABI and
the entity, model, hull, plane, and temporary box-hull layouts used by it.

The brush path validates `SOLID_BSP`, `MOVETYPE_PUSH`, and `mod_brush`, then
selects hull 0 when the moving box width is below 3, hull 1 through width 32,
and hull 2 above 32. It computes the same hull-origin offset as the C path.
The bbox path constructs all six plane distances and returns the entity origin
as the offset. The assembly restores the x87 control word after model-index
conversion and leaves the x87 stack empty on return.

## Exact parity fixture

Six direct helper cases passed: brush widths 2, 3, 32, and 33; a direct
`SV_HullForBox` build; and an entity-created bbox hull. The fixture compares
the selected hull, all six box-plane structures, offsets, and surrounding
sentinels. It observed 19 entity-helper and 3 box-helper assembly entries,
with zero failures.

The end-to-end entity/world trace fixture passed all 14 C/assembly comparisons,
observed 40 assembly recursive-hull entries, preserved 16 edge sentinels, and
reported zero failures. Its result is
`out/dos-bench-20261016-090608/bench-result.json`.

## Strict BENCH i486 gate

The complete BENCH gate passed. Project-object auditing covered 241,948
instructions; linked-object and executable audits covered 280,245 instructions
across 386 objects and 408 executable text ranges. The source map verified 408
source-bound contributions, 2,168 CODE ranges, and 25 DATA ranges. Startup
verification covered 1,660 loaded bytes and 529 CODE rows; the provider audit
covered 9,207 instructions. There were zero above-i486, unknown, exempt, or
misclassified instructions and zero relocated data sites.

These focused runs prove behavior and instruction compatibility. They are not
FPS measurements or hull-routine timings. Broader gameplay and visual-scene
acceptance remain open.

## Strict Release i486 gate

The non-BENCH release gate also passed. Project-object auditing covered
129,485 instructions; linked-object and executable audits covered 167,782
instructions across 386 objects and 394 executable text ranges. The source map
verified 394 source-bound contributions, 1,449 CODE ranges, and 25 DATA ranges.
Startup verification again covered 1,660 loaded bytes and 529 CODE rows; the
provider audit covered 9,207 instructions. All stages reported zero
above-i486, unknown, exempt, or misclassified instructions and zero relocated
data sites.

The selected release object references the public hull helpers, and the
assembly object defines `_SV_HullForBox` and `_SV_HullForEntity`. It contains
neither `_SV_HullForBox_C` nor `_SV_HullForEntity_C`; those C bodies remain in
BENCH builds as the parity oracle. The release pin covers 151 objects plus
`quake.exe`.

## Reproduction

```powershell
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -HullCheckOnly -NoBootstrap
```
