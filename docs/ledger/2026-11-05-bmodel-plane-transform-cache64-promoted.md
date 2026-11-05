# Brush-model splitter-plane transform cache expanded to 64 entries (2026-11-05)

## Candidate and profile

The accepted brush-model splitter-plane transform cache was direct-mapped with
32 entries. The profile showed 26,704 hits and 14,454 misses across 41,158
requests (64.88%). Increasing the table to 64 entries changes the index mask
from `(plane_pointer >> 2) & 31` to `(plane_pointer >> 2) & 63`; the cache key
remains the plane pointer, current-entity pointer, and frame count. Collisions
remain safe misses. The four cached binary32 values are unchanged.

In the corrected 64-entry profile, hits increased to 27,372 and misses fell to
13,786: 668 additional transforms reused, and a 66.50% hit rate. The BSS table
grew from 896 to 1,792 bytes. An earlier incorrectly targeted mask edit did not
change the cache index and is excluded from all measurements below.

## Exact-output and i486 gates

The fixed-step 32-entry control at `out/dos-timedemo-20261105-181936` and the
64-entry candidate at `out/dos-timedemo-20261105-192525` used DOSBox-X 2026.08.31,
the pinned `cputype=486` profile, `demo1`, `host_framerate 0.0783`, and
per-frame color and Z checksums. Both produced 970 records. Their color files
have the same SHA-256
`934C3DF21F9E2AA11D402F28643EC4BA9331D52450D984FA5A131DCD78737962`, and their
Z files have the same SHA-256
`1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8`. The final
framebuffer checksum was `1047377823`.

The strict release i486 audit passed with 315,186 relocated application
instructions, 529 startup code rows, and 9,207 DOS provider instructions. It
reported zero above-i486, unknown, exempt, or unclassified instructions.

## Matched uninstrumented timing

Both variants used DOSBox-X 2026.08.31, the same pinned i486 profile
(SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and 969 frames. Each run passed the expected final framebuffer
checksum. The qbench binaries were uninstrumented and built with the same
selectors; only the cache capacity and index mask differed.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| 32 entries | 16.750401, 16.750451, 16.750444 | 16.750432000 |
| 64 entries | 16.750602, 16.750605, 16.750617 | 16.750608000 |

All three candidate samples were faster. The pooled mean improved by 0.000176
FPS, or **0.001051%**. This small positive result meets the current promotion
rule. The result artifacts are `out/dos-timedemo-20261105-193940` (64 entries)
and `out/dos-timedemo-20261105-195500` (32 entries).

## Conclusion

Retain the 64-entry table. It removes 668 repeated plane transforms from the
pinned profile, preserves exact color and Z output, passes the strict i486
audit, and improves the matched three-run mean. The additional 896 bytes of
BSS remain modest for the target.
