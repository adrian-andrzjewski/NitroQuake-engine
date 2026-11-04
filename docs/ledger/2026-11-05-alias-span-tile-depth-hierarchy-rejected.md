# Lazy tile-min hierarchy for alias-span occlusion rejected (2026-11-05)

Status: rejected. The profile candidate eliminated too little work to pay for
its query path, and exact per-frame color and Z parity was not demonstrated.

## Candidate

The prototype added a lazy, horizontal screen-tile minimum-depth cache over the
existing Z buffer. It queried long alias spans after world and brush rendering,
and rejected a span only when every touched tile's cached minimum Z was
strictly greater than the span's maximum candidate integer depth. It added no
second BSP or PVS visibility pass. Eight-pixel and four-pixel tile widths were
profiled; the four-pixel layout doubled tile-cache storage to about 48 KiB from
24 KiB.

The helper ran only for spans at least 16 pixels wide. Profile counters reused
the `alias-span-package` record: `work_items` counted eligible queries and
`work_bytes` counted rejected spans (it did not count bytes). The first trial
had an assembly calling-convention bug that clobbered the span length and
produced a wrong final checksum. The helper was corrected to preserve EAX, and
its initialization was moved to the first alias-span query because the active
frame loop bypassed the C frame-begin hook.

## Diagnostic results

Both candidates used `timedemo-dos.ps1` with `-VisualParityOnly
-Instrumentation -NoBootstrap -CpuTarget i486 -Runs 1 -FrameChecksums` and
`-QuakeExtraArgs '-zchecksums'`. These are single-run instrumented profiles, not
release timing or full i486 qualification runs.

| Layout | Eligible span queries | Rejected spans | Rejection rate | Final color checksum | Final Z checksum | Instrumented alias-span self time |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Disabled helper, `out/dos-timedemo-20261104-224740` | — | — | — | `1047377823` | `981012801` | ~3.36 s |
| 8x1, `out/dos-timedemo-20261104-225613` | 39,990 | 103 | 0.26% | `1047377823` | `981012801` | ~3.54 s |
| 4x1, `out/dos-timedemo-20261104-230118` | 39,990 | 140 | 0.35% | `1047377823` | `981012801` | ~3.58 s |

Relative to the disabled-helper profile, each active profile had one differing
per-frame color checksum and one differing per-frame Z checksum, both at frame
83. Matching final checksums do not establish pixel-exact replay parity. The
profile self times are instrumented diagnostics and are not an FPS A/B; they
also show no indication that the helper saved time. The 4x1 layout rejected
only 37 more spans than 8x1 while using about twice the cache storage.

## Disposition and evidence

The candidate was removed. Its query rate was at most 0.35%, its helper added
work to every eligible span, and the per-frame stream differed from the
disabled-helper profile. No uninstrumented timing A/B or release ISA audit was
run after that result. The timedemo profiles remain under the ignored `out`
paths named above, along with the earlier failed calling-convention trial
`out/dos-timedemo-20261104-223852`. The scratch builds remain in
`out/local-hzb-screen-tiles`, `out/local-hzb-screen-tiles-fix1`, and
`out/visual-parity-profile-e4825a3e97882413`.
