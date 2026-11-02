# 320x200 framebuffer page-offset pad promoted (2026-10-30)

## Candidate

The pinned 320x200 layout placed `vid_surfcache` and `lvid->buffer` at the same
4 KB page offset: the Z buffer occupies 128,000 bytes (offset 1,024), and the
1,800 KB surface cache preserves that offset. `tools/486-cost-model.ps1`
identified this as a possible 486 cache conflict for the texture-read and
framebuffer-write streams. The model is a ranking aid; DOSBox-X does not model
this mechanism, and no physical 486 measurement is available.

`VGA_FreeAndAllocVidbuffer` now reserves 16 extra bytes for a single-buffer
320x200 mode and starts the RAM framebuffer 16 bytes later. This changes its
page offset from 1,024 to 1,040 while retaining 16-byte alignment. The
allocation-size and available-memory checks include the padding. Other sizes
and modes keep their previous layout.

## Measurement and disposition

The strict comparison used DOSBox-X 2026.08.31, `cputype=486`, the pinned
`tools/dosbox-x-486-high.conf` profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, `-stdvid`, and 969 frames at 320x200.

| Variant | FPS samples | Spread | Mean FPS | Framebuffer checksum |
|---|---|---:|---:|---:|
| Control | 16.329108 / 16.329125 / 16.329110 | 0.000017 | 16.329114333 | `1047377823` |
| 16-byte page-offset pad | 16.329115 / 16.329125 / 16.329114 | 0.000011 | 16.329118000 | `1047377823` |

The pooled delta is **+0.000003667 FPS (+0.00002246%)**, below both sample
spreads. The current promotion rule accepts any positive matched three-run
mean, so the change is retained. Its tiny DOSBox delta does not measure the
predicted 486 cache-conflict benefit; that remains unverified on physical
hardware.

All candidate runs rendered 969 frames with exact checksum parity. The complete
i486 gates passed: 314,329 linked-object instructions, 314,329 linked
executable instructions, 529 startup-code rows, and 9,207 provider
instructions; zero above-i486, unknown, or exempt instructions. Source proof
covered 168 native objects and runtime-source proof covered 235 installed
objects.

Artifacts:

- Control: `out/dos-timedemo-20261029-224006/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261029-232707/timedemo-result.json`
- Candidate ISA report: `out/profile-107ff6406936b458/isa-qbench/isa-audit-linked.json`

### Reassessment (2026-11-02)

The tiny positive mean was accepted under the then-current any-positive rule,
but it is below both sample spreads and is not repeatable evidence of a DOSBox
speedup. The Intel486 write-through/no-allocation policy also means the
set-color explanation applies only when the affected destination lines are
already resident; it does not describe a cold streaming-write conflict. See
[`2026-10-30-vga-cache-set-model-correction.md`](2026-10-30-vga-cache-set-model-correction.md)
for the allocator-address and physical-cache caveats. Keep this result as a
historical layout experiment, not as a verified performance win. No genuine
486 timing was available for either disposition.

The current combined renderer was rechecked with the same pinned DOSBox-X
profile on 2026-11-02, three uninstrumented runs per layout:

| Layout | FPS samples | Spread | Mean FPS | Final checksum |
|---|---|---:|---:|---:|
| No pad | 16.346963 / 16.346953 / 16.346945 | 0.000018 | 16.346953667 | `1047377823` |
| 16-byte pad | 16.346944 / 16.346952 / 16.346944 | 0.000008 | 16.346946667 | `1047377823` |

The pad delta is **-0.000007000 FPS (-0.0000428%)**, smaller than either
sample spread. All six runs rendered 969 frames and produced the same final
checksum and timedemo event streams. Both builds passed the complete i486 ISA
gate (314,326 and 314,349 linked instructions, respectively; zero above-486,
unknown, or exempt instructions). This reverses the sign of the earlier tiny
positive mean and confirms that the DOSBox result is flat. The profile hash was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` for both
layouts. These timings still say nothing about physical 486 cache behavior.

Artifacts for the current recheck (preserved under ignored `out/`):

- No-pad timedemo: `out/dos-timedemo-20261102-084901/timedemo-result.json`
- 16-byte-pad timedemo: `out/dos-timedemo-20261102-090605/timedemo-result.json`
