# `R_ParticleExplosion2` -> i486 assembly port (2026-10-09)

## Particle pool semantics and ABI

`R_ParticleExplosion2` in `src/r_part.c` takes up to 512 nodes from
`free_particles`, prepends each to `active_particles`, sets the lifetime,
color and `pt_blob` type, and makes six ordered `rand()` calls per emitted
particle for its three origin and velocity components. The assembly leaf in
`src/r_particleexplosion2asm.s` preserves the list updates, early exhaustion,
512-particle limit, signed color remainder, field stores and RNG order. Its
particle and `cl.time` offsets are checked with compile-time layout assertions.
The BENCH486 assembly build retains `R_ParticleExplosion2_C` as the oracle.

`ParticleExplosion2Implementation=c|asm` maps to
`ASM486_PARTICLE_EXPLOSION2`. The focused profile is
`tools/renderer-profiles/i486-asm-particle-explosion2.json`; the cumulative
88-selector profile records this addition in
`tools/renderer-profiles/i486-asm-selectable-88.json`.

## Full-state fixture and i486 results

`Bench486ParticleExplosion2Cases` in
`src/bench486_particleexplosion2.h`, invoked by
`-benchparticleexplosion2`, compares the complete guarded particle pool,
active/free list heads, emitted particle fields and next RNG value between C
and assembly. Six cases cover empty, single, short, almost-full, full and one
extra free node. The fixture restores particle globals and `cl.time`; because
it reseeds and advances libc's global RNG, the runner exits the disposable
BENCH process after the test.

The combined i486 BENCH build selected both `ParticleExplosion2Implementation=asm`
and `PrintTimesImplementation=asm`. All ISA gates passed: 165,846
instructions across 127 selected objects; 204,143 instructions across 362
linked objects; all 204,143 executable opcodes were verified across 348 text
ranges. The relocated executable, 529 startup rows and 9,207 runtime-provider
instructions also passed with zero above-i486, unknown or exempt instructions.

DOSBox-X completed all six full-state and RNG continuation cases with zero
failures. This validates the particle-generation leaf, not its later rendering
or whole-frame framebuffer parity. As in the original C expression,
`colorLength` must be nonzero. Reproduce it with:

```powershell
rtk pwsh -NoProfile -File tools/build-dos.ps1 `
  -Benchmark -ParticleExplosion2Implementation asm `
  -PrintTimesImplementation asm -NoBootstrap
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -ParticleExplosion2Only -ParticleExplosion2Implementation asm `
  -PrintTimesImplementation asm -SkipBuild -NoBootstrap
```
