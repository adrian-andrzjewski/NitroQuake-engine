# Brush splitter-plane cache generation tags rejected (2026-11-06)

## Candidate

The 256-entry brush splitter-plane cache currently keys each transformed plane
by its plane pointer, `currententity`, and `r_framecount`. This experiment
replaced the per-slot entity and frame fields with one generation tag. The
assembly `R_DrawSolidClippedSubmodelPolygons` entry advanced the generation
once per clipped model draw, so all surface and recursive clip calls in that
draw shared the same cache context. Generation wrap cleared the slot tags
before restarting at one.

The layout removed one 32-bit per-slot field and replaced the entity/frame
comparisons with one generation comparison. With 256 slots, the cache storage
fell from 7,168 to 6,148 bytes, including the global generation counter.

## Exact-output and i486 gates

The candidate and clean control used the pinned DOSBox-X 2026.08.31 i486
profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and `host_framerate 0.0783`. The instrumented replay recorded
970 framebuffer checksum rows and 970 Z-buffer checksum rows with no overflow.
Both streams matched byte for byte, as did the captured frame-482 PCX.

| Output | Candidate and control SHA-256 |
| --- | --- |
| Framebuffer checksum stream | `e00b1c297accfb4c161dbb8f2448cbaf48cfabccd3ac1da98ebc836515b8f8ca` |
| Z-buffer checksum stream | `1b41d2ab5b0fc99fcca5158c51e4d7b9028cbf4c3ec8dfdf32c6ab96c2db85e8` |
| Frame 482 PCX | `82abcb38389d68e1c5c96658b66680c3ab52d50755c384f85ad1df772d760c8d` |

The final framebuffer checksum was `1047377823`. The candidate passed the
complete strict i486 gate: 315,196 relocated instructions, 529 startup code
rows, and 9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions.

## Matched uninstrumented timing

Both variants used the same selector manifest, DOSBox-X profile, replay, and
969-frame checksum gate. These timing runs enabled neither per-frame checksum
nor FPS instrumentation.

| Variant | Result folder | FPS samples | Mean FPS |
| --- | --- | --- | ---: |
| 256-entry control | `out/dos-timedemo-20261106-013924` | 16.781146, 16.781151, 16.781151 | 16.781149333 |
| Generation-tag candidate | `out/dos-timedemo-20261106-085706` | 16.782197, 16.782198, 16.650086 | 16.738160333 |

The candidate mean was 0.042989 FPS (0.256%) lower. Its median was 0.001046
FPS (0.0062%) higher, a difference too small to separate from timing noise;
the third candidate run was substantially slower than its first two.

## Conclusion

Reject the generation-tag cache change. Exact output and i486 compatibility
passed, but the uninstrumented runs did not show a repeatable performance gain.
The candidate source was reverted. Benchmark reports and parity artifacts
remain under the ignored `out` directory.
