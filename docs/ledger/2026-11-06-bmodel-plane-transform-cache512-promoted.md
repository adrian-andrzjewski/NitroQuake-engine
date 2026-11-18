# Brush-model splitter-plane cache expanded to 512 entries (2026-11-06)

## Candidate and profile

The direct-mapped transformed splitter-plane cache grows from 256 to 512
entries. Its key remains the exact splitter-plane pointer, current entity, and
frame count; only the slot mask changes from 255 to 511. The lookup and
replacement path add no extra probes or comparisons.

Across 41,158 profile requests, the 256-entry table recorded 30,109 hits and
11,049 misses. The 512-entry table recorded 31,160 hits and 9,998 misses,
recovering 1,051 transforms and reducing misses by 9.512%. The hit rate rose
from 73.15% to 75.71%. The four arrays grow from 7,168 to 14,336 BSS bytes.

## Exact output and strict i486 audit

The fixed-step profile runs at `out/dos-timedemo-20261106-123714` (256 entries)
and `out/dos-timedemo-20261106-124105` (512 entries) match byte-for-byte for
all 969 color and Z checksum rows and the captured frame 482 PCX. The hashes
are:

| Output | SHA-256 |
| --- | --- |
| Color checksum stream | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

The release checks at `out/dos-timedemo-20261106-125806` and
`out/dos-timedemo-20261106-131242` also match for every color and Z checksum
row and the captured PCX. Both rendered 969 timed frames and ended at
framebuffer checksum `1047377823`.

The 512-entry release passed the complete strict i486 gate: 315,256 relocated
instructions across 435 linked CODE ranges, 529 startup code rows, and 9,207
DPMI-provider instructions. There were zero above-i486, unknown, exempt,
undecoded, or non-instruction bytes. All 403 source proofs matched exactly.

## Matched uninstrumented timing

The control is the clean 256-entry renderer at commit `8a5dfe9f809c`; the candidate
changes only the cache entry count and mask. Both used DOSBox-X 2026.08.31,
`cputype=486`, the 320-by-200 `demo1` workload, and the pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Neither
set used frame-FPS instrumentation, and all six runs rendered 969 frames and
passed the final framebuffer checksum gate.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| 256 entries | 16.755717, 16.755701, 16.755703 | 16.755707000 |
| 512 entries | 16.756108, 16.756083, 16.756078 | 16.756089667 |

The 512-entry mean is **0.0022838% faster**. Each candidate sample exceeded
every control sample; the smallest gap was 0.000361 FPS. Timing artifacts are
in `out/dos-timedemo-20261106-123318` and
`out/dos-timedemo-20261106-131526`. This is DOSBox-X evidence; physical 486
cache behavior remains unmeasured.

## Conclusion

Retain the 512-entry direct map for this workload. It removes 1,051 more
transforms than the 256-entry version without adding lookup work, keeps exact
color, Z, and PCX output, passes the strict i486 audit, and improves all three
matched uninstrumented FPS samples. Its additional 7,168 BSS bytes are an
explicit memory cost; no claim is made that this larger table is faster on
physical 486 hardware.
