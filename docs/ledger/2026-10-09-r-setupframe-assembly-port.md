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

## Waterwarp and frame-state stress extension (2026-10-12)

`tools/render-scenarios-viewcontrol-waterwarp.json` adds four exact-tolerance
stress scenarios for the same C and assembly profiles. Both `demo1` and
`demo2` run with waterwarp disabled and enabled, `r_numsurfs 1`, `r_numedges 1`,
`r_ambient -16`, and `viewsize 50`; `demo1` also uses `d_subdiv16 1`. The
manifest records one run per case, a frame-169 PCX golden for each demo, and
the final expected checksum for each replay.

The C/assembly pair passed all four cases: 3,888 post-warmup checksum records
matched exactly, all four 320x200 captures matched every pixel index and
palette byte, and there was no edge overflow. The enabled waterwarp path was
observably exercised by `demo2`: toggling waterwarp changed 210 later
post-warmup checksum records (starting at record 459) in both C and assembly;
the C and assembly streams still matched exactly for each setting. `demo1`
produced no changed records when toggled, so it is retained as an exact
regression case rather than evidence that its replay enters a waterwarp area.
Reference goldens are SHA-256 `78763F76315FB7BC8D72982B9C3B7F1471B6DD95B4682FAD0A2BC618F9CF0B1C`
for `demo1` and `B210C2A8224854C91D0987476C2E9FAFA2E9A729FD6478F8EAA56880833ED9E3`
for `demo2`.

The stress-pair DOSBox rates were approximately 17.64 FPS for `demo1` and
18.20/17.97 FPS for `demo2` with waterwarp off/on. These runs enabled counters
and used a reduced viewport, so they are not comparable to the normal-scene
rates above and are recorded only as workload observations. The separate
strict i486 candidate build for the same assembly selector passed the complete
source-object, linked-image, startup, and CWSDPMI-provider gates with zero
above-i486 instructions, unknown instructions, exemptions, or unverified
bytes. Its candidate qbench SHA-256 is
`98092915B89BEC6592505302B4696F47D7CB7A2B2A72DB4CCE001828450BE558`.

Reproduce the deterministic stress pair with:

```powershell
rtk pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-viewcontrol-c.json `
  -CandidateProfile tools/renderer-profiles/i486-viewcontrol-asm.json `
  -ScenarioFile tools/render-scenarios-viewcontrol-waterwarp.json `
  -RunsOverride 1 -OutputRoot out/render-parity-rsetupframe-waterwarp-repro-20261012 `
  -TimeoutSeconds 600 -VisualParityOnly -NoBootstrap
```

`-VisualParityOnly` skips the in-run ISA gate. Rebuild and run the complete
strict i486 executable audit separately using the assembly profile and
`CpuTarget=i486`; the captured strict result is under
`out/profile-809cad5829aff636/isa-qbench`.

## Scope still open

This is focused coverage, not complete renderer acceptance. The waterwarp
toggle, debug counters, negative ambient value, and reduced viewport now have
stress-pair evidence, but waterwarp sizing across modes, multiplayer cvar
enforcement, malformed/extreme dimensions, long-running state stability, and
broader gameplay/effect scenes still need dedicated tests. The default i486
release profile selects assembly, while the C selector remains the reference.
DOSBox-X's i486 mode is emulator evidence rather than a genuine 486 hardware
run.

To rebuild and repeat all strict checks, use a fresh output root:

```powershell
rtk proxy pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools/renderer-profiles/i486-viewcontrol-c.json `
  -CandidateProfile tools/renderer-profiles/i486-viewcontrol-asm.json `
  -Scenario demo2-entity-workload,demo1-viewsize-50,demo3-world-workload `
  -RunsOverride 1 -OutputRoot out/render-parity-rsetupframe-repro-20261009 `
  -CpuTarget i486 -TimeoutSeconds 600 -NoBootstrap
```
