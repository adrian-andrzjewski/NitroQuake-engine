# 8-bit sound mixer four-sample loop promoted (2026-11-13)

## Change

`SND_PaintChannelFrom8` now handles four samples per loop iteration instead of
two, reducing loop-branch frequency by half. The existing two-sample body is
also retained for the even remainder after the optional odd-sample prelude.
Scale-table lookups, sample order within each pair, accumulator additions, and
the final `channel_t::pos` update are unchanged.

## Mixer output parity

A temporary DJGPP DOS fixture linked the actual candidate `snd_mixa.obj` and
compared the complete 512-pair paint buffer and final channel position against
the original per-sample mixing equation. All **4,096 cases passed**: each count
from 1 through 512, eight deterministic sample/volume patterns per count,
including odd counts, two-sample tails, four-sample blocks, and volumes above
255. The fixture exercised the pinned DOSBox-X i486 profile.

## Gameplay output parity

Control and candidate used DOSBox-X 2026.08.31, `cputype=486`, FPU 387,
fixed 33,445 cycles, VGA 320x200, and the same staged game data. Each local-map
capture ran 64 warm-up frames followed by 256 measured frames with a fixed
0.0625-second simulation step, god mode, forward movement, firing, and sound on.
The sound device initialized at 11,025 Hz, stereo, 16-bit.

Every control and candidate capture had identical final simulation and
framebuffer checksums:

| Map | Simulation checksum | Framebuffer checksum |
| --- | ---: | ---: |
| e1m1 | 2568184557 | 1299435123 |
| e1m2 | 1496920581 | 1246513233 |

These are selected final-state checks, complemented by the direct mixer-buffer
fixture; they are not a full per-frame audio recording.

## Matched timing

Three uninstrumented pairs per map alternated control/candidate,
candidate/control, and control/candidate. Profiling was disabled during timing.

| Map / pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| e1m1 / 1 | 11.017132 / 23.236537 | 11.015287 / 23.240430 |
| e1m1 / 2 | 11.017130 / 23.236543 | 11.015287 / 23.240428 |
| e1m1 / 3 | 11.017128 / 23.236546 | 11.015303 / 23.240397 |
| e1m2 / 1 | 11.985844 / 21.358529 | 11.980966 / 21.367225 |
| e1m2 / 2 | 11.985846 / 21.358525 | 11.980981 / 21.367199 |
| e1m2 / 3 | 11.985856 / 21.358508 | 11.980961 / 21.367234 |

Pooled results (768 measured frames per variant and map):

| Workload | Control FPS | Candidate FPS | Change |
| --- | ---: | ---: | ---: |
| e1m1, sound on | 23.236541640 | 23.240418162 | +0.016683% |
| e1m2, sound on | 21.358520962 | 21.367219369 | +0.040726% |
| Both maps pooled | 22.257986995 | 22.264488351 | +0.029209% |

Every candidate capture beat its matched control. This is a small DOSBox-X
gain, not a physical-486 performance claim.

## Strict i486 gates

The final release and qbench builds passed their complete linked i486 audits:
165,087 and 317,515 relocated instructions, respectively. Both audits checked
529 startup instruction rows and 9,207 maintained DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. The mixer object is byte
identical in the timed qbench, final qbench, and release builds. Executable
hashes and source-bound audit reports are retained in the build manifests below.

## Artifacts

- Timed gameplay JSONs and reports: `benchmarks/out/audio-mix-unroll4-ab-20261113/`
- Mixer parity fixture result: `benchmarks/out/audio-mix-unroll4-parity-stage-20261113/quake/MIXER.TXT`
- Timed qbench binary (Build 883): `quake/out/local-audio-mix-unroll4-20261113/qbench.exe`
  (SHA-256 `DE798A500ED50723C7EAC108D40BAC93D37D2178ED315DC7405762E25ED66149`)
- Final Build 884 release: `quake/out/local-audio-mix-unroll4-release-verified-20261113/quake.exe`
- Release manifest and ISA proof: `quake/out/local-audio-mix-unroll4-release-verified-20261113/build-manifest.json`
- Final Build 884 qbench: `quake/out/local-audio-mix-unroll4-verified-20261113/qbench.exe`
- qbench manifest and ISA proof: `quake/out/local-audio-mix-unroll4-verified-20261113/build-manifest-bench.json`
