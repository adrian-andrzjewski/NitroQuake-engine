# 320x200 non-bmodel edge-sort 10-vs-12 unroll recheck rejected

## Rejected result

The non-bmodel surface-stack search was screened with a ten-comparison
back-edge body against the current twelve-comparison worktree control. The
candidate kept comparison order and exit branches unchanged. It removed the
last two comparisons, their `PROFILE486` increments, and their optional probe
blocks from the unrolled body.

The five matched 320x200 DOSBox-X runs averaged **16.3217204 FPS** for the
10-way candidate and **16.3217212 FPS** for the 12-way control. The candidate
delta was **-0.0000008 FPS (-0.00000490%)**. Paired differences ranged from
-0.000030 to +0.000024 FPS, so the result is noise-level and non-positive.
All ten runs rendered 969 frames and ended with framebuffer checksum
`1047377823`. No 640x480 run was made.

| Pair | 10-way candidate | 12-way control | Candidate delta |
| --- | --- | --- | ---: |
| 1 | `002628`: 16.321745 FPS | `004326`: 16.321721 FPS | +0.000024 |
| 2 | `004603`: 16.321702 FPS | `004724`: 16.321706 FPS | -0.000004 |
| 3 | `004845`: 16.321711 FPS | `005004`: 16.321741 FPS | -0.000030 |
| 4 | `005124`: 16.321724 FPS | `005243`: 16.321719 FPS | +0.000005 |
| 5 | `005406`: 16.321720 FPS | `005525`: 16.321719 FPS | +0.000001 |

The 12-way control remains in the worktree. The 10-way candidate is rejected;
its renderer ISA audit was skipped after the non-positive mean, so it is not a
promotion candidate.

### Reproducibility

- Workload: `demo1`, 969 frames, 320x200, DOSBox-X `2026.08.31`, pinned profile
  `tools/dosbox-x-486-high.conf`, SHA-256
  `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
- Candidate build: `out/visual-parity-profile-107ff6406936b458`; all five runs
  used source fingerprint
  `533532A2158190624E88AF29AE19FB10D4A89E9BA891E5F019FAEA46AC0BC953` and
  `VisualParityOnly=true` (`isaAuditStatus=SKIPPED`).
- Control build: `out/local-edge-sort-12-control-reaudit-20261030`; all five
  runs used source fingerprint
  `1EAC1185DB47D679F38ADCE820619F3EF677FED3A9EB22D41C6AEE4825F3D6CD`.
  Its strict gate passed for 314,332 linked instructions, 529 startup rows,
  and 9,207 provider instructions, with zero above-i486 instructions and zero
  exemptions.
- Timedemo artifacts are under `out/dos-timedemo-20261030-<stamp>/` using the
  pair identifiers in the table. Candidate runs used
  `-VisualParityOnly -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats`; control runs
  used `-SkipBuild -NoBootstrap -LocalOutputDirectoryName
  edge-sort-12-control-reaudit-20261030 -Runs 1 -NoFpsStats`.
