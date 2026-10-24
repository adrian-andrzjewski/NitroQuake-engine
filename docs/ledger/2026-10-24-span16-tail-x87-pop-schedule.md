# Span16 tail x87 pop schedule promoted (2026-10-24)

Status: promoted after a strict three-run i486 improvement.

In `LLastSegment`, store the scaled S value with `fistpl snext` before
calculating scaled T. The S store pops the duplicated Z value, so the T
multiply can use `%st(2)` directly. This removes both `fxch` instructions from
the tail schedule while preserving the computed S and T steps.

The control and candidate used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. All
runs completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Median FPS |
| --- | --- | --- | ---: |
| Control | `7774C471DEFBABE7222F6D5D9F4579F00EC31603B7D4F434CA2B4B155E22EA23` | 15.880169 / 15.880175 / 15.880157 | 15.880169 |
| Tail S-pop schedule | `D19EC7C86748FCCB2CF075CDC2CF3CF74CB1E9B85BCD1E8F4D0A8169F9CC4ABE` | 15.900777 / 15.900727 / 15.900733 | 15.900733 |

The candidate improved the median by **+0.020564 FPS (+0.1295%)** against
control. All three candidate runs retained the expected frame count and
checksum.

## Validation

- Strict timedemo: PASS, three runs at 969 frames and checksum `1047377823`.
- Complete linked i486 ISA gate: PASS, 314,316 relocated instructions, 529
  startup code rows, and 9,207 provider instructions; zero above-i486, unknown,
  or exempt instructions.
- Candidate result: `out/dos-timedemo-20261024-162540/timedemo-result.json`.
- Candidate build and audit reports:
  `out/local-span16-tail-pop-s-compute-t-20261024/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName span16-tail-pop-s-compute-t-20261024 -NoBootstrap
```
