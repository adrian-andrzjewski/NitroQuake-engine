# Alias-raster depth-store schedule promoted (2026-10-21)

Status: promoted in `src/d_polysa.s` under the positive-mean performance rule.
The assembly moves each passing pixel's Z-buffer word store until after its
colormap lookup and before the framebuffer pixel store. The self-modifying
colormap patch labels remain directly after their lookup instructions.

The comparison used the pinned DOSBox-X 2026.08.31 32 MB i486 profile, `demo1`,
CWSDPMI, and the same `qbench.exe` control settings. Runs alternated in three
control/candidate pairs in the last successful pinned staging root:

| Variant | FPS samples | Mean |
|---|---|---:|
| Control | 15.537290 / 15.537288 / 15.537290 | 15.537289333 FPS |
| Candidate | 15.537304 / 15.537295 / 15.537305 | 15.537301333 FPS |

The pooled delta is **+0.000012 FPS (+0.0000772%)**. Each candidate sample beat
its paired control. All six runs completed 969 frames and produced framebuffer
checksum `1047377823`. Per-run reports and the A/B summary are in
`out/alias-raster-experiment-20261021/`.

The source tree fingerprint is
`CEF6953D5359DCEDEE2FF87A97A0991DA82575B669246097E49184C08BC015F3`. The strict
candidate executable is `out/profile-c86686d2e5e2448c/qbench.exe`, SHA-256
`25BB3DF5D080EFC5403007C9E4F3E637598718A72252C9F0C08447A40545F906`. The
complete linked i486 audit passed: 313,316 instructions verified across 435
executable ranges, with zero above-i486, unknown, or exempt instructions. The
final source mapping covered 2,377 CODE ranges and 35 DATA ranges; the startup
proof covered 1,660 loaded bytes and 529 code rows; the exact CWSDPMI provider
passed its 9,207-instruction audit with zero exemptions.

The timedemo runner's fresh staging attempt exited before rendering because
Quake received only 5,419,300 bytes. The exact strict candidate binary then ran
in the preserved pinned root and passed runtime parity at **15.537300 FPS**, 969
frames, checksum `1047377823`. The original root executable was restored after
the A/B and runtime checks.
