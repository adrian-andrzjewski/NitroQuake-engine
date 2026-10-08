# Sprite orientation and renderer math assembly

## Implementation and traceability

The C implementations remain independent, selectable reference implementations.
The assembly selectors default to C while complete-profile integration proceeds.
When selected, these public entry symbols are exported directly by the assembly
modules, with no compiler-generated forwarding entry.

| Original entry | Assembly module / replacement | Direct correctness evidence |
|---|---|---|
| `R_DrawSprite` | `r_spriteasm.s:R_DrawSprite_asm486` | 2648 exact descriptor, axes, dimensions, frame, beam, dispatch and ABI cases |
| `R_GetSpriteframe` public validation and dispatch | `r_spriteasm.s:R_GetSpriteframePublic_asm486` | Twelve single/group/boundary/invalid-frame cases against the C getter and existing assembly core, plus ABI checks |
| `VectorNormalize` | `r_mathasm.s:VectorNormalize_asm486` | Exact vector and returned length, guards and ABI across twelve x87 settings |
| `AngleVectors` | `r_mathasm.s:AngleVectors_asm486` | Exact nine output floats and ABI across twelve x87 settings |

The math pair has 252 direct cases in total. Inputs include zero and signed zero,
tiny and large finite coordinates, fractional and wrapped angles, and large
angles. The orientation fixtures cover all five types, near-pole rejection,
zero vectors, roll, nonzero beam lengths, changed entity state and 2048
consecutive calls. Ten rendering fixtures compare projected vertices, all color
and depth bytes, axes, and surrounding buffer guards, including transparent
texels and clipping/rejection paths.

The current shared beam, clip, setup and rasterization selectors still determine
those callees. A selected top-level assembly entry does not make a shared C
callee an assembly implementation. Remaining renderer closure work is recorded
separately in `docs/RENDERER-COMPLETION-GAPS.md`.

## ABI and arithmetic

The modules use DJGPP 32-bit cdecl and preserve EBX, ESI, EDI and EBP. EAX, ECX,
EDX and x87 registers are scratch. The x87 stack is empty at entry/exit, except
`VectorNormalize` returns its extended length in ST(0); the caller consumes it.
Neither math routine modifies the control word. Sprite structure offsets live
in `asm_sprite.h` and have compile-time layout assertions in `r_sprite.c`.

The pinned C object's actual arithmetic is the reference. Trigonometric values
remain extended until their original store boundaries. `AngleVectors` retains
the two observed float spills; normalization does not add a float spill for
length or reciprocal. Upright rejection uses the original strict comparisons
against double constants for positive/negative 0.999848. Comments identify the
GNU assembler's historically reversed x87 pop mnemonics; emitted bytes were
inspected before execution.

The generic benchmark ABI probe checks callee-saved registers, ESP, stack canary,
x87 control word, TOP/tag state and direction flag. Five deliberately faulty
callees prove the register, stack, control-word, x87-stack and direction-flag
checks detect real damage. An initial offset error in the new test probe was
fixed before these results were accepted.

## Mechanical and emulator evidence

The isolated benchmark build audited 106 selected objects and all 341 linked
inputs, including 235 runtime members. The final opcode gate verified 223878
linked opcodes, with no mismatch or enforced instruction above i486.

The first focused demo pair is INVALID as evidence for these new selectors.
`timedemo-dos.ps1` recorded orientation/math requests but omitted them from its
build arguments. Its 1960 matching post-warmup frame checksums and two matching
captures exercised only the five previously validated assembly paths. The raw
results are retained and marked invalid; they do not establish integration
parity for sprite orientation or renderer math. Direct assembly fixtures above
remain valid because their runner forwarded the selectors correctly.

The runner now forwards exposed selectors from the shared table and verifies
the actual build manifest before execution. The replacement main-tree pair
passed: Demo 2 ran twice per profile, all 1960 post-warmup frame checksums
matched, and both 64000-index / 768-byte-palette captures were exact. The
candidate's verified build manifest selects both new paths as assembly, along
with the five previously validated paths. Source-tree SHA256:
`EF23815650DD430BF0508A5821232B43B2A4CE7033FF2FBA6A488BA50B9F4DA7`.
The report is
`out/render-parity-sprite-math-verified-selection-20261007/render-parity-result.json`.
The candidate's linked ISA gate verified 223167 opcodes and all 235 runtime
members under the stronger special-register classifier, with no enforced
instruction above i486 or linked opcode mismatch.

The benchmark reports are in the isolated sprite worktree:
`out/dos-bench-20261007-140845`, `-140853`, and `-140859`. The paired report is
`out/render-parity-spriteorientation-math-20261007/render-parity-result.json`.
Main-tree integration retained an explicit file allowlist and preimages in
`out/sprite-integration-preimages-20261007`. A public frame-getter prototype was
added during integration to remove an implicit-int warning. The main tree's
subsequent build/audits and the correctly selected paired comparison establish
the focused integration gate. Full-profile tests remain required.

Reproduce the direct cases with `tools/bench-dos.ps1 -NoBootstrap` and selectors
`-SpriteOrientationImplementation asm -RenderMathImplementation asm`, choosing
`-SpriteOrientationOnly`, `-SpriteFrameOnly`, or `-SpriteSetupOnly` in separate
runs. Use `tools/render-parity-dos.ps1` with candidate profile
`i486-asm-promoted-renderers-spriteorientation-math.json` and scenario
`demo2-entity-workload` to reproduce the focused paired gate.

Full-profile six-scene integration, uninterrupted rendering soak, remaining C
ownership and human visual/gameplay acceptance remain pending. No performance
improvement is asserted or required for this conversion.
