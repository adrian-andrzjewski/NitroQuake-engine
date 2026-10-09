# `R_SetupFrame` assembly port (2026-10-09)

## Per-frame renderer setup

`R_SetupFrame` in `src/r_misc.c` enforces multiplayer cvar restrictions,
records optional surface/edge statistics, advances frame and animated-light
state, builds the camera basis, finds the current BSP leaf, updates waterwarp
and viewport state, transforms the frustum, snapshots camera vectors, resets
renderer counters, and calls `D_SetupFrame`.

The selected assembly implementation is `src/r_setupframe_asm.inc`, included
by `src/v_viewcontrolasm.s` under `ViewControlImplementation=asm`. The ordinary
C selector remains the reference. BENCH486 builds retain the same C body as
`R_SetupFrame_View_C` while the assembly entry owns the production symbol. The
focused profiles `i486-viewcontrol-c.json` and `i486-viewcontrol-asm.json`
change only that selector.

The assembly preserves the original ordering and delegates the same operations
to the existing angle-vector, alias-view, BSP leaf, viewport, frustum, sky and
drawing setup routines. It uses the 32-bit cdecl ABI, saves EBP, leaves
EAX/ECX/EDX caller-owned, and keeps its x87 stack empty across calls. C layout
contracts in `src/asm_viewcontrol.h` pin the refdef, video, client, server,
leaf, surface, edge, and cvar fields used by the routine. Float-to-int casts
use a temporary truncation mode and restore the caller's x87 control word. The
viewport code retains the original assignment order, including the existing
height-clamp calculation.

## Verification

The focused BENCH486 candidate passed the complete i486 executable gate. The
project and installed runtime proofs covered 123 project objects and 235
runtime objects. The linked audit covered 204,912 instructions and 340
source-bound code contributions; 1,591 relocated ranges were checked. Startup
and CWSDPMI checks covered 529 startup rows and 9,207 provider instructions.
There were zero above-i486 instructions, unknowns, exemptions, or mismatched
linked opcodes. The candidate qbench executable SHA-256 is
`2606614D48CA88EAB1FB5BCE819DD2D355F34DBA114F1CB89A946C245E304BD1`.

The C and assembly profiles ran on DOSBox-X's i486 target and matched exactly:

| Scene | Compared checksums after 6 warmup records | Captured image |
|---|---:|---|
| `demo2-entity-workload` | 980 of 980 | 320x200 pixels and palette exact |
| `demo1-viewsize-50` | 964 of 964 | 320x200 pixels and palette exact |
| `demo3-world-workload` | 1,085 of 1,085 | 320x200 pixels and palette exact |

All three framebuffer diffs contain zero pixel-index and palette-byte
mismatches. The measured reference/candidate rates were 12.887602/12.887604,
18.071871/18.071900, and 12.106563/12.106563 FPS respectively; these are
single-run observations, not a performance claim. The paired reports are
under `out/render-parity-setupframe-{entity-strict,viewsize,demo3}-20261009`.

`tools/test-rendering.py` passes 55 tests, `tools/test-renderer-ownership.py`
passes two tests, and `tools/test-build-dos.py` passes its pinned i486/i386
flag checks. The view-control object disassembly was inspected alongside the
linked executable audit; it contains only 486 integer/control instructions and
387-compatible x87 operations.

## Scope still open

This is focused coverage, not complete renderer acceptance. Waterwarp sizing,
debug-stat branches, multiplayer cvar enforcement, extreme dimensions,
long-running state stability, and broader gameplay/effect scenes still need
dedicated tests. The default release selector remains C. DOSBox-X's i486 mode
is emulator evidence rather than a genuine 486 hardware run.

To rebuild and repeat all strict checks, use a fresh output root:

```powershell
rtk proxy pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-viewcontrol-c.json `
  -CandidateProfile tools/renderer-profiles/i486-viewcontrol-asm.json `
  -Scenario demo2-entity-workload,demo1-viewsize-50,demo3-world-workload `
  -RunsOverride 1 -OutputRoot out/render-parity-rsetupframe-repro-20261009 `
  -CpuTarget i486 -TimeoutSeconds 600 -NoBootstrap
```
