# Reject the sixteen-pixel turbulent span loop (2026-10-23)

The candidate unrolled the turbulent span's pixel body sixteen times before
processing the remainder. It was compared with the checked-in eight-pixel
(`octa`) loop using three alternating, uninstrumented DOSBox-X `demo1` pairs.
Both variants used CWSDPMI, the full i486 selector profile, and the pinned 32 MB
profile `out/dosbox-x-486-high-32mb-profile.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

All six runs rendered 969 frames and produced framebuffer checksum
`1047377823`. The source-tree fingerprint was
`B720651E940BC8251C172AFFE7FB0372F33E62975044A2502AB39B4A8251C466` for every
run.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control (`octa`) | 15.606222, 15.606212, 15.606211 | 15.606215 | 0.000011 |
| Candidate (`sixteen`) | 15.605629, 15.605622, 15.605647 | 15.605632667 | 0.000025 |

The candidate delta is **−0.000582333 FPS (−0.00373%)**. Every candidate run
was slower than every control run, so the sixteen-pixel loop is rejected and
the `octa` implementation remains the default. The candidate added 702 linked
instructions over the control.

Both strict i486 build audits passed. The control audit covered 313,623 linked
instructions and the candidate covered 314,325, each across 403 objects and
435 source-bound contributions. Each audit also recorded 529 startup rows and
9,207 external DPMI-provider instructions, with zero above-i486, unknown,
exempt, or unenforced instructions.

Artifacts:

- Control: `out/dos-timedemo-20261023-032340/timedemo-result.json`, `out/dos-timedemo-20261023-032617/timedemo-result.json`, `out/dos-timedemo-20261023-032853/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261023-032458/timedemo-result.json`, `out/dos-timedemo-20261023-032734/timedemo-result.json`, `out/dos-timedemo-20261023-033011/timedemo-result.json`
- Control build and ISA reports: `out/profile-4c7cfb0c1bb71b71/`
- Candidate build and ISA reports: `out/profile-4cd0e6c09d9b06ca/`
