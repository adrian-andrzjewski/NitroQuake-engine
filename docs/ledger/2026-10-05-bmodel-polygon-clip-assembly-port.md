# Brush-model polygon clipping assembly port

Status: focused selector slice accepted; the full renderer port remains ongoing.
This entry records the selectable conversion of `R_RecursiveClipBPoly` and its
exact paired parity and strict i486 evidence. It does not close the software-
renderer conversion or every brush-model clipping boundary.

## `R_RecursiveClipBPoly` now has a selectable i486 assembly entry

`BmodelPolygonClipImplementation=c|asm` selects the recursive brush-model BSP
polygon clipper. The C routine remains the default and benchmark reference. The
assembly path transforms each splitter plane into model space, classifies and
splits linked edges, creates intersection vertices and opposite-winding clip
boundary edges, visits visible BSP children, and dispatches visible leaf faces.
The selected C build asserts the 32-bit pointer size and every vertex, edge,
plane, node, leaf, and surface offset read by assembly. The benchmark C copy
recurses through itself, so the reference does not silently enter the assembly
path. Review caught and corrected a reversed stack layout for the temporary
plane-normal vector before the final assembly run; its components now occupy
the three consecutive addresses read by the x87 dot product.

The selector is wired through build, smoke, benchmark, and timedemo manifests.
`tools/test-build-dos.py` passed with the i486 and i386 golden flags unchanged.
The i486 assembly build linked and passed the ISA gate, and its release binary
passed DOS smoke. Under the pinned DOSBox-X 2026.08.31 profile, the corrected
assembly candidate completed 969 `demo1` frames in `59.233076 s` with checksum
`1047377823`. The C selector, rebuilt from the same source tree, completed the
same frame count in `59.170256 s` with the same checksum. These are single
samples, not an alternating benchmark; no speedup is claimed and C remains the
release default.

## `demo1` wall leak traced to the split fraction and fixed

Matched intermediate captures reproduced the user's missing wall and streak
artifacts in the assembly clipper. Its x87 sequence divided in the wrong
direction: for `lastdist = 2` and `dist = -2` it produced `2.0`, while the C
expression requires `0.5`. The off-plane intersection vertices multiplied the
edge list until `Out of edges for bmodel` aborted clipping. Switching the
sequence to `fdivrp` computes `lastdist / (lastdist - dist)` correctly.

The same `demo1` capture point now shows the wall and floor intact. The C
reference log had zero edge overflows, the pre-fix assembly log had 17, and the
corrected assembly log has zero. The corrected candidate also passes the
pinned 969-frame timedemo with checksum `1047377823` (one run: `59.449346 s`,
`16.299591 fps`). The broader assembler port remains ongoing; C remains the
release default, and this timedemo sample is not an alternating performance
comparison.

## Exact paired parity and strict i486 audit (2026-10-12)

Committed profiles `i486-c-reference-bmodel-clip-20261012` and
`i486-asm-bmodel-clip-20261012` each contain 85 renderer selectors. Their only
difference is `BmodelPolygonClipImplementation=c` versus `asm`. Both profiles
were built from the same source-tree fingerprint
`ABE9955C60AA3D5D27C280BFA05473831EB0D3B13225BF8D9E2883989EF0612C`.

The deterministic paired run used two repetitions of `demo1-vga-full`,
`demo2-entity-workload`, and `demo3-world-workload` under DOSBox-X 2026.08.31
with the pinned `dosbox-x-486-high.conf` profile. All 6,058 post-warmup frame
checksums matched exactly. All six 320x200 indexed framebuffer captures had
zero pixel-index or palette-byte differences. Each run had zero edge overflow.
The final frame checksums were `1047377823`, `1887495667`, and `3722973491`
for demos 1, 2, and 3 respectively.

| Scenario | Timedemo frames | C reference median | Assembly candidate median |
|---|---:|---:|---:|
| `demo1-vga-full` | 969 | 12.15 fps | 12.14 fps |
| `demo2-entity-workload` | 985 | 12.24 fps | 12.22 fps |
| `demo3-world-workload` | 1090 | 11.70 fps | 11.68 fps |

These rates are secondary evidence from the focused clipper selector pair, not
a full-renderer performance claim. The assembly candidate is within 0.2% of
the C reference in these runs.

Reproduce the parity run with:

```powershell
rtk pwsh -NoProfile -File tools\render-parity-dos.ps1 `
  -ReferenceProfile tools\renderer-profiles\i486-c-reference-bmodel-clip.json `
  -CandidateProfile tools\renderer-profiles\i486-asm-bmodel-clip.json `
  -Scenario demo1-vga-full,demo2-entity-workload,demo3-world-workload `
  -RunsOverride 2 -OutputRoot out\render-parity-bmodel-clip-20261012 `
  -TimeoutSeconds 600 -VisualParityOnly -NoBootstrap
```

`-VisualParityOnly` skips the renderer ISA gate, so the candidate selectors
were separately rebuilt with `CpuTarget=i486`, `Benchmark=true`, and
`BlobExplosionImplementation=c`, passing every selector in the assembly
profile to `tools\build-dos.ps1`. The strict build audited the benchmark
objects, all 378 source-bound runtime/object proofs, all 366 linked executable
`.text` ranges, startup bytes, and the CWSDPMI provider. The resulting
`qbench.exe` contained 206,313 decoded instructions: 206,312 i386-valid and
one i486 instruction, with zero Pentium-or-later, unknown, or exempt
instructions. The 1,660-byte startup image passed all 529 executable startup
rows; its linked startup helpers and the 9,207-instruction provider also
passed with zero exemptions. The audited `qbench.exe` SHA-256 is
`AA840A7588A3CDD397B27E90D2F80208078D8A656E59408D2EACEE3EEF54D250`.
Build output and machine-readable reports are under
`out\profile-85da44afaee44fbe\isa-qbench`.

Reproduce the strict selector build with:

```powershell
$profile = Get-Content -Raw tools\renderer-profiles\i486-asm-bmodel-clip.json | ConvertFrom-Json
$buildParameters = @{ Benchmark = $true; CpuTarget = 'i486'; NoBootstrap = $true; BlobExplosionImplementation = 'c' }
foreach ($selector in $profile.selectors.PSObject.Properties) { $buildParameters[$selector.Name] = $selector.Value }
& .\tools\build-dos.ps1 @buildParameters
```

The repository rendering checks also passed: `rtk python tools/test-rendering.py`
ran 99 tests successfully.
