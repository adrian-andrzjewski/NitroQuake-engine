# Span16 deferred `tfracf` reload scheduling (2026-10-21)

Status: promoted in `src/renderer/d_draw16.s` under the positive pooled-mean rule.

In both zero and nonzero T-step setup arms, the `tfracf` reload now follows the
`advancetable+4` store and the independent cachewidth addition. The address
arithmetic and subsequent fractional state are unchanged.

The uninstrumented comparisons used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and
the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every run
completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Matched control | `out/dos-timedemo-20261021-095134`, `095624`, `100055` | 15.537284 / 15.537299 / 15.537289 | 15.537290667 | 0.000015 |
| Deferred-reload parity screen | `out/dos-timedemo-20261021-100813/timedemo-result.json` | 15.537289 / 15.537300 / 15.537305 | 15.537298000 | 0.000016 |
| Strict candidate | `out/dos-timedemo-20261021-103344/timedemo-result.json` | 15.537290 / 15.537300 / 15.537308 | 15.537299333 | 0.000018 |

The strict pooled mean improved by **+0.000008667 FPS (+0.00005580%)** over
control. The gain is smaller than the observed spread but positive, so it
qualifies under the no-floor rule. All strict runs enforced exact
frame/checksum parity and report `isaAuditStatus=PASS`.

The complete linked i486 audit verified 313,315 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 provider instructions. It
found zero above-i486, unknown, or exempt instructions. The audited build is in
`out/local-span16-tfracf-reload-deferred-strict-20261021-1012/`.
