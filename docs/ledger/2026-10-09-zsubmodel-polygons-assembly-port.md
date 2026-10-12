# Z-submodel polygon driver assembly port (2026-10-09)

## Optional submodel polygon driver

`R_ZDrawSubmodelPolys(model_t *)` walks a model's surfaces, computes the
view-origin distance to each surface plane, applies the `SURF_PLANEBACK` and
`BACKFACE_EPSILON` tests, and forwards visible surfaces to
`R_RenderPoly(surface, 15)`. The DOS frame path calls this optional pass only
when `r_drawpolys` or `r_drawculledpolys` is enabled. The standard span driver
leaves `r_drawpolys` false, so ordinary scene captures do not exercise it.

The assembly entry is `R_ZDrawSubmodelPolys_asm486` in
`src/r_zsubmodelasm.s`. It follows the original floating-point operation order
and x87 status-word tests, uses the established 32-bit cdecl convention, and
preserves EBX, ESI, and EDI. `src/asm_zsubmodel.h` pins the structure offsets
and sizes used by the assembly with compile-time layout checks. The new
`ZSubmodelPolygonsImplementation` selector defaults to C; the assembly profile
is `i486-asm-zsubmodel`.

The BENCH-only C oracle and fixture compare plane decisions, surface call order,
clip flags, renderer state, x87 status, guards, and ABI preservation. The
callback records the `R_RenderPoly` arguments instead of rasterizing them, so
this is a direct decision-and-forwarding test, not a pixel test of
`R_RenderPoly`. Other optional polygon paths and the rasterizer remain separate
work. No frame-time improvement or regression is claimed: the normal span path
leaves this optional pass disabled, and this fixture measures correctness rather
than throughput.

Validation results:

- `tools/test-rendering.py`: 53 tests passed.
- `tools/test-build-dos.py`: passed after pinning the additional assembly
  source in both i386 and i486 build manifests.
- The i486 benchmark executable passed the project-object audit: 122 objects
  and 163,544 decoded instructions, with no instruction above i486.
- Runtime-source verification passed for 235 installed objects. The linked
  object audit covered 357 objects and 201,809 instructions; the linked
  executable audit verified all 201,809 relocated opcodes across 341
  source-bound code contributions and 1,598 ranges. It reported zero
  post-i486, unknown, exempted, or unverified instructions.
- Audited `qbench.exe` SHA-256:
  `0900FFCB2A3B1047B1CB93273FEBD251BB26CBDD51880E21DA556552F21F7E0A`.
- That exact executable ran under the repository's DOSBox-X i486 profile. The
  fixture printed all 12 x87-mode markers and progress through 4096 continuous
  calls, then reported 4,483 cases and zero failures. The retained run log is
  `out/dos-bench-zsubmodel-20261009-manual/quake/bench486.txt`.
- DOSBox-X's i486 profile provides a representative execution environment, not
  instruction gating; the linked executable audit above is the ISA gate.

The regular `bench-dos.ps1` wrapper stopped after the target-code audits while
running its additional host-side DJGPP assembler proof: this machine has no
Windows MinGW GCC on `PATH`. The already audited executable was then staged
directly with the same DOSBox-X 486 profile and passed the focused fixture.
This host-tool proof remains an environment limitation; it is not an ISA
failure in the renderer executable.

## 2026-10-12 strict rerun and scene-pair limit

The standard wrapper now completes the focused i486 gate with:

```powershell
rtk pwsh -NoProfile -File tools/bench-dos.ps1 `
  -ZSubmodelPolygonsOnly `
  -ZSubmodelPolygonsImplementation asm `
  -CpuTarget i486 -TimeoutSeconds 180
```

`out/dos-bench-20261012-132910/quake/BENCH486.TXT` records all 12 x87 control
word settings, progress through 4,096 continuous calls, and a pass for 4,483
exact cases with zero failures. The DOSBox window can remain visually quiet
after its short `486 benchmark begin` marker because the fixture's detailed
progress and result are written to `BENCH486.TXT`.

The strict executable gate passed for this build: 172,785 project-object
instructions, 211,082 relocated executable instructions, 529 embedded startup
instructions, and 9,207 CWSDPMI provider instructions were audited with zero
post-i486 instructions, unknown instructions, or exemptions. The retained
`out/dos-bench-20261012-132910/bench-result.json` records the i486 target and
provider verification.

A C/assembly selector pair also completed the three standard DOSBox-X scenes
twice each in `out/render-parity-zsubmodel-20261012`: all 6,058 compared
post-warmup checksums, six 320x200 indexed framebuffer captures, and six
palettes matched exactly. This is only a surrounding-renderer stability check.
It does **not** demonstrate pixel parity for `R_ZDrawSubmodelPolys`: the DOS
span driver sets `r_drawpolys` false, and the BENCH-only
`bench486_renderpolys 1` command explicitly reports that polygon rendering is
unavailable and leaves edge scanning enabled. The focused callback fixture
also records `R_RenderPoly` calls instead of rasterizing them. The optional
polygon driver's rendered output therefore remains unverified by these scene
captures. The pair report is visual-parity-only and skips its own ISA audit;
the separate strict build above supplies the ISA evidence.

To reproduce the flag and source checks, run `rtk python
tools/test-build-dos.py` and `rtk python tools/test-rendering.py`. With a Windows
host GCC available to the assembler proof, run
`rtk pwsh -NoProfile -File tools/bench-dos.ps1
-ZSubmodelPolygonsImplementation asm -ZSubmodelPolygonsOnly` for the built-in
ISA and DOSBox-X path.
