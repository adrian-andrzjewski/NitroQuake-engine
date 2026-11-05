# Brush-clip previous-edge endpoint-distance cache rejected (2026-11-05)

Status: rejected. The candidate preserved the tested color and Z output and
passed the complete strict i486 audit, but its three-run uninstrumented mean
was 0.1145% slower than the matched control.

## Candidate

`R_RecursiveClipBPoly` computes the transformed splitter-plane distance for
both vertices of each brush edge. The control profile found that 105,123 of
340,532 endpoint checks (30.9%) referenced one of the previous edge's two
vertices. The prototype kept those previous vertex pointers and their exact
binary32 distances in the recursion frame, then forwarded a distance when the
next edge reused a vertex. A miss used the original x87 calculation. This
avoided recomputation without changing clipping order or plane arithmetic, but
added pointer comparisons, branches, and 16 bytes to each active recursion
frame.

## Results

The release A/B used the pinned DOSBox-X 2026.08.31 profile
(`dosbox-x-486-high.conf`, SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), the
969-frame `demo1` workload, and identical i486 build settings. Every run ended
at framebuffer checksum `1047377823`.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| Control | `out/dos-timedemo-20261105-065049` | 16.390228, 16.390248, 16.390239 | 16.390238333 |
| Endpoint-distance forwarding | `out/dos-timedemo-20261105-070933` | 16.371471, 16.371472, 16.371485 | 16.371476000 |

The candidate lost 0.018762333 FPS (-0.1145%). A separate fixed-step run,
`out/dos-timedemo-20261105-071314`, matched control
`out/dos-timedemo-20261105-065538` byte-for-byte across all 970 framebuffer
checksum records, all 970 Z-checksum records, and the captured frame 482 PCX.
The complete strict i486 audit passed: 314,699 relocated executable
instructions, 529 DOS startup code rows, and 9,207 provider instructions, with
zero instructions above i486 and zero exemptions.

## Disposition and evidence

The endpoint-distance cache was removed. Its extra tests and stack traffic
cost more than the repeated x87 distance calculations saved in this workload.
The control, candidate, parity captures, and build/audit evidence remain under
the ignored `out` directory paths listed above.
