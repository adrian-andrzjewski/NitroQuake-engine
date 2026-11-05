# Whole-model alias tile occlusion promoted (2026-11-05)

## Candidate and profile

`R_AliasCheckBBox` already transforms, near-clips, and projects the alias
model's conservative bounding box. The projection helper now also records its
screen rectangle and maximum reciprocal depth during that existing pass. A
lazy 40-by-25 array caches the minimum 16-bit Z value for each 8-by-8 screen
tile. The values and per-tile epoch tags use about 6 KB; each tile is sampled
at most once per frame.

The candidate rejects a model only when every tile touched by its expanded
projected bounds has a cached minimum depth strictly greater than the model's
conservative nearest depth. It reuses depth written by the BSP and brush pass.
Later entity writes can only raise the depth value, so a cached minimum remains
a conservative lower bound. Tiles cut by the viewport edge, negative Z values,
debug polygon modes, and layouts other than 320-by-200 disable rejection.
The viewmodel does not use this entity-bounds path.

The final-source PROFILE486 replay counted 4,503 queries, 1,360 rejected
models, 12,797 tile checks, and 757,056 Z samples. Alias model draws fell from
5,470 to 4,111 for the fixed `demo1` replay.

## Output and i486 checks

The final-source instrumented fixed-step candidate at
`out/dos-timedemo-20261105-085345` matched control
`out/dos-timedemo-20261105-075327` across all 970 per-frame color checksums and
all 970 per-frame Z checksums. Both streams also contain the same completion
record. The color checksum file SHA-256 is
`3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B`; the Z
checksum file SHA-256 is
`1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8`. The
captured frame 482 PCX SHA-256 is
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`.

The final release build passed the complete strict i486 gate: 315,131
relocated application instructions, 529 startup code rows, and 9,207 DOS
provider instructions; zero above-i486, unknown, or exempt instructions. Each
release run rendered 969 frames and ended at framebuffer checksum
`1047377823`.

## Matched release timing

Both variants used DOSBox-X 2026.08.31, the pinned 320-by-200 `demo1` workload,
and the `cputype=486` profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
timing control was the clean source at commit `1ca2ef9`; neither variant used
per-frame FPS instrumentation.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.390080, 16.390140, 16.390120 | 16.390113333 |
| Tile occlusion | 16.659512, 16.659524, 16.659496 | 16.659510667 |

The candidate mean is **1.64366% faster**. The release artifacts are
`out/dos-timedemo-20261105-074940` (control) and
`out/dos-timedemo-20261105-090743` (candidate). This is DOSBox-X evidence, not
a claim about timing on physical 486 hardware.

Reproduce the strict release timing with:

```powershell
pwsh -NoProfile -File tools/timedemo-dos.ps1 -CpuTarget i486 -Runs 3 -NoBootstrap -NoFpsStats
```

The fixed-step profile replay used `-VisualParityOnly -Instrumentation`,
`-FrameChecksums -FrameCaptureIndex 482`, `-QuakeExtraArgs '-zchecksums'`, and
the autoexec commands `host_framerate 0.0783` and `con_notifytime -1`.

## 4-by-4 tile refinement

The follow-up changes `ALIAS_OCCLUSION_TILE_SHIFT` from 3 to 2. The lazy
hierarchy now covers 80 by 50 tiles instead of 40 by 25, increasing its
minimum-Z and epoch arrays from 6,000 to 24,000 bytes. The conservative
projected-bounds test and strict depth comparison are unchanged.

The fixed-step PROFILE486 replay at `out/dos-timedemo-20261105-092512`
recorded 4,503 queries, 1,627 rejected models, 36,940 tile checks, and
567,552 Z samples. Against the 8-by-8 profile, this rejected 267 more models
and sampled 189,504 fewer Z values, at the cost of 24,143 additional tile
checks. Instrumented timings are diagnostic only.

The candidate's 970 per-frame color and Z checksum rows matched control
`out/dos-timedemo-20261105-075327`, and both streams had the same completion
record. The color checksum SHA-256 is
`3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B`; the Z
checksum SHA-256 is
`1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8`. The
captured frame 482 PCX SHA-256 remains
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`.

The strict release build passed the complete i486 gate: 315,188 relocated
application instructions, 529 startup code rows, and 9,207 DOS provider
instructions, with zero above-i486, unknown, or exempt instructions. All
three release runs rendered 969 frames and ended at framebuffer checksum
`1047377823`.

The 4-by-4 candidate and 8-by-8 control used DOSBox-X 2026.08.31, the same
`demo1` workload, and the same pinned profile SHA-256 shown above. Neither
timing run used per-frame FPS instrumentation.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| 8-by-8 control | 16.659512, 16.659524, 16.659496 | 16.659510667 |
| 4-by-4 tiles | 16.750101, 16.750170, 16.750116 | 16.750129000 |

The 4-by-4 candidate mean is **0.543944% faster** than the 8-by-8 control.
The release artifacts are `out/dos-timedemo-20261105-090743` (8-by-8) and
`out/dos-timedemo-20261105-094109` (4-by-4). This remains DOSBox-X evidence,
not a physical 486 timing claim.

Reproduce the fixed-step profile replay with:

```powershell
pwsh -NoProfile -File tools/timedemo-dos.ps1 -VisualParityOnly -Instrumentation -CpuTarget i486 -Runs 1 -NoBootstrap -NoFpsStats -FrameChecksums -FrameCaptureIndex 482 -QuakeExtraArgs '-zchecksums' -AutoexecCommandsJson '["host_framerate 0.0783","con_notifytime -1"]'
```

## Tile-tag compaction

### Validity bitset rejected

A 500-byte validity bitset replaced the 16,000-byte 32-bit epoch array and was
cleared once per view change. It preserved the fixed-step color/Z checksum
streams and frame 482 PCX, and passed the strict i486 gate. However, its three
release samples averaged 16.736746 FPS, **0.079898% slower** than the matched
32-bit-epoch mean of 16.750129 FPS. The bitset candidate is not retained; its
profile and release artifacts are `out/dos-timedemo-20261105-095218` and
`out/dos-timedemo-20261105-100635`.

### 8-bit epochs promoted

The retained representation keeps the existing per-tile compare and replaces
each 32-bit epoch with an 8-bit epoch. For 4,000 tiles, the epoch tags shrink
from 16,000 to 4,000 bytes; with the unchanged 8,000-byte minimum-Z array, the
whole cache shrinks from 24,000 to 12,000 bytes. On epoch wrap, the code clears
the 4,000-byte tag array and restarts at epoch 1. The 969-frame fixed-step
replay crosses this wrap three times.

The PROFILE486 replay at `out/dos-timedemo-20261105-101311` retained the same
4,503 queries, 1,627 model rejections, 36,940 tile checks, and 567,552 Z
samples. All color/Z checksum records and the captured frame 482 PCX matched
control `out/dos-timedemo-20261105-075327` byte for byte.

The strict release build passed the complete i486 gate: 315,186 relocated
application instructions, 529 startup code rows, and 9,207 DOS provider
instructions, with zero above-i486, unknown, or exempt instructions. Each
release run rendered 969 frames and ended at framebuffer checksum
`1047377823`.

For an adjacent comparison, the 32-bit-epoch control executable was replayed
from `out/dos-timedemo-20261105-094109`; its SHA-256 matched the original build
record (`86F98456C6CCD37785455EB1748F093CBCF9C90D5D8EDF8DD691C9FA1F82615A`).
The control and 8-bit candidate used DOSBox-X 2026.08.31 and the same pinned
profile SHA-256 shown above. Their three-run means were:

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| 32-bit epochs, fresh control replay | 16.750099, 16.750109, 16.750117 | 16.750108333 |
| 8-bit epochs | 16.750405, 16.750456, 16.750440 | 16.750433667 |

The 8-bit-epoch candidate mean is **0.001942% faster** than this adjacent
control set. The control replay is in
`out/dos-timedemo-control-replay-20261105-1130`; the candidate release result
is `out/dos-timedemo-20261105-103741`. This small improvement and 12,000-byte
working-set reduction are DOSBox-X evidence, not physical 486 timing claims.
