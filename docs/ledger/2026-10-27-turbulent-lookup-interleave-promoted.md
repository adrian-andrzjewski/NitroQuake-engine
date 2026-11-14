# Interleave turbulent span sine-table lookups — promoted

## Change

`TURBULENT8_PIXEL` in `src/renderer/d_scana.s` now derives the `%ecx` table index and
starts that sine-table load before deriving the independent `%esi` index. The
reordering leaves both indices, table reads, arithmetic, stores, and the
instruction count unchanged. It places several integer operations between the
first lookup load and its use on the i486 pipeline.

## Matched timedemo

Control and candidate used three uninstrumented `demo1` runs, DOSBox-X
2026.08.31, the pinned 32 MB i486 profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, matching
aggressive i486 selectors, 969 frames, and framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean FPS | Median FPS |
|---|---|---:|---:|
| Control | 16.194893, 16.194905, 16.194909 | 16.194902333 | 16.194905 |
| Candidate | 16.194900, 16.194901, 16.194919 | 16.194906667 | 16.194901 |

The mean increased by **0.000004333 FPS (+0.0000268%)**. The sample ranges
(16.194893–16.194909 and 16.194900–16.194919) overlap, and the candidate median
is below the control median. The gain is therefore smaller than the observed
run-to-run spread. It qualifies under the current acceptance rule, which
promotes any positive mean from at least three matched runs, but should be
regarded as a fragile, very small result.

Every run retained 969 frames and checksum `1047377823`. Result files:
`out/dos-timedemo-20261027-105618/timedemo-result.json` (control) and
`out/dos-timedemo-20261027-120306/timedemo-result.json` (candidate).

## i486 audit

The source-bound linked i486 audit passed: 314,276 relocated instructions,
529 startup instructions, and 9,207 instructions in the verified CWSDPMI
provider, with zero instruction exemptions. The candidate build and timedemo
source-tree fingerprints match.
