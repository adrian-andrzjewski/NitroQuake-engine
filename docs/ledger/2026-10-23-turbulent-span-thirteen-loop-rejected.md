# Reject the thirteen-pixel turbulent span loop (2026-10-23)

The candidate unrolled the turbulent span's pixel body thirteen times before
processing the remainder. It was compared with the checked-in fourteen-pixel
loop using three alternating, uninstrumented DOSBox-X `demo1` pairs. Both
variants used CWSDPMI, the full i486 selector profile, and the pinned 32 MB
profile `out/dosbox-x-486-high-32mb-profile.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).
All six runs used source-tree fingerprint
`FF59A02BA5258620E889DEB6497610DAD9A83837DFBA41ADADA1450ABF11B69A`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control (`fourteen`) | 15.607072, 15.607056, 15.607061 | 15.607063000 | 0.000016 |
| Candidate (`thirteen`) | 15.606227, 15.606229, 15.606205 | 15.606220333 | 0.000024 |

The candidate delta is **−0.000842667 FPS (−0.00539926%)**. Every candidate
sample was slower than every control sample, so the thirteen-pixel loop is
rejected and the fourteen-pixel implementation remains the i486 default. All
six runs rendered 969 frames and produced framebuffer checksum `1047377823`.
Each run passed the strict i486 ISA gate.

The control and candidate linked-object audits covered 313,933 and 313,916
instructions respectively, across 403 objects and 435 source-bound executable
ranges. Both startup audits covered 529 instructions, and both external
DPMI-provider audits covered 9,207 instructions; all had zero above-i486,
unknown, exempt, or unenforced instructions.

Artifacts:

- Control: `out/dos-timedemo-20261023-074629/timedemo-result.json`,
  `out/dos-timedemo-20261023-080929/timedemo-result.json`, and
  `out/dos-timedemo-20261023-081207/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261023-080810/timedemo-result.json`,
  `out/dos-timedemo-20261023-081048/timedemo-result.json`, and
  `out/dos-timedemo-20261023-081326/timedemo-result.json`
- Control build: `out/profile-9eea9650c5c9c4f1/`
- Candidate build: `out/profile-54a5aee2d19987ca/`
