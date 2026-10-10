# `R_RunParticleEffect` -> i486 assembly port (2026-10-10)

## C reference and assembly behavior

`R_RunParticleEffect` in `src/r_part.c` emits particles from the free list,
prepends each one to the active list, and returns as soon as the free list is
empty. `src/r_runparticleeffectasm.s:R_RunParticleEffect_asm486` preserves that
order and the original C routine remains available as the selectable oracle.

For counts other than 1024, the routine emits slow-gravity impact particles,
sets lifetime to `cl.time + 0.1 * (rand() % 5)`, masks the requested color,
perturbs each origin coordinate, and derives velocity from the supplied
direction. It consumes five random values per particle. Count 1024 selects the
rocket-explosion branch: it sets the explosion ramp and lifetime, alternates
the two explosion particle types, and consumes seven random values per
particle. The assembly keeps the source RNG order, signed `IDIV` remainder
behavior, x87 store points, list updates, and early-exhaustion behavior.

The entry uses cdecl arguments `(org, dir, color, count)` and preserves EBX,
ESI, and EDI. Its source declares `.arch i486` and `.arch .387`; the latter
requires an x87 FPU, so this slice is verified for 486DX-class execution and
does not claim support for a FPU-less 486SX. The binary ISA gate remains the
authority for the emitted instruction stream.

## Selector and direct fixture

`RunParticleEffectImplementation` keeps C as the default and selects the
assembly entry only when requested. The BENCH486 C oracle and the assembly
entry are tested by `src/bench486_runparticleeffect.h` across 12 cases,
including empty and exhausted pools, ordinary counts, count 1024, untouched
fields, full list state, scripted random values, seeded libc RNG continuation,
register/stack preservation, and canaries. The fixture passed in the i486
DOSBox-X run recorded at
`out/dos-bench-20261010-000310/bench-result.json`.

The paired scene injects a `TE_WIZSPIKE` at the existing deterministic clear
point and records the real call immediately after `R_RunParticleEffect`.
Quake defines `TE_WIZSPIKE` as protocol value 7 (`src/protocol.h`); value 5 is
`TE_LIGHTNING1`. A host regression test now compares the fixture generator's
supported event values to `protocol.h`, preventing another wire-ID mismatch.

## Paired frame parity

`tools/render-scenarios-runparticleeffect.json` uses the C profile as the
reference and the assembly profile as the candidate, with exact comparison
tolerance. Each run reports 10 timedemo frames and 11 checksum records. The
event occurs once at checksum index 10 with zero overflow, and the captured
frame uses that same index. The first four startup checksum rows are excluded
from repeat and cross-profile stream comparisons; the remaining seven rows
match exactly.

Both profiles ran twice under the configured DOSBox-X i486 target. All four
captured 320x200 framebuffers match exactly between C and assembly: zero of
64,000 palette indices differ, and all palette bytes match. The final
framebuffer checksum is `16764447`. The pair report is
`out/render-parity-20261010-002556/render-parity-result.json`; it records
`pass: true`, event frame 10 for every run, and exact stream and image parity.
The measured median was about 12.3 fps for each profile; this is regression
context, not an optimization claim.

## ISA evidence and remaining scope

The C-reference executable passed the strict i486 audit at
`out/profile-1981d7617a5f4c91/isa-qbench/relocated-20261010-021341653/strict-isa.json`:
204,554 decoded instructions, zero above-i486 instructions, zero unknown
instructions, and zero exemptions. The assembly executable passed at
`out/profile-89ec6ced75682de0/isa-qbench/relocated-20261010-015934180/strict-isa.json`:
205,500 decoded instructions with the same zero-violation result. Both
timedemo reports and the paired report record `isaAuditStatus: PASS`. The build
gate also checked the startup image and maintained DPMI provider; its proof
reported 529 startup CODE rows and 9,207 provider instructions with no
exemptions.

This accepts the `R_RunParticleEffect` implementation and the ordinary
`TE_WIZSPIKE` framebuffer path. The count-1024 branch is covered by direct
state/RNG parity, not by a separate event-driven framebuffer pair. The broader
renderer migration remains in progress; `R_EntityParticles` is a suitable next
particle leaf, with its C math behavior requiring especially careful parity
work.

## RPE test commands

From `quake/`, run the focused direct fixture and paired scene:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -RunParticleEffectImplementation asm -RunParticleEffectOnly -NoBootstrap
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -ReferenceProfile tools/renderer-profiles/i486-runparticleeffect-c.json -CandidateProfile tools/renderer-profiles/i486-runparticleeffect-asm.json -ScenarioFile tools/render-scenarios-runparticleeffect.json -Scenario demo2-wizspike-event -CpuTarget i486 -NoBootstrap
```

The host fixture and selector contracts are registered in
`tools/run-tests.ps1`; `tools/test-rendering.py` also checks the event scenario
and exact paired-report gates.
