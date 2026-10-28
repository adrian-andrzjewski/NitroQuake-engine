# Span16 `advancetable` store after T-step shift promoted (2026-10-21)

Status: promoted in `src/d_draw16.s` under the positive pooled-mean rule. This
schedule supersedes the earlier placement before the T-step shift.

`LSetUpCommon` now schedules the independent base-address store after both
fractional shifts:

```asm
shll    $12,%ebp             // left-justify sstep fractional part
movl    sfracf,%ebx
shll    $12,%ecx             // left-justify tstep fractional part
movl    %eax,advancetable    // advance extra in t
```

The store value and fixed-point arithmetic are unchanged. The comparison used
DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486 profile with
SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. All runs
completed 969 frames with framebuffer checksum `1047377823`; per-frame FPS
collection was disabled.

## Strict matched timing

The baseline is the same previously audited executable, measured in two blocks
on the same profile. The candidate is the strict audited build.

| Variant | Artifacts | Run FPS | Pooled mean | Spread |
|---|---|---|---:|---:|
| Strict control, 6 runs | `out/dos-timedemo-20261021-103344`, `out/dos-timedemo-20261021-114754` | 15.537290 / 15.537300 / 15.537308 / 15.537290 / 15.537301 / 15.537283 | 15.537295333 | 0.000025 |
| Strict candidate, 3 runs | `out/dos-timedemo-20261021-114126` | 15.537299 / 15.537293 / 15.537299 | 15.537297000 | 0.000006 |

The strict candidate pooled mean is **+0.000001667 FPS (+0.00001072%)** above
the six-run control mean. The difference is below the observed spread but
positive, so it qualifies. Every control and candidate run retained exact
frame/checksum parity.

## Parity screen

An independent three-run `VisualParityOnly` screen also had a positive pooled
mean. Those runs skipped the ISA audit and are listed only as the screen; the
strict results above are the promotion evidence.

| Variant | Artifacts | Run FPS | Mean | Spread |
|---|---|---|---:|---:|
| Screen control | `out/dos-timedemo-20261021-110942`, `out/dos-timedemo-20261021-111647` | 15.537302 / 15.537288 / 15.537290 | 15.537293333 | 0.000014 |
| Screen candidate | `out/dos-timedemo-20261021-111154`, `out/dos-timedemo-20261021-111318` | 15.537301 / 15.537287 / 15.537293 | 15.537293667 | 0.000014 |

The parity-screen delta was **+0.000000333 FPS (+0.00000214%)**. All six
screen runs also completed 969 frames with checksum `1047377823`.

## Strict i486 audit

The strict build passed the complete audit. It verified 403 linked objects and
313,315 instructions across 435 executable ranges, with zero above-i486,
unknown, or exempt instructions. Final mapping covered 2,377 CODE ranges and
35 DATA ranges. Startup proof covered 1,660 loaded bytes and 529 code rows; the
CWSDPMI provider audit verified 9,207 instructions with zero exemptions.
Project source proof passed for 168 objects. The audited executable is
`out/profile-c86686d2e5e2448c/qbench.exe`; its timedemo result is
`out/dos-timedemo-20261021-114126/timedemo-result.json`.
