# Reject the fifteen-pixel turbulent span loop (2026-10-23)

The candidate unrolled the turbulent span's pixel body fifteen times before
processing the remainder. It was compared with the checked-in fourteen-pixel
loop using three alternating, uninstrumented DOSBox-X `demo1` pairs. Both
variants used CWSDPMI, the full i486 selector profile, and the pinned 32 MB
profile `out/dosbox-x-486-high-32mb-profile.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).
All six runs used source-tree fingerprint
`9DEEC84D9AD632E1E94150AE8007BA52E15E958C525C6C8DB6AC21560CA315AB`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control (`fourteen`) | 15.607052, 15.607060, 15.607060 | 15.607057333 | 0.000008 |
| Candidate (`fifteen`) | 15.606322, 15.606317, 15.606323 | 15.606320667 | 0.000006 |

The candidate delta is **−0.000736667 FPS (−0.00472009%)**. Every candidate
sample was slower than every control sample, so the fifteen-pixel loop is
rejected and the fourteen-pixel implementation remains the i486 default. All
six runs rendered 969 frames and produced framebuffer checksum `1047377823`.
Each run passed the strict i486 ISA gate.

The control and candidate linked-object audits covered 313,933 and 313,950
instructions respectively, across 403 objects and 435 source-bound executable
ranges. Both startup audits covered 529 instructions, and both external
DPMI-provider audits covered 9,207 instructions; all had zero above-i486,
unknown, exempt, or unenforced instructions.

Artifacts:

- Control: `out/dos-timedemo-20261023-065639/timedemo-result.json`,
  `out/dos-timedemo-20261023-071816/timedemo-result.json`, and
  `out/dos-timedemo-20261023-072054/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261023-071654/timedemo-result.json`,
  `out/dos-timedemo-20261023-071936/timedemo-result.json`, and
  `out/dos-timedemo-20261023-072214/timedemo-result.json`
- Control build: `out/profile-9eea9650c5c9c4f1/`
- Candidate build: `out/profile-c7e9db70a6425c52/`
