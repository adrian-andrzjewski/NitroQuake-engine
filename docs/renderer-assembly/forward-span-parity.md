# Forward span generator parity

This slice validates the existing assembly implementation of Quake's forward
surface span generator. It does not claim that the renderer migration is
complete.

| Reference behavior | 486 implementation | Verification |
| --- | --- | --- |
| `R_LeadingEdge` and `R_GenerateSpans` in `src/r_edge.c` | `_R_GenerateSpans` in `src/r_edgea.s`; `_R_GenerateSpans_asm486` is an alias at the same entry address | `src/bench486_forwardspans.h` compares C and assembly state exactly; `tools/renderer-ownership.py` binds and audits both symbols |
| C trailing-edge and span cleanup used by the generator | Existing forward-edge assembly and its C ABI | The fixture runs the C oracle with C trailing/cleanup helpers and checks complete guarded buffers, links, span counts, globals, x87 state, and the assembly call ABI |

The B-model equal-key ordering path uses the C thresholds `newzi * 0.99` and
`newzi * 1.01`, which are double constants. The assembly loads matching double
constants. Although the C source writes `(float)(edge->u - 0xFFFFF)`, the pinned
i486 compiler keeps this conversion in its x87 extended-precision register and
does not materialize an intermediate single-precision value. The assembly keeps
the same `fild` plus exact `2^-20` scaling sequence; the fixture exercises this
fixed-point boundary under all four x87 rounding modes. The current fixture has
16 cases and requires exact state parity for all 64 comparisons. These
operations use the 486DX x87; this slice does not support a 486SX without an
FPU.

The deterministic fixture covers empty and opaque spans, overlapping and
same-edge surfaces, inverted and zero-width spans, equal keys, B-model depth
ordering, both double-precision depth boundaries, the fixed-point-to-float
boundary, and a fractional pixel edge. It runs every case with all four x87
rounding modes. Surface, edge, and span pools have guard regions; the comparison
includes their complete contents and the resulting linked span state. There is
no framebuffer tolerance in this fixture: all compared state must match
exactly.

Run the host checks from the `quake` checkout:

```powershell
rtk proxy python .\tools\test-rendering.py
rtk proxy python .\tools\test-renderer-ownership.py
rtk proxy python .\tools\test-build-dos.py
```

Run the deterministic DOSBox-X comparison and the complete i486 executable,
startup, runtime-provider, and renderer-ownership audits with:

```powershell
rtk proxy pwsh -NoProfile -Command '& .\tools\bench-dos.ps1 -NoBootstrap -CpuTarget i486 -ForwardSpansOnly -RenderPolyImplementation asm -PublicBindingsImplementation asm -ScreenNotifyImplementation asm -WorldControlImplementation asm -ScanEdgesImplementation asm -BackwardSpansImplementation asm -ParseParticleEffectImplementation asm -RunParticleEffectImplementation c'
```

The run writes its structured result and ISA reports under `out`. It is an
isolated correctness run, not a performance benchmark.

Verified on 2026-10-10 in DOSBox-X with the 486DX/x87 profile: all 16 cases
matched across four x87 rounding modes (64 exact C/assembly comparisons), and
the DOS process exited successfully. The linked executable audit covered
216,180 instructions; startup and runtime-provider audits covered 529 startup
code rows and 9,207 provider instructions. All three ISA gates reported zero
post-i486, unknown, or exempt instructions.
