# Span16 tail cache-width load hoist rejected (2026-10-24)

Status: reverted after a negative three-run parity screen.

The experiment moved the independent `cachewidth` load ahead of both shifts in
`LSetEntryvec`, giving the load more instructions to overlap before the
multiply. The arithmetic and tail dispatch were unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Control | `7BE17091D3C94029FAABA5B110526EF5FE6B4C6BA1819DEA41DFA8549EA22ABD` | 15.803280 / 15.803272 / 15.803277 | 15.803276333 | 0.000008 |
| Cache-width hoist | `22422512447078D6BEDFD35A5C334B2065B37D24A454E1B97656C63D41AA0B32` | 15.803272 / 15.803275 / 15.803275 | 15.803274000 | 0.000003 |

The screen delta was **−0.000002333 FPS (−0.00001476%)**. Exact parity held,
but the negative mean rejects the schedule and the original load order is
restored. The visual-parity-only build skipped the renderer ISA audit; a full
strict audit was not warranted for this negative screen.

- Candidate result: `out/dos-timedemo-20261023-225259/timedemo-result.json`.
- Screen build: `out/visual-parity-profile-9eea9650c5c9c4f1/`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -VisualParityOnly
```
