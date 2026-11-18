# `D_DrawParticle` -> verification of the existing i486 rasterizer (2026-10-10)

## Traceability and scope

The Quake C reference is `src/renderer/d_part.c:D_DrawParticle`; the existing 32-bit
runtime rasterizer is `src/renderer/d_parta.s:D_DrawParticle`. The assembly path
predates this tranche. This work exposed the retained C body as a selectable
oracle and made the C and assembly implementations directly comparable; it did
not newly translate the rasterizer into assembly. `ParticleDrawImplementation`
selects the C oracle or the existing assembly path in the focused profiles
`i486-particledraw-c` and `i486-particledraw-asm`.

The code tranche is inner-repository commit `1c1e411932b2`, referenced by outer
workspace commit `0bd562c`.

Traceability is:

| Reference or implementation | Role | Verification |
| --- | --- | --- |
| `src/renderer/d_part.c:D_DrawParticle_C` | Original C rasterizer retained as the oracle | `src/tests/bench486/bench486_particledraw.h` direct comparisons |
| `src/renderer/d_parta.s:D_DrawParticle` | Existing hand-written 32-bit assembly runtime path | Strict i486 executable audit and paired scene |
| `tools/renderer-profiles/i486-particledraw-c.json` / `i486-particledraw-asm.json` | Select the C oracle and assembly path over the same renderer profile | `tools/render-parity-dos.ps1` |

## x87 conversion and clipping parity

The C float-to-integer conversions truncate toward zero regardless of the
caller's x87 rounding-control bits. `FISTP` follows those bits, so the assembly
now saves the caller's control word, selects round-toward-zero for the `u`,
`v`, and inverse-depth conversions, then restores the original word. The
zero-or-negative depth clip is performed before reciprocal evaluation, matching
the C early-out and avoiding a divide-by-zero exception for clipped zero depth.
The routine's texture mapping, clipping, depth test, and pixel-store algorithm
remain the existing ones.

## Direct differential fixture

The BENCH486 fixture compares C and assembly framebuffer and depth results,
guard regions, register/stack behavior, and x87 control-word restoration. It
covers clipping and edge boundaries, coordinate clamps, pixel sizes/aspects,
and depth occlusion. The 26 direct cases run under each of four x87 rounding
modes: **104 exact C/ASM comparisons**, with repeated streams and zero
failures. DOSBox-X recorded progress for each mode and finished the fixture at
`out/dos-bench-20261010-023405/quake/BENCH486.TXT`; its report is
`out/dos-bench-20261010-023405/bench-result.json`.

## Paired scene parity

The strict paired run used the configured DOSBox-X i486 target and the
`demo2-wizspike-event` scenario: ten timedemo frames, two repeats for each
profile, and one `R_RunParticleEffect` event at frame 10 in every run. After
the four warmup checksum rows, all seven frame checksums matched across the
reference/candidate profiles and across repeats. Each of the four captured
320x200 indexed framebuffers matched exactly (64,000 indices, zero differences)
and all 768 palette bytes matched. The final framebuffer checksum was
`16764447`. The pair report is
`out/particle-draw-parity-20261010/render-parity-result.json`.

The measured profile medians were 12.2989385 FPS for C and 12.298983 FPS for
assembly (both 12.30 FPS rounded). These short scenario timings are regression
context only, not a benchmark or speedup claim.

## Strict i486 audit

The C executable audit decoded 204,681 instructions and the assembly executable
audit decoded 205,154. Both reports target `i486` and have zero above-i486
violations, unknown or unclassified instructions, and exemptions:

- C: `out/profile-86fee8e9fb75b9c2/isa-qbench/relocated-20261010-044327822/strict-isa.json`
- Assembly: `out/profile-79ed86c9de0c8891/isa-qbench/relocated-20261010-045549664/strict-isa.json`

The paired builds also passed the normal source-bound compatibility gate. Its
startup proof accounted for 529 CODE rows, and its maintained DPMI provider
proof decoded 9,207 instructions with no exemptions. The pair report records
`isaAuditStatus: PASS` for both profiles.

## Reproduction and limits

From `quake/`, rerun the direct fixture and exact paired scene with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 -CpuTarget i486 -ParticleDrawImplementation asm -ParticleDrawOnly -NoBootstrap
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 -ReferenceProfile tools/renderer-profiles/i486-particledraw-c.json -CandidateProfile tools/renderer-profiles/i486-particledraw-asm.json -ScenarioFile tools/render-scenarios-runparticleeffect.json -Scenario demo2-wizspike-event -CpuTarget i486 -OutputRoot out/particle-draw-parity-20261010 -NoBootstrap
```

This evidence accepts the existing `D_DrawParticle` assembly path against its
C oracle and the tested event-driven scene. It does not close the full renderer
ownership inventory, broader particle-effect stress/sequence coverage, or sky
coverage. The routine uses x87 instructions; this DOSBox-X i486 run does not
establish support for a 486SX without an FPU or constitute a physical-hardware
test.
