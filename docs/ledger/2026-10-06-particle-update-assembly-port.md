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
