# Span16 advancetable store scheduling (2026-10-21)

Status: originally promoted under the positive pooled-mean rule; superseded in
`src/d_draw16.s` by
[`2026-10-21-span16-store-after-tstep-shift-promoted.md`](2026-10-21-span16-store-after-tstep-shift-promoted.md).

In the measured revision of `LSetUpCommon`, the store to `advancetable`
followed the `sfracf` reload and preceded the T-step fractional shift. The
store was independent of both fractional shifts, and its value and the
subsequent address arithmetic were unchanged.

The uninstrumented comparisons used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and
the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every run
completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Fresh control | `out/dos-timedemo-20261021-090128/timedemo-result.json` | 15.537282 / 15.537292 / 15.537297 | 15.537290333 | 0.000015 |
| Early-store parity screen | `out/dos-timedemo-20261021-091053/timedemo-result.json` | 15.537295 / 15.537290 / 15.537304 | 15.537296333 | 0.000014 |
| Strict candidate | `out/dos-timedemo-20261021-093858/timedemo-result.json` | 15.537288 / 15.537302 / 15.537292 | 15.537294000 | 0.000014 |

The strict pooled mean improved by **+0.000003667 FPS (+0.00002360%)** over
control. The gain is smaller than the run spread but positive, so it qualifies
under the no-floor rule. The strict result enforced exact frame/checksum parity
and reports `isaAuditStatus=PASS`. Its source fingerprint is
`010545C4F1A5D3592F51D99EE2EEE46C3C991AD88D05F0C8C0C36D4267D7AF1C`.

The complete linked i486 audit verified 313,315 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions.
It found zero above-i486, unknown, non-instruction, or exempted bytes. The
audited build is in `out/local-span16-advancetable-store-hoist-20261021/`.
