# Span16 tail `tfracf` reload schedule rejected (2026-10-24)

Status: reverted after the strict three-run mean was lower than control.

The experiment moved the `tfracf` load in `LSetEntryvec` after the independent
`advancetable` and `tstep` stores. The DDA arithmetic and tail dispatch were
unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Control | `7BE17091D3C94029FAABA5B110526EF5FE6B4C6BA1819DEA41DFA8549EA22ABD` | 15.803280 / 15.803272 / 15.803277 | 15.803276333 | 0.000008 |
| Deferred tail reload | `F55267084877FCA20487E1EDEC98171B531ED44327D6AE9F55ED530B3FE16E05` | 15.803265 / 15.803275 / 15.803273 | 15.803271000 | 0.000010 |

The candidate mean was **−0.000005333 FPS (−0.00003374%)** against control.
Exact parity held, but the negative strict mean rejects the schedule and the
original load order is restored.

## Validation

- Strict timedemo: PASS, three runs at 969 frames and checksum `1047377823`.
- Complete linked i486 audit: PASS, 314,024 relocated instructions, 529
  startup code rows, and 9,207 provider instructions; zero above-i486,
  unknown, or exempt instructions.
- Candidate result: `out/dos-timedemo-20261023-224329/timedemo-result.json`.
- Candidate build and audit reports:
  `out/local-span16-tail-tfrac-deferred-20261024/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName span16-tail-tfrac-deferred-20261024
```
