# Reject moving the first Span16 texel load into x87 endpoint math (2026-10-22)

The assembly-only candidate moved `movb (%esi),%bl` from after the endpoint
calculations to between the first endpoint `fmul` and `fxch` in
`LNotLastSegment`. The candidate retained exact output, but its three-run mean
was below control. The load has been restored to its original position in
`src/d_draw16.s`.

Both variants used the same uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI,
and pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
control was the immediately preceding three-run block. Each variant rendered
969 frames with framebuffer checksum `1047377823` on every run.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Candidate | 15.601295, 15.601301, 15.601298 | 15.601298 | 0.000006 |

The candidate delta is **−0.000005 FPS (−0.00003205%)**. Under the
any-positive pooled-mean rule, this negative mean rejects the change. No
separate trailing control was run.

The complete strict i486 audit passed: 313,376 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All six timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-191558/timedemo-result.json`
- Candidate build and ISA reports: `out/local-span16-first-texel-x87-overlap-20261022/`

Candidate fingerprints:

- Build source fingerprint: `7403651B382F9C306AE861B913031114CC346FDB0957DB0FBC079E0BC3B1D592`
- Source-tree fingerprint: `10BAC249137170ADA6FA6117257A1580EE9093DE7BB34C9CF072E7B47BA29DF0`
- Executable SHA-256: `BD70DCA6B37F923065B94C710C221D156166DA17C9DC2E76ACEC990C0ADDBF21`
