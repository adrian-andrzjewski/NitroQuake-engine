# D_PolysetScanLeftEdge height folded into the low-word counter (2026-10-28)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

The `D_PolysetScanLeftEdge` entry sequence used to load `height` into `EAX`,
mask off its upper 16 bits, and OR the result into `ECX` after loading
`d_sfrac`. The scan height contributes only to `CX`, which holds the 16-bit
row counter while the upper half of `ECX` retains the S fraction. A single
`orw height(%esp),%cx` replaces the height load, mask, and register OR; the
independent pointer loads are scheduled before it. This saves two executed
instructions per scan call and does not change the loop or branch behavior.

The profile counted 109,940 left-edge scan calls in the measured `demo1` run.
Object disassembly shows the scan function shrinking from 76 to 74
instructions. Six NOP alignment bytes were added after the rasterizer's `ret`,
so the object-wide static instruction total rose by four; those NOPs are
unreachable.

## Matched timedemo

Control and candidate used DOSBox-X 2026.08.31, the pinned 32 MB i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and CWSDPMI. All six runs rendered 969 frames with framebuffer
checksum `1047377823`.

| Variant | FPS samples | Mean FPS | Median FPS | Spread |
| --- | --- | ---: | ---: | ---: |
| Control | 16.238312 / 16.238258 / 16.238250 | 16.238273333 | 16.238258 | 0.000062 |
| Low-word height OR | 16.240126 / 16.240119 / 16.240126 | 16.240123667 | 16.240126 | 0.000007 |

The candidate mean increased **0.001850333 FPS (+0.01139489%)**.

Timedemo results and build evidence:

- Control: `out/dos-timedemo-20261028-140424/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261028-143226/timedemo-result.json`
- Candidate build and full audit: `out/local-local-alias-leftscan-candidate-20261028/`

## i486 audit

The complete candidate gate passed with zero above-i486, unknown, or exempt
instructions: 314,214 relocated instructions, 529 startup rows, and 9,207
DPMI-provider instructions. All 435 source-bound contributions mapped to the
linked code; there were no non-instruction bytes or relocation data sites in
audited code ranges.
