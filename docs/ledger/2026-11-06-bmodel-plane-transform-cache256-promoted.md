# Brush-model splitter-plane cache expanded to 256 entries (2026-11-06)

## Candidate and profile

The accepted 128-entry direct-mapped transformed-plane cache hashes
`(plane_pointer >> 2) & 127`. Doubling the table to 256 entries and changing
the mask to 255 preserves the lookup and
replacement path while reducing collisions. The direct-map key remains the
exact plane pointer, current entity, and frame count.

Across 41,158 profile requests, the 128-entry table reported 27,843 hits and
13,315 misses. The 256-entry table reported 30,109 hits and 11,049 misses:
2,266 fewer transforms, a 17.02% reduction in misses, and a hit rate increase
from 67.65% to 73.16%. The table's BSS grows from 3,584 to 7,168 bytes.

## Exact-output and i486 gates

The fixed-step candidate at `out/dos-timedemo-20261106-012532` and the
128-entry control at `out/dos-timedemo-20261105-211219` used the pinned
DOSBox-X 2026.08.31 `cputype=486` profile, `demo1`, `host_framerate 0.0783`,
and per-frame color and Z checksums. All 970 checksum records match
byte-for-byte. The color stream has SHA-256
`934c3df21f9e2aa11d402f28643ec4ba9331d52450d984fa5a131dcd78737962`; the Z
stream has SHA-256
`1b41d2ab5b0fc99fcca5158c51e4d7b9028cbf4c3ec8dfdf32c6ab96c2db85e8`. The
captured frame 482 PCX files also match, with SHA-256
`82abcb38389d68e1c5c96658b66680c3ab52d50755c384f85ad1df772d760c8d`. The
final framebuffer checksum was `1047377823`.

The complete strict release i486 audit passed with 315,186 relocated
instructions, 529 startup code rows, and 9,207 provider instructions. There
were zero above-i486, unknown, exempt, or unclassified instructions.

## Matched uninstrumented timing

The release A/B used DOSBox-X 2026.08.31, the same pinned i486 profile
(SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and 969 frames. Both builds used the same selectors,
`host_framerate 0.0783`, and data root. Every run passed the expected final
framebuffer checksum. The 128-entry baseline was built from the same renderer
source contents in a clean detached worktree.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| 128 entries | `out/worktree-bmodel-victim4-control-20261106/out/dos-timedemo-20261105-231254` | 16.780320, 16.780321, 16.780326 | 16.780322333 |
| 256 entries | `out/dos-timedemo-20261106-013924` | 16.781146, 16.781151, 16.781151 | 16.781149333 |

All three 256-entry samples were faster. The mean improved by 0.000827 FPS,
or **0.004928%**.

## Conclusion

Retain the 256-entry direct-mapped table. It avoids 2,266 transforms in the
profile, preserves exact color and Z output, passes the strict i486 audit,
and improves all three matched uninstrumented samples. The additional 3,584
bytes of BSS are retained for this measured DOSBox-X workload; physical
486-cache behavior remains unmeasured.
