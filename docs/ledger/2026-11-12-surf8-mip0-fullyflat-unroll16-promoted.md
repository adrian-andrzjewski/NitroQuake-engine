# Mip-0 fully-flat surface rows unrolled sixteen at a time promoted (2026-11-12)

## Candidate

`LSurf8Mip0FullyFlat` now emits sixteen distinct row bodies in sequence. This
removes the `%dl` loop counter and the conditional loop branch from the
two-pass eight-row path. Source and destination row pointers advance after each
row, including row `p`, so the common `LSurfaceBlockMip0Done` path receives the
same final state. The candidate adds 128 independently patchable colormap
sites; `R_Surf8Patch` now registers 384 flat-path entries rather than 256. No
renderer selector or runtime policy changed.

## Strict i486 gate

The Build 873 benchmark executable passed the complete source-bound i486 gate:
317,060 linked instructions (317,059 i386 and one i486), 403 exact object
proofs, 435 mapped source contributions, 529 startup rows, and 9,207 provider
instructions. There were zero above-i486, unknown, or exempt instructions.
Candidate `qbench.exe` SHA-256:
`2C2AE0E023EDE86A5728A4940127C902B560A5BB70DEA86F545C1FFF84442DE8`.

The separate Build 873 release executable also passed the complete strict
gate: 164,646 linked instructions (164,645 i386 and one i486), 403 exact object
proofs, 422 mapped source contributions, 529 startup rows, and 9,207 provider
instructions. It had zero above-i486, unknown, or exempt instructions.
Release `quake.exe` SHA-256:
`50413D0B8A4401351BD0F3D80CC1EE0B6AA48F467F9F9B8DF0F8A5621FF0DA9D`.

## Exact rendering parity

The control and candidate used DOSBox-X 2026.08.31, profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, the
same `demo1` workload, VGA mode, `host_framerate 0.0783`, and the pinned
`id1` data. Each replay enforced 969 frames and framebuffer checksum
`1047377823`.

Both color and Z logs contained 970 records and matched exactly over all 964
records after the six-frame warm-up. The captured 320x200 frame 169 PCX had the
same palette and zero changed pixels. Candidate capture SHA-256:
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`.

## Uninstrumented matched timing

Three `demo1` runs per variant used `-stdvid`, the same pinned profile and
data, 969 frames, and the expected framebuffer checksum. Frame-checksum, Z,
and profiler instrumentation were disabled for timing.

| Sample | Control seconds / FPS | Candidate seconds / FPS |
|---:|---:|---:|
| 1 | 57.160831 / 16.952168 | 57.160176 / 16.952362 |
| 2 | 57.160806 / 16.952176 | 57.160150 / 16.952370 |
| 3 | 57.160815 / 16.952172 | 57.160160 / 16.952367 |

The control mean was **16.952172 FPS**; the candidate mean was
**16.952366333 FPS**, a gain of **0.000194333 FPS (+0.00114636%)**. Every
candidate sample exceeded every control sample. This small result meets the
current positive-mean rule and applies only to the pinned DOSBox-X workload; it
does not establish performance on physical 486 hardware.

## Artifacts and scope

- Candidate source worktree:
  `D:\NitroQuake-surf8-mip0-fullyflat-unroll16-20261111`
- Candidate benchmark build:
  `out/local-surf8-mip0-flat16-20261112`
- Candidate release build:
  `out/local-surf8-mip0-flat16-release-20261112`
- Candidate parity replay:
  `workspace\benchmarks\out\dos-timedemo-20261112-000628`
- Candidate uninstrumented timing:
  `workspace\benchmarks\out\dos-timedemo-20261112-000903`
- Control uninstrumented timing:
  `workspace\benchmarks\out\dos-timedemo-20261111-223711`
