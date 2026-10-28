# Reject delaying the Span16 endpoint integer reloads (2026-10-22)

The assembly-only candidate delayed the `snext` and `tnext` reloads from
immediately after their `FISTP` stores until after the first texel fetch,
remaining-count update, and adjustment loads in `LNotLastSegment`. The endpoint
values and subsequent clamps were unchanged. Its strict three-run mean was
negative, so both reloads have been restored immediately after the `FISTP`s in
`src/d_draw16.s`.

Both variants used the uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI, and
the pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
control was the immediately preceding three-run block. Each run rendered 969
frames with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Candidate | 15.601304, 15.601302, 15.601274 | 15.601293333 | 0.000030 |

The candidate delta is **−0.000009667 FPS (−0.00006196%)**. Under the
any-positive pooled-mean rule, the negative mean rejects the schedule. No
separate trailing control was run.

The complete strict i486 audit passed: 313,376 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All six timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-202314/timedemo-result.json`
- Candidate build and ISA reports: `out/local-span16-fistp-interleave-independent-loads-20261022/`

Candidate fingerprints:

- Build source fingerprint: `FEEB023AF509992DFC87C2A5378DDFB3CA1CBDA58976BF44159D3F1640453C6F`
- Source-tree fingerprint: `DCB14F7F0EDD3A1E7D7F2B4B7B2CE9E79DD084D178B773101FA3E67D77F04416`
- Executable SHA-256: `98C0D9A8D67F5E7595E9E04735CEB996181C288F4B97463D1C5D4CF30CF9810D`
