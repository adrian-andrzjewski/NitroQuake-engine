# Surface-cache hit load-gap schedule rejected (2026-10-21)

Status: rejected because the three-run mean tied the matched control mean.

The candidate loaded the `surface` argument into `%edx` between loading the
first light-style key and comparing that key with the cached value. The intent
was to overlap an independent stack load with the cache-key load. The change
was confined to `D_CacheSurfaceHit_asm486` in `src/asm486_experiments.s` and has
been removed.

The matched strict runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the
uninstrumented runner, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Each run
completed 969 frames with checksum `1047377823`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Control | `out/dos-timedemo-20261021-033929/timedemo-result.json` | 15.537289 / 15.537296 / 15.537289 | 15.537291333 | 0.000007 |
| Load-gap schedule | `out/dos-timedemo-20261021-040645/timedemo-result.json` | 15.537290 / 15.537291 / 15.537293 | 15.537291333 | 0.000003 |

Both builds passed the complete i486 ISA gate. The pooled mean delta was zero,
so this schedule was not promoted. A follow-up that retains the light-style
pointer and removes a later stack reload is recorded separately in
[`2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md`](2026-10-21-surface-cache-hit-key-pointer-retained-promoted.md).
