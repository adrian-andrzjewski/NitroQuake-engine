# Mip-0 fully-flat source row-stride hoist (2026-11-11)

Status: rejected after three matched uninstrumented runs produced a negative
mean. The original memory-source row advances remain in `src/renderer/surf8.s`.

## Experiment

The candidate loaded `sourcetstep` into `%ebp` at `LSurf8Mip0FullyFlat` entry
and changed the eight row advances in the repeated eight-row body from
`addl C(sourcetstep),%esi` to `addl %ebp,%esi`. The profile recorded 4,753
fully-flat mip-0 blocks in `demo1`, so this tested removing seven repeated
memory-source reads per eight-row group after its initial load.

Both variants used DOSBox-X 2026.08.31, the pinned profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
i486/CWSDPMI, `demo1` in VGA mode (`-stdvid`), `host_framerate 0.0783`, and
three uninstrumented runs. Each run completed 969 frames with framebuffer
checksum `1047377823`.

| Variant | Artifact | Run times (s) | Reported FPS | Mean FPS |
|---|---|---|---|---:|
| Control, memory-source row advances | `out/dos-timedemo-20261111-223711/timedemo-result.json` | 57.160831 / 57.160806 / 57.160815 | 16.952168 / 16.952176 / 16.952172 | 16.952172000 |
| Candidate, `%ebp` row stride | `out/dos-timedemo-20261111-224045/timedemo-result.json` | 57.160960 / 57.160960 / 57.160956 | 16.952129 / 16.952129 / 16.952130 | 16.952129333 |

The candidate mean decreased by **0.000042667 FPS (−0.0002517%)**, so it fails
the positive-mean promotion rule. Both sets used the same expected frame count,
checksum, profile hash, and DOSBox-X version; frame checksum and Z checksum
capture were disabled during timing.

Rendering parity passed before timing. In a matching captured VGA replay, the
parent and candidate had exact per-frame color checksums after the first six
warmup records (964 compared records, zero mismatches), exact Z checksum
records (970 records, zero mismatches), and an identical 320x200 frame-169
PCX (zero changed pixels, matching palette). The candidate also passed the
complete strict i486 executable gate: 316,728 linked instructions, 529 startup
rows, and 9,207 provider instructions, with zero above-i486, unknown, or
exempted instructions. Its linked map had 435 source-bound contributions.

Candidate source-tree fingerprint:
`D390374E0DC7E7B85EF375CD1281D2754C5CA69990661F7154FD4F7BFA0E79F4`.
Control source-tree fingerprint:
`ACCD80D9E8555D9570F7E86281B59B5D0AAADE6C13100DC1AFAE11352018F5AB`.

The candidate source edit was restored. Benchmark runs, captures, and audit
reports remain under `benchmarks/out/` for review.
