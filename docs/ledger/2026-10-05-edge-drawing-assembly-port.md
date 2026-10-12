# Edge-drawing orchestration assembly port

Status: ongoing renderer port. This entry records the selectable assembly
conversion of `R_EdgeDrawing`; it does not close the software-renderer
conversion or its render-time dependency closure.

## `R_EdgeDrawing` now has a selectable i486 assembly entry

`EdgeDrawingImplementation=c|asm` selects the frame-level edge-drawing
orchestration. The C implementation remains the release default and benchmark
reference. The assembly entry chooses the caller-provided or aligned stack
edge buffer, installs the optional stack surface buffer, begins the edge frame,
runs the selected world renderer, performs culled/world edge scans, enables Z
testing before brush entities, preserves the `r_dspeeds` timestamps and extra
sound update, and closes the edge-drawing profile scope. Compile-time checks
pin `edge_t` and `surf_t` sizes, stack counts, cache alignment, and the cvar
value offset used by assembly.

The selector contract passed with the i486 and i386 default flag lists still
golden-pinned. C and assembly DOS smoke both passed. The assembly build passed
the i486 ISA gate at 168 enforced above-i486 instructions versus the 170
baseline. Its PROFILE486 qbench build also passed the ISA gate at 176 versus
the 177-instruction instrumented baseline.

The pinned `demo1` timedemo completed 969 frames with checksum `1047377823` in
`59.171652 s`. The matching C candidate completed with the same checksum in
`59.170319 s`. These single samples do not establish a speed gain; C remains
the release default.

Live playdemo captures from both paths showed the same room and camera
framing, with no frame trails or persistent smear. The captures were taken
after fixed `wait` counts and therefore landed at slightly different moving
entity/demo states: the second PCX pair differed in 14,927 of 64,000 decoded
pixels. This is not exact-frame parity evidence. The supplied page fault was
not reproduced, and its exact staged executable remains unidentified.

## Remaining edge-drawing closure

The matched-frame acceptance below closes the `R_EdgeDrawing` orchestration
check. Brush-entity polygon clipping and other active render-time setup and
draw dependencies remain. Keep the C reference selectable and retain the
pinned framebuffer checksum.

## 2026-10-12 matched-frame and i486 acceptance

The C and assembly selector profiles are now retained as
[`i486-c-reference-edge-drawing.json`](../../tools/renderer-profiles/i486-c-reference-edge-drawing.json)
and
[`i486-asm-edge-drawing.json`](../../tools/renderer-profiles/i486-asm-edge-drawing.json).
Their only selector difference is `EdgeDrawingImplementation=c|asm`. Both
profiles target i486 and were used against the same source-tree fingerprint
(`ABE9955C60AA3D5D27C280BFA05473831EB0D3B13225BF8D9E2883989EF0612C`).

The matched DOSBox-X pair covered `demo1-vga-full`,
`demo2-entity-workload`, and `demo3-world-workload`, twice per profile. All
6,058 post-warmup frame checksums matched. The six 320x200 indexed captures
also matched exactly: zero pixel-index or palette-byte mismatches across each
capture. The pair report is in
`out/render-parity-edge-drawing-20261012/render-parity-result.json`.

The timedemo rates were effectively unchanged:

| Scene | C reference FPS | Assembly FPS | Change |
|---|---:|---:|---:|
| `demo1-vga-full` | 12.150861 | 12.150649 | -0.0017% |
| `demo2-entity-workload` | 12.241847 | 12.241631 | -0.0018% |
| `demo3-world-workload` | 11.700718 | 11.700517 | -0.0017% |

These are paired DOSBox-X timedemo measurements, not real-486 performance
results. They show no material regression and are not a speed-based acceptance
claim.

The visual pair used `-VisualParityOnly`; its report therefore skips its own
ISA audit. A separate strict qbench build used the assembly profile's full
selector map plus `BlobExplosionImplementation=c`, matching the candidate
build manifest. The strict i486 audit passed: 167,870 instructions across 143
project objects; 206,167 instructions across 378 linked objects; and all
206,167 linked opcodes decoded across 366 executable `.text` ranges. Source
mapping passed for 1,640 CODE ranges and 12 DATA ranges, with no exemptions,
unclassified instructions, or undecoded bytes. The final-byte startup proof
covered 1,660 loaded bytes and 529 CODE rows; the loader and CRT helper audits
found no post-i486 instructions. The DPMI provider audit passed for 9,207
instructions, also with no exemptions. The complete executable ISA gate
passed. The audited executable was
`out/profile-0b199a47326b25bc/qbench.exe`, SHA-256
`1DC83C480D06F2C440080DD69A46ED1A2C747C38475EC5DC2C55B371BFEB0BFB`; the
hash-bound linked report is
`out/profile-0b199a47326b25bc/isa-qbench/isa-audit-linked.json`. The committed
C and assembly profile SHA-256 values are
`20C681784E5473DCCA8047F3AC5C2E4C1143B65FBB1EA32E9DD123974292646B` and
`924ED7DC35D911C3A8E0DA22EFAE4B9F08230CAA69E7C1D8E24B5D7692449295`.

Reproduce the visual pair with:

```powershell
pwsh -NoProfile -File tools/render-parity-dos.ps1 `
  -ReferenceProfile tools\renderer-profiles\i486-c-reference-edge-drawing.json `
  -CandidateProfile tools\renderer-profiles\i486-asm-edge-drawing.json `
  -Scenario demo1-vga-full,demo2-entity-workload,demo3-world-workload `
  -RunsOverride 2 `
  -OutputRoot ("out\render-parity-edge-drawing-" + (Get-Date -Format yyyyMMdd-HHmmss)) `
  -TimeoutSeconds 600 -VisualParityOnly -NoBootstrap
```

Then run the strict i486 qbench build with the same candidate selectors and
the matching `BlobExplosionImplementation=c` build setting:

```powershell
$edgeProfile = Get-Content -Raw tools\renderer-profiles\i486-asm-edge-drawing.json | ConvertFrom-Json
$buildParameters = @{
  Benchmark = $true
  CpuTarget = "i486"
  NoBootstrap = $true
  BlobExplosionImplementation = "c"
}
foreach ($selector in $edgeProfile.selectors.PSObject.Properties) {
  $buildParameters[$selector.Name] = $selector.Value
}
& .\tools\build-dos.ps1 @buildParameters
```

The reference remains the oracle and the C implementation remains the release
default. This accepts `R_EdgeDrawing` orchestration only; frame initialization,
brush-entity clipping, and remaining C list/span forwarding entries remain
open.
