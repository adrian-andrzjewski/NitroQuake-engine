# Reject overlapping the Span16 S-adjust load with x87 endpoint math (2026-10-22)

The assembly-only candidate moved `movl C(sadjust),%ebp` from after the
remaining-count decrement to between the first endpoint `fmul` and `fxch` in
`LNotLastSegment`. The candidate retained exact output, but its three-run mean
was below control. The load has been restored to its original position in
`src/renderer/d_draw16.s`.

Both variants used the same uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI,
and pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
control was the immediately preceding three-run block. Each variant rendered
969 frames with framebuffer checksum `1047377823` on every run.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Candidate | 15.601299, 15.601303, 15.601295 | 15.601299 | 0.000008 |

The candidate delta is **−0.000004 FPS (−0.00002564%)**. Under the any-positive
pooled-mean rule, this negative mean rejects the change. No separate trailing
control was run.

The complete strict i486 audit passed: 313,376 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All six timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-183910/timedemo-result.json`
- Candidate build and ISA reports: `out/local-span16-sadjust-x87-overlap-20261022/`

Candidate fingerprints:

- Build source fingerprint: `813B8A7C30272B8CC9959317A41337756410B6E5FDD4B941685073FCD34012C3`
- Source-tree fingerprint: `C0F7DC69FAAE31C72B757D1D5FB32F7C3D0AC4B7690911E3E7368217F7C87111`
- Executable SHA-256: `7671EBDBABB5C9986A3B00065D71259B3C7715DA1E290E96E54A18BF96C60CC6`
