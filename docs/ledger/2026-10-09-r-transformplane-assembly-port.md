# `R_TransformPlane` assembly slice (2026-10-09)

## Semantics and focused fixture

`R_TransformPlane` in `src/renderer/r_misc.c` now has a selectable-symbol boundary for
`ASM486_TRANSFORM_PLANE`. The standalone entry is
`src/renderer/r_transformplaneasm.s`; it retains the original dot-product order,
materializes the source's local `float d`, stores `p->dist - d`, then calls the
existing 32-bit `TransformVector` x87 routine. The precision-sensitive case is
intended to verify the selected compiler's actual C-oracle behavior for that
local. The original C body remains as `R_TransformPlane_C` in BENCH486 assembly
builds.

`src/tests/bench486/bench486_transformplane.h` supplies seven finite signed/zero/mixed-value
cases, including a cancellation input sensitive to intermediate precision;
direct C/assembly calls through the ABI probe; guarded input/output storage;
two independent exact-value checks; and full output/state comparison.

## Focused validation and remaining scene coverage

The selector, assembly-source manifest, host command, and DOS runner are wired.
The focused DOSBox-X i486 fixture passed all seven cases with exact output and
ABI-state parity, including the precision-sensitive cancellation case. The
final BENCH486 build with this selector and the parallel particle-explosion
selector enabled passed the complete executable ISA gate with zero post-i486
or unknown instructions. The focused fixture command was:

```powershell
tools\bench-dos.ps1 -SkipBuild -TransformPlaneOnly `
  -ParticleExplosionImplementation asm -TransformPlaneImplementation asm
```

Traceability: `r_misc.c:R_TransformPlane` ->
`r_transformplaneasm.s:R_TransformPlane_asm486` ->
`bench486_transformplane.h:Bench486TransformPlaneCases` -> linked i486 audit and
the focused DOS fixture. A source search found no direct renderer call site for
this helper, so scene/framebuffer parity through this path remains pending; the
focused fixture currently proves exact helper output and ABI-state parity.
