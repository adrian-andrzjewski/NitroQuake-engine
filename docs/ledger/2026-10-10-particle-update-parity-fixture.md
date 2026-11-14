# Particle update i486 parity fixture

Status: validated on 2026-10-10 with the strict i486 build and DOSBox-X.

## Traceability

src/renderer/r_part.c:R_DrawParticles_C is the reference for
src/renderer/asm486_experiments.s:R_DrawParticles_asm486. The fixture in
src/tests/bench486/bench486_particleupdate.h seeds a deterministic particle pool, then runs
the C routine and assembly routine from the same initial state. Both paths use
the assembly particle rasterizer so the comparison isolates the update loop.

The test compares ten consecutive frames for four x87 rounding modes. It
requires exact equality for the full particle pool, active/free list heads,
projection vectors, color buffer, depth buffer, and x87 control word. It also
checks the caller ABI, framebuffer canaries, and state restoration. No
framebuffer or particle-state tolerance is used.

The first run exposed a real rounding mismatch in the Z velocity update for
pt_explode, pt_explode2, and pt_blob. GCC keeps the product in x87 extended
precision through the following gravity subtraction, then stores the result
once. The assembly had stored the product to float before subtracting gravity.
The assembly now follows the C instruction order, and the exact multi-frame
comparison passes.

## Reproduction and evidence

Run the strict i486 build, executable/runtime ISA audit, and isolated emulator
fixture with:

~~~powershell
rtk pwsh -NoProfile -File .\tools\bench-dos.ps1 -NoBootstrap -CpuTarget i486 -ParticleUpdateImplementation asm -ParticleDrawImplementation asm -ParticleUpdateOnly
~~~

The fixture passed its 40 frames across four x87 rounding modes with exact
equality.
The strict linked audit decoded 211,647 instructions across the build and
runtime objects, with zero above-i486, unknown, or exempt instructions. The
startup audit covered 529 CODE rows, and the DPMI provider proof covered 9,207
instructions with zero exemptions. Source mapping passed for all 368
source-bound code contributions; the 1,683 CODE ranges were checked and 13
DATA ranges were excluded from instruction decoding.

The executable SHA256 was
C085FE64A2A9A2E827B657FEDC8B388D17D6DC6472C4F73C6FBE2AAA0770525E.
The captured run report is
out/dos-bench-20261010-164449/bench-result.json; ISA reports are under
out/profile-093783e03ea47bfb/isa-qbench/.
