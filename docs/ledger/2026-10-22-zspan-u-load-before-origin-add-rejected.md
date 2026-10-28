# Reject moving the Z-span U load before the origin add (2026-10-22)

The assembly-only candidate moved `movl espan_t_u(%ebp),%edx` from after
`fadds C(d_ziorigin)` to just before it, after the x87 `fxch`. The independent
integer load was intended to overlap the origin addition. The strict candidate
had a negative three-run mean, so the load was restored after the add in
`src/d_draw.s`.

Both variants used the uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI, and
the pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
control was the immediately preceding three-run block. Each run rendered 969
frames with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Candidate | 15.601311, 15.601280, 15.601283 | 15.601291333 | 0.000031 |

The candidate delta is **−0.000011667 FPS (−0.00007478%)**. Under the
any-positive pooled-mean rule, the negative mean rejects the schedule. No
separate trailing control was run.

The complete strict i486 audit passed: 313,376 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All six timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-194837/timedemo-result.json`
- Candidate build and ISA reports: `out/local-zspan-u-load-before-origin-add-20261022/`

Candidate fingerprints:

- Build source fingerprint: `5B6F177A27B05C26F12F2B17779312FDE151E79D70FD13EEE0736F0737447A23`
- Source-tree fingerprint: `6057324007A55692B5DB4AD9B5D6DCDF486BA7A08C86CFC299CABE6525F3F84A`
- Executable SHA-256: `B3FD93D7697518C0FF3EFEDB07C17055726A3107E656354935E6825D1D794107`
