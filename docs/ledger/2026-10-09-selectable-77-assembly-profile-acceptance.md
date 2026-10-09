# All-77-selector assembly profile acceptance (2026-10-09)

## Complete i486 executable gate

The opt-in `i486-asm-selectable` profile now sets all 77 declared renderer
selectors to `asm`, including `TransformFrustumImplementation`. The strict
paired run compared it with `i486-c-reference` at `CpuTarget=i486` in DOSBox-X,
one run per committed scenario. Both suites passed and the source-tree
fingerprints matched (`6FE9839E606AF326873711D4A104BBE4722FE787BA4C112B6B2C9A96944C4`).

The candidate `qbench.exe` SHA-256 is
`B15C6093E12DAE96454456ED522290474F381E571C07E6C0F990A4C00D12A149`. The
complete gate passed 224,570 relocated instructions, 529 startup code rows and
9,207 maintained CWSDPMI instructions. Exact source proofs covered 123 project
objects and 235 installed runtime objects (358 total). The linked audit mapped
346 source-bound code contributions and verified 1,758 relocated ranges. The
startup proof bound 1,660 loaded bytes; the provider proof covered one runtime
branch variant. Every gate reported zero post-i486 instructions, unknown
encodings, exemptions or opcode mismatches.

## Six-scene exact 77-selector parity

All six committed scenes passed with the reference and candidate built from the
same source-tree fingerprint. After six warmup frames, 5,921 frame checksums
matched exactly. The selected frame-169 320x200 indexed framebuffer and all
768 palette bytes matched for every scene: six exact captures, zero pixel-index
mismatches and zero palette-byte mismatches. The pair report is
`out/render-parity-selectable-77-strict-20261009/render-parity-result.json`.

| Scenario | Compared checksums | Reference FPS | Assembly FPS |
|---|---:|---:|---:|
| `demo1-vesa-full` | 964 | 12.684 | 12.555 |
| `demo1-vga-full` | 964 | 12.682 | 12.552 |
| `demo1-fullbright` | 964 | 13.102 | 12.958 |
| `demo1-viewsize-50` | 964 | 18.065 | 17.684 |
| `demo2-entity-workload` | 980 | 12.781 | 12.705 |
| `demo3-world-workload` | 1,085 | 12.175 | 11.929 |

The candidate was 0.6% to 2.1% slower in these workloads. This is a bounded
regression observation, not a completion criterion.

## Remaining 77-selector ownership and scope

The matching four-root ownership inventory is
`out/renderer-ownership-selectable-77-strict-20261009.json`. It reports 471
renderer entries, 381 directly reachable entries, 61 directly reachable
renderer C functions, 40 entries containing 121 indirect call/jump sites, and
26 unresolved direct callees. It is not a complete call graph; indirect targets
and renderer initialization/debug/support ownership still need review.

This result proves the all-selector profile, not a pure-assembly renderer or
the full completion criteria. Broad clipping and extreme-camera coverage,
long-run stability/corruption tests, representative gameplay and full ownership
closure remain open. Human visual/gameplay acceptance also remains pending.
The earlier 76-selector checkpoint and separate frustum-candidate results are
recorded in the [prior combined-profile acceptance](2026-10-09-selectable-assembly-profile-acceptance.md)
and [frustum port](2026-10-09-frustum-transform-assembly-port.md).

## Reproduction

From the `quake` directory, prepend the pinned host compiler directory to
`PATH` and run the paired strict workflow. Use a new, unused `OutputRoot` for
each rerun; this accepted run used:

```powershell
$env:PATH = 'user\AppData\Local\486quake\tools\host-tools\winlibs-gcc-12.2.0\mingw64\bin;' + $env:PATH
.\tools\render-parity-dos.ps1 `
  -NoBootstrap -CpuTarget i486 `
  -ToolRoot 'user\AppData\Local\486quake\tools' `
  -ReferenceProfile 'tools/renderer-profiles/i486-c-reference.json' `
  -CandidateProfile 'tools/renderer-profiles/i486-asm-selectable.json' `
  -RunsOverride 1 -TimeoutSeconds 600 `
  -Scenario demo1-vesa-full,demo1-vga-full,demo1-fullbright,demo1-viewsize-50,demo2-entity-workload,demo3-world-workload `
  -OutputRoot 'out/render-parity-selectable-77-strict-20261009'
```
