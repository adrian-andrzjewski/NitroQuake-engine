# 3D entity trace wrapper in i486 assembly (2026-10-16)

## Function and selection boundary

`ClipMoveToEntityImplementation=c|asm` selects the implementation of
`SV_ClipMoveToEntity`. The current i486 profile selects assembly; the complete
C-reference profile selects the original C function. BENCH builds keep both
implementations so the public assembly path can be compared directly with the
C oracle. The assembly entry is in `src/sv_clipmovetoentity_asm.inc`, included
from `src/asm486_experiments.s`.

This wrapper performs the 3D entity/world trace setup: it initializes the
returned trace, obtains the entity hull through the selected
`SV_HullForEntity`, translates the endpoints, calls the selected recursive
hull checker, restores the world-space endpoint, and assigns the entity when
the trace hits. The `QUAKE2` rotation path remains on its C implementation.
The earlier hull-selection and recursive-check ports are recorded in the
[hull-selection ledger](2026-10-16-entity-hull-selection-assembly-port.md) and
[recursive hull-check ledger](2026-10-16-chase-hull-check-assembly-port.md).

## Wrapper and ABI

The i386 ABI returns `trace_t` through a hidden result pointer. The assembly
entry preserves that contract and the 52-byte structure layout pinned by
`src/asm_clipmovetoentity.h`. It builds the result in a local trace before
copying it to the caller buffer, preserving behavior when the output aliases
an input. Float arguments for the recursive checker retain their exact `0.0`
and `1.0` bit patterns.

## Exact trace parity

The DOSBox-X `HullCheckOnly` fixture passed all 14 entity/world trace
comparisons. It observed 14 assembly wrapper entries, 40 recursive assembly
entries, and 16 intact edge sentinels, with zero failures. The same run passed
the six direct hull-helper comparisons: 19 entity-helper entries and 3
box-helper entries, with zero failures.

The retained fixture output is
`out/dos-bench-20261016-094738/bench-result.json`. It is a correctness run and
does not measure FPS or trace-routine timing.

## Strict i486 gates

The strict BENCH gate passed. Project-object auditing covered 242,040
instructions. Linked-object and final-executable auditing covered 280,337
instructions across 386 objects and 408 source-bound contributions. The
source-to-executable map verified 2,170 CODE ranges and 25 DATA ranges.
Startup proof covered 1,660 loaded bytes and 529 CODE rows; the provider audit
covered 9,207 instructions. All stages reported zero above-i486 instructions,
unknown encodings, exemptions, or misclassified data.

The non-BENCH release gate also passed. Project-object auditing covered
129,484 instructions across 151 objects. Linked-object and final-executable
auditing covered 167,781 instructions across 386 objects and 394 source-bound
contributions. The source map verified 1,450 CODE ranges and 25 DATA ranges.
Startup and provider checks again covered 529 CODE rows and 9,207 instructions,
with zero above-i486 instructions, unknown encodings, exemptions, or
misclassified data.

In the selected release, `world.obj` references `_SV_ClipMoveToEntity` and
`asm486_experiments.obj` defines it. The release contains no
`_SV_ClipMoveToEntity_C` oracle body; BENCH retains the C implementation for
parity. Broader gameplay and visual-scene acceptance remain open.

## Reproduction and limits

```powershell
rtk proxy pwsh -NoProfile -File tools/bench-dos.ps1 -HullCheckOnly -NoBootstrap
rtk proxy pwsh -NoProfile -File tools/build-dos.ps1 -NoBootstrap
```

The strict runs used the default i486 assembly profile
`out/profile-47c681114048cac6`. These focused checks prove trace parity and
i486 instruction compatibility; they do not establish a frame-rate gain or
complete 3D rendering coverage.
