# Brush-model splitter-plane transform cache expanded to 128 entries (2026-11-05)

## Candidate and profile

The accepted 64-entry direct-mapped cache keys each transformed BSP splitter
plane by plane pointer, current-entity pointer, and frame count. Increasing the
capacity to 128 changes the hash mask from `(plane_pointer >> 2) & 63` to
`(plane_pointer >> 2) & 127`; collisions remain safe misses, and the four
cached binary32 values are unchanged.

Across 41,158 profile requests, the 64-entry table produced 27,372 hits and
13,786 misses. The 128-entry table produced 27,843 hits and 13,315 misses:
471 additional transforms reused, raising the hit rate from 66.50% to 67.65%.
The table's BSS grows from 1,792 to 3,584 bytes.

## Exact-output and i486 gates

The fixed-step candidate at `out/dos-timedemo-20261105-211219` and 64-entry
control at `out/dos-timedemo-20261105-192525` used the pinned DOSBox-X
2026.08.31 `cputype=486` profile, `demo1`, `host_framerate 0.0783`, and
per-frame color and Z checksums. All 970 checksum records match byte-for-byte;
the files have SHA-256
`934C3DF21F9E2AA11D402F28643EC4BA9331D52450D984FA5A131DCD78737962`. The
captured frame 482 PCX files also match, with SHA-256
`82ABCB38389D68E1C5C96658B66680C3AB52D50755C384F85AD1DF772D760C8D`. The
final framebuffer checksum was `1047377823`.

The strict release i486 audit passed with 315,186 relocated application
instructions, 529 startup code rows, and 9,207 DOS provider instructions. It
reported zero above-i486, unknown, exempt, or unclassified instructions.

## Matched uninstrumented timing

The release A/B used DOSBox-X 2026.08.31, the same pinned i486 profile
(SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and 969 frames. Every run passed the expected final
framebuffer checksum. The qbench binaries were uninstrumented and built with
the same selectors; only cache capacity and index mask differed.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| 64 entries | `out/dos-timedemo-20261105-205536` | 16.750620, 16.750612, 16.750605 | 16.750612333 |
| 128 entries | `out/dos-timedemo-20261105-212659` | 16.750743, 16.750758, 16.750744 | 16.750748333 |

All three candidate samples were faster. The mean improved by 0.000136 FPS, or
**0.000812%**.

## Conclusion

Retain the 128-entry table. It reuses 471 additional transformed planes per
profile, preserves exact color and Z output, passes the strict i486 audit, and
improves all three matched uninstrumented samples. The additional 1,792 bytes
of BSS remain a small footprint for the target.
