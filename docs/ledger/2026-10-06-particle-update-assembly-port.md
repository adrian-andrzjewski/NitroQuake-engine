# Particle-update assembly port

Status: ongoing renderer port. The C implementation remains the default
reference; this conversion targets explicit i486 instruction compatibility and
visual parity, not a speed promotion.

## `R_DrawParticles` now has a selectable i486 assembly path

`ParticleUpdateImplementation=c|asm` selects the original C loop or
`R_DrawParticles_asm486`. The C wrapper retains the `D_StartParticles` and
`D_EndParticles` calls, supplies the current time and gravity values, and
aggregates PROFILE486 counters and timing. The assembly loop owns dead-particle
unlinking, live-particle drawing order, position updates, type-specific velocity
and ramp updates, color selection, and list continuation. It calls the existing
`D_DrawParticle`, whose software rasterizer remains in the legacy driver
assembly.

The loop preserves the reference order: expired particles move to the free list;
live particles are drawn before their positions and velocities are updated; the
next link advances only after the current update. The optional zero-horizontal
gib-trail selector keeps its C reference behavior. `d_ifacea.h` now names all
eight `ptype_t` values for assembly, and compile-time checks pin the C particle
record offsets and 40-byte size.

A PROFILE486 inspection before this port placed the particle C path at roughly
0.8% of measured frame time. That is diagnostic context only; particle coverage
is part of the requested compatibility port regardless of its timing share.

## Build, ISA, and render validation

The selectable release build passed its post-link i486 audit with 168,460
decoded instructions, zero enforced above-i486 instructions, and zero unknown
instructions. The all-assembly benchmark profile passed with 205,800 decoded
instructions and the same zero/zero result. Both reports list only the existing
CRC-table byte sequence as an explicit data exemption. The source audit scanned
82 C and 21 assembly sources, decoded 119,033 instructions, and found no
above-i486 or unclassified instructions. The default i486/i386 build flag lists
remain golden-pinned.

The `i486-asm-selectable` profile passed all six deterministic DOSBox-X 486
scenes, with two runs per scene and `repeatParity: PASS` in every case:

| Scene | Timedemo frames | Pinned checksum | Changed pixels per capture |
|---|---:|---:|---:|
| `demo1-vesa-full` | 969 | `1047377823` | 12 / 12 |
| `demo1-vga-full` | 969 | `1047377823` | 12 / 12 |
| `demo1-fullbright` | 969 | `4021309056` | 0 / 0 |
| `demo1-viewsize-50` | 969 | `885630476` | 2 / 2 |
| `demo2-entity-workload` | 985 | `1887495667` | 0 / 0 |
| `demo3-world-workload` | 1,090 | `2316550348` | 0 / 0 |

Both repeated frame streams matched after the six-frame warmup in every scene.
Demo3 had 1,067 unique post-warmup checksums per run, zero zero-checksum
frames, and a longest identical-frame run of ten. The six captured PCX images
passed their pinned reference tolerances. Fullbright, demo2, and demo3 were
pixel-exact; the VESA and VGA references each differed by 12 pixels and the
reduced viewport by two, as in the established reference captures.

Automated checks passed: `test-build-dos.py`, all 14 `test-rendering.py` cases,
`test-isa-audit.py`, the i486 source scan, the post-link audit, and the
documentation structure check. The direct one-run C-reference checksum-stream
comparison is recorded below when complete.

The full report is `out/render-validation-20261006-062232/` and contains each
timedemo result, frame-checksum stream, capture, image diff, and scenario summary.
The object reports are under the release build directory ending in
`particleupdateasm` and `out/profile-30cd6d87d1e638e4/isa-audit.json`.

## Remaining particle closure

Compare the all-assembly frame streams against a matched `i486-c-reference`
profile, then retain both selector choices and the exact scene artifacts. Keep
the C reference available for isolated particle-state comparisons and long-run
regression diagnosis.

## `R_ClearParticles` free-list reset follow-up (2026-10-09)

`ParticleUpdateImplementation=c|asm` now selects both particle initialization+and particle simulation. The original C `R_ClearParticles` loop remains the+reference and is exported as `R_ClearParticles_C` only in benchmark builds.+The assembly replacement is isolated in `src/r_particlelist.s`, with its+`particle_t` field constants in `src/asm_particlelist.h` and the existing C+layout assertions guarding the 16-byte `next` offset and 40-byte structure.+
The i486 routine publishes `free_particles`, clears `active_particles`, links+the nodes in ascending order, and terminates the final node. It mirrors the C+loop's one-past link store and final indexed null store, so the completed pool+matches byte-for-byte. A signed nonpositive-count path retains the reference's+final indexed store for the bounded zero/negative fixture cases without looping.+The implementation uses cdecl and caller-saved `%eax`, `%ecx`, and `%edx`; it+does not modify callee-saved registers.

`-ParticleListOnly` runs a direct DOSBox C/ASM fixture. It compares the complete+guarded particle pool, active/free heads, and particle count for counts+`1, 2, 3, 17, 512, 1024, 2048, 0, -1`, and uses `Bench486Call_asm486` to verify+the calling convention for both paths. The linked object is also included in the+existing i486 binary ISA gate and the pinned build-source inventory.

### Validation (2026-10-09)

`test-build-dos.py`, `test-rendering.py` (51 tests), and `test-isa-audit.py` passed. The release i486 build passed the object and linked executable gates: 171,204 relocated instructions, 529 startup rows, and 9,207 provider instructions were checked, with zero above-i486 instructions, unknown encodings, or exemptions. The benchmark profile passed the same complete gate for 202,319 relocated instructions.

The DOSBox-X particle-list fixture passed all nine counts with zero failures. It verifies the free-list state and calling convention; matched framebuffer parity for the updated particle selector remains part of the broader renderer parity gate. The complete startup proof also requires a native Windows MinGW GCC on `PATH`; the DJGPP target compiler is intentionally rejected for that host-only step.
