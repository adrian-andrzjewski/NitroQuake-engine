# Brush-model splitter-plane cross-frame reuse rejected (2026-11-05)

## Candidate and profile

The per-frame plane cache discards transformed splitter planes at the next
render frame. The prototype retained entries across frames while an entity's
translation and 3-by-3 rotation matrix remained bit-identical. A 32-slot
direct-mapped transform-state table stored those 12 exact float words and a
generation tag; map changes and generation wrap invalidated the cache.

In the pinned profile, cross-frame reuse increased hits from 27,372 to 28,389
and reduced misses from 13,786 to 12,769 across 41,158 requests. The prototype
avoided 1,017 additional transforms, but required transform-state lookups,
exact comparisons, and another 1,792 bytes of BSS.

## Exact-output and i486 gates

The fixed-step candidate at `out/dos-timedemo-20261105-202613` and per-frame
control at `out/dos-timedemo-20261105-192525` used the pinned DOSBox-X
2026.08.31 `cputype=486` profile, `demo1`, `host_framerate 0.0783`, and
per-frame color and Z checksums. All 970 checksum records match byte-for-byte;
the files have SHA-256
`934C3DF21F9E2AA11D402F28643EC4BA9331D52450D984FA5A131DCD78737962`. The
captured frame 482 PCX files also match, with SHA-256
`82ABCB38389D68E1C5C96658B66680C3AB52D50755C384F85AD1DF772D760C8D`. The
final framebuffer checksum was `1047377823`.

The strict release i486 audit passed with 315,399 relocated application
instructions, 529 startup code rows, and 9,207 DOS provider instructions. It
reported zero above-i486, unknown, exempt, or unclassified instructions.

## Matched uninstrumented timing

The release A/B used DOSBox-X 2026.08.31, the same pinned i486 profile
(SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and 969 frames. Every run passed the expected final
framebuffer checksum. The qbench binaries were uninstrumented and built with
the same selectors; only transform-cache lifetime differed.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| Per-frame | `out/dos-timedemo-20261105-205536` | 16.750620, 16.750612, 16.750605 | 16.750612333 |
| Cross-frame | `out/dos-timedemo-20261105-204051` | 16.747138, 16.747202, 16.747199 | 16.747179667 |

All candidate samples were slower. The mean fell by 0.003432667 FPS, or
**0.020493%**.

## Disposition

The cross-frame path was removed. Its extra state lookup and transform
comparisons cost more than the additional cache hits saved. Retain the
per-frame entity-and-frame key; the ignored profile, parity, build, and timing
artifacts remain under the `out` folders listed above.
