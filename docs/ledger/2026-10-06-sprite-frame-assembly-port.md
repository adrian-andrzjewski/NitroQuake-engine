# Sprite frame selection assembly port (2026-10-06)

## `R_GetSpriteframe` animated frame selection

The original routine remains available as `R_GetSpriteframe_C`. The public
`R_GetSpriteframe` wrapper selects `R_GetSpriteframe_asm486` with
`SpriteFrameImplementation=asm`; invalid entity frame numbers still print the
same diagnostic and fall back to frame zero before dispatch. Compile-time
layout assertions pin `msprite_t.frames` at offset 24,
`mspritegroup_t.intervals` at 4, `mspritegroup_t.frames` at 8, and
`mspriteframedesc_t` at 8 bytes.

The assembly takes cdecl arguments `(psprite, frame, cl.time, syncbase)` and
preserves EBX, ESI, and EDI. Single frames return directly. Animated groups
compute `time = cl.time + syncbase`, truncate `time / fullinterval` toward zero
with `FISTP` under a temporarily adjusted x87 control word, restore the caller's
control word, then compute `time - quotient * fullinterval` and scan the
interval table using the original strict `interval > targettime` boundary.
The generated C object was inspected to preserve its x87 operation order. An
initially reversed remainder subtraction selected frame zero for every
nonzero target; the corrected `fsubrp` source mnemonic encodes the required
`fsubp st(1),st` instruction in this AT&T assembly source.

The direct DOSBox-X i486 fixture compares the returned C and assembly pointers
in twelve cases; every case passed exactly: single-frame, group-start,
boundary-first, boundary-middle, last-interval, wrap-exact-period,
positive-multiple, negative-truncate-zero, negative-truncate-period,
syncbase-boundary, negative-frame-fallback, and high-frame-fallback. The
fixture is run by `tools/bench-dos.ps1 -SpriteFrameOnly` and the default
`bench486` aggregate.

### Paired render and linked-ISA validation

The C-reference profile and a focused profile with only
`SpriteFrameImplementation=asm` ran Demo 2's entity workload under the i486
DOSBox-X configuration. The paired report passed on the same source tree
(`2764440EFDA4D1FD0E5B6089C98EB895AAD9F9D0BB406454CF257BA7922E3F75`). All
980 post-warmup frame checksums matched. The captured 320x200 framebuffer had
zero differences across 64,000 palette indices and 768 palette bytes. The
report is `out/render-parity-spriteframe-focused-20261006/render-parity-result.json`.

The assembly-selected candidate's linked i486 audit passed: 338 linked input
objects, 235 runtime inputs, 231642 linked opcode sites verified, zero opcode
mismatches, and no enforced above-i486 instruction. The audit report is under
`out/dos-turbc-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasc-aliasbboxc-aliastransformc-aliasmatrixc-textureanimc-lightmapc-spriteframeasm-edgelistc/isa-audit-linked.json`.
The focused renderer test, build-selector test, ISA-audit test, render-report
test, documentation structure check, and whitespace check passed.

The single paired timedemo measured 12.805875 FPS for C and 12.805675 FPS for
the selected assembly profile. This one-run difference is not treated as a
performance regression or optimization target.

This evidence covers animated sprite-frame selection. The gradient, scan,
setup/projection, and draw stages now have separate port records.
`R_DrawSprite` orientation and top-level dispatch still use C, and the full
renderer migration remains in progress.

### i486 default and release audit (2026-10-07)

`SpriteFrameImplementation=asm` is now the i486 default in the build, benchmark,
timedemo, and smoke entry points. Explicit C remains selectable, and i386 keeps
the C default. Build-selector tests, all 51 rendering tests, ISA-audit tests,
and whitespace checks passed before the release rebuild.

The release build completed with the five promoted dynamic-light/sprite paths.
Its selected-object audit covered 104 objects and 148,910 instruction sites.
The complete linked-input audit covered 339 objects and 190,422 sites. The
linked executable audit verified 187,778 opcodes across 235 runtime inputs and
332 executable text ranges. All three gates reported zero enforced above-i486
instructions. Explicit data-table exemptions remain visible in the reports.
Reports and the executable are under `out/profile-1981d7617a5f4c91/`.
The release hash guard was recorded and then passed for 104 objects and the
executable; this pin does not substitute for framebuffer validation.

The later 2026-10-07 ISA-verifier correction re-audited the same objects and
executable successfully. It verified 187,773 linked opcode sites after adding
one hash-bound eight-byte runtime constant exclusion, with zero opcode
mismatches and zero enforced above-i486 instructions. See the object-gate
correction in `2026-10-03-isa-audit-and-i386-codepath.md` for the reproduced
classifier defects, real instruction fixtures, and data-exclusion evidence.

The five-path combined parity run uses
`tools/renderer-profiles/i486-asm-promoted-renderers-spriteframe.json` against
`tools/renderer-profiles/i486-c-reference.json`, with all six scenarios repeated
twice. The attempt under `out/render-parity-20261007-120536/` completed all six
reference scenarios but was stopped after the stricter candidate ISA gate
rejected a relocated benchmark name pointer in `.text`. No successful combined
comparison exists for that attempt. The two affected alias-frame/skin fixture
tables now explicitly reside in `.data`, which changes the source fingerprint
and requires fresh runs on both sides. Five-path combined parity remains
**PENDING**. The earlier focused frame-selection pair and four-path combined
pair do not prove this new five-path combination.

The fresh paired run is under `out/render-parity-isa-fixed-20261007/`. Both
sides rebuild from the source with fixture tables in `.data` and use the
corrected ISA classifier. Its final comparison report remains pending.
