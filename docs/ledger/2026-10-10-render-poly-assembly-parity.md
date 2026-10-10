# RenderPoly assembly parity (2026-10-10)

## Original routine and assembly behavior

`src/r_draw.c:R_RenderPoly` transforms and clips the polygon vertices, computes
the projected coordinates and reciprocal depth, then hands the live polygon
descriptor to `D_DrawPoly`. The selectable replacement is
`src/asm486_experiments.s:R_RenderPoly_asm486`; `RenderPolyImplementation`
continues to default to C, and the strict candidate profile selects assembly.

The near-clip branch now follows the built C reference at both outcomes. When
depth is below `0.01`, it clamps the stored single-precision depth and loads the
exact `100.0f` reciprocal used by GCC 12.2's compiled C path. Otherwise it
computes the reverse divide `1.0 / z` in the same x87 operand form as the C
reference. This fixes the one-ULP `nearzi` mismatch previously observed under
round-up mode.

## Direct differential oracle

`src/bench486_renderpoly.h` runs C and assembly from the same fixture and
captures the descriptor and projected vertices at the `D_DrawPoly` lifetime
boundary. The capture hook in `src/d_edge.c` exists only in the BENCH,
public-bindings and RenderPoly-assembly profile. The fixture checks raw float
bits, vertex order, callback count and arguments, descriptor pointers, clipping
links, `r_pedge`, other global state, and ABI guards over 14 geometry/axis
variants and 12 x87 control words (168 pairs). The fixture restores `r_pedge`
and renderer state after the run so it cannot leave a pointer into its static
test geometry.

The only explicit tolerance is x87 status-word C1 (bit `0x0200`), and only when
both implementations leave invalid-operation (IE) and stack-fault (SF) clear.
The fixture fails immediately if either implementation raises either flag,
then compares all remaining status bits exactly apart from nonexceptional C1.
This follows Intel's documented distinction between C1's round-up meaning and
its overflow/underflow meaning when IE and SF are set ([Intel SDM, Volume 1](https://cdrdv2-public.intel.com/843827/253665-sdm-vol-1-dec-24.pdf)).
All captured outputs remain exact. The reported C1 count is a raw bit-difference
count; it can include a case that separately fails the IE/SF rule and never
turns that failure into a pass. The fixture prints the first differing
geometry, axis, plane, control word, and raw C/ASM status pair. This is a
status-word exception, not a framebuffer tolerance.

The capture stops at `D_DrawPoly`; it proves projection and descriptor parity,
not the polygon rasterizer or a full rendered-frame match. No performance claim
is made for `R_RenderPoly`.

## Strict i486 and paired-run evidence

The candidate is built by `tools/bench-dos.ps1` for `-CpuTarget i486`. The run
performs source-bound object and linked-code audits, relocated executable
decoding, startup and runtime-provider audits, then runs the fixture in the
repository's DOSBox-X 486 profile. `renderer-ownership.py` also runs after
manifest validation and reports renderer-reachable C entries and selected
indirect-call closures from the exact benchmark objects. Its parser ignores
undefined COFF symbols, accepts code in non-`.text` sections, retains local
assembly labels inside their enclosing function, and fails closed on unknown
symbol classes.

The RenderPoly fixture and ownership tests provide function-level evidence;
they do not establish full renderer framebuffer parity or completion of the
larger C-to-assembly migration. The C selector remains the release default.

## Traceability and reproduction

| Original behavior | Assembly replacement | Correctness evidence |
|---|---|---|
| `R_RenderPoly` transform, near clipping and projection in `src/r_draw.c` | `R_RenderPoly_asm486` in `src/asm486_experiments.s` | BENCH-only direct C/assembly capture in `src/bench486_renderpoly.h` |
| `D_DrawPoly` handoff boundary in `src/d_edge.c` | Same callback boundary after the assembly projection | 168 raw-bit C/ASM pairs, descriptor and ABI checks |
| Renderer ownership and selected function-pointer dispatch | Exact build-object report from `tools/renderer-ownership.py` | 16 host tests and automatic `bench-dos.ps1` invocation |

Run the host checks and the strict paired benchmark from `quake/`:

```powershell
rtk python tools/test-rendering.py
rtk python tools/test-renderer-ownership.py
rtk proxy pwsh -NoProfile -Command '.\tools\bench-dos.ps1 -NoBootstrap -CpuTarget i486 -RenderPolyImplementation asm -PublicBindingsImplementation asm -ScreenNotifyImplementation asm -WorldControlImplementation asm -ScanEdgesImplementation asm -BackwardSpansImplementation asm -PublicBindingsOnly'
```

The build manifest, machine-code reports, ownership report and DOSBox result are
written under the profile-specific directory in `out/`. Keep the manifest and
reports together when retaining evidence; generated audit JSONL files may be
compressed in place after the run finishes.
