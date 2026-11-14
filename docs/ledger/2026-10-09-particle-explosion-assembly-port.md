# `R_ParticleExplosion` -> i486 assembly port (2026-10-09)

## Standard explosion particle pool semantics and ABI

`R_ParticleExplosion` in `src/renderer/r_part.c` emits up to 1024 particles, popping
each node from `free_particles` and prepending it to `active_particles`. It
sets the five-second lifetime, `ramp1[0]` palette byte, random ramp, and
alternating `pt_explode2`/`pt_explode` type. Each emitted particle consumes
seven random values in order: one ramp value, then origin and velocity values
for x, y, and z. The assembly in `src/renderer/r_particleexplosionasm.s` preserves the
early-exhaustion boundary and uses signed `IDIV` for the C `% 32` and `% 512`
expressions. `r_part.c` compile-time assertions pin the particle fields, client
time offset, and particle type values. BENCH486 builds retain the C oracle as
`R_ParticleExplosion_C` under `ASM486_PARTICLE_EXPLOSION`.

The selector is `ParticleExplosionImplementation=c|asm`; selecting `asm`
defines `ASM486_PARTICLE_EXPLOSION` and picks up the standalone assembly source
in all i486 build manifests.

## Full-state fixture and i486 validation

`Bench486ParticleExplosionCases` in `src/tests/bench486/bench486_particleexplosion.h` compares
the guarded particle pool, links, emitted particle fields, ABI flags, random
call count, and next RNG value between C and assembly. It covers empty,
single-particle signed-remainder, alternating types, short, almost-full, full,
and one-extra-node cases. Scripted BENCH random values include negative
operands to check signed C remainder behavior; the one-extra-node case checks
continuation of the seeded libc `rand()` stream. The fixture restores particle
globals and `cl.time`; the libc case advances process-global RNG state, so run
it in a disposable BENCH486 process. The focused DOSBox-X i486 run passed all
seven cases, including full pool exhaustion and the next seeded RNG value.

The final BENCH486 build with this selector and the parallel `R_TransformPlane`
selector enabled passed the complete executable ISA gate: selected objects,
linked objects, relocated executable bytes, startup code, and runtime provider
were all classified with zero post-i486 or unknown instructions. The focused
fixture command was:

```powershell
tools\bench-dos.ps1 -SkipBuild -ParticleExplosionOnly `
  -ParticleExplosionImplementation asm -TransformPlaneImplementation asm
```

The fixture proves exact particle-pool, link, emitted-field, ABI, random-call,
and RNG-continuation equivalence for its cases. It does not render a complete
scene or establish framebuffer parity; that broader renderer gate remains
pending. Traceability: `r_part.c:R_ParticleExplosion` ->
`r_particleexplosionasm.s:R_ParticleExplosion_asm486` ->
`bench486_particleexplosion.h:Bench486ParticleExplosionCases` -> selectable
i486 executable audit and focused DOSBox-X fixture.
