# Reject moving the Span16 count update into x87 endpoint math (2026-10-22)

The assembly-only candidate moved `subl $16,%ecx` and `movl %ecx,counttemp`
from after the first source texel load to between the first endpoint `fmul` and
`fxch` in `LNotLastSegment`. The candidate retained exact output, but its
three-run mean was lower than control. The original count-update placement has
been restored in `src/renderer/d_draw16.s`.

Both variants used the same uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI,
and pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
control was the immediately preceding three-run block. Each variant rendered
969 frames with framebuffer checksum `1047377823` on every run.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Candidate | 15.601281, 15.601276, 15.601287 | 15.601281333 | 0.000011 |

The candidate delta is **−0.000021667 FPS (−0.00013888%)**. Under the
any-positive pooled-mean rule, this negative mean rejects the change. No
separate trailing control was run.

The complete strict i486 audit passed: 313,376 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All six timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-181021/timedemo-result.json`
- Candidate build and ISA reports: `out/local-span16-counttemp-x87-overlap-20261022/`

Candidate fingerprints:

- Build source fingerprint: `C44002C4EF9BF67F7435C7318D24DCEEF531E74A0F557A564F30DAF986684BA2`
- Source-tree fingerprint: `282CD55782779263B4BACC9BF32A0BA6ECBDA97D3009F35D765D005D2AB215F7`
- Executable SHA-256: `4FF90BA1A23B0FAB0B9CF80348ED1C8AA6A6AE1216A255BB1CB7A6E3768AA4C4`
