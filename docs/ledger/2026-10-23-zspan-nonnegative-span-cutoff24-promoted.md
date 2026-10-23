# D_DrawZSpans nonnegative span cutoff

Status: promoted after a positive three-run mean, exact framebuffer parity, and
the complete strict i486 gate.

## Measurement

The paired `demo1` timedemos used DOSBox-X 2026.08.31 and the pinned 32 MB i486
profile `out/dosbox-x-486-high-32mb-profile.conf` with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Control | `D95CCDF22EEB2DFB477D2A45DA1758566A055BFC549105C61DB86D86FCEA56E4` | 15.790356, 15.790362, 15.790361 | 15.790359667 | 0.000006 |
| Candidate | `7BE17091D3C94029FAABA5B110526EF5FE6B4C6BA1819DEA41DFA8549EA22ABD` | 15.803280, 15.803272, 15.803277 | 15.803276333 | 0.000008 |

Gain: `+0.012916666 FPS` (`+0.081801%`). The candidate median was 15.803277
FPS.

- Control result: `out/dos-timedemo-20261023-212323/timedemo-result.json`
- Candidate result: `out/dos-timedemo-20261023-215042/timedemo-result.json`
- Strict candidate build: `out/local-zspan-nonnegative-cutoff24-20261023/`

## Change

The nonnegative endpoint fast path now skips its multiply and endpoint checks
for spans shorter than 24 pixels. Those spans continue through the existing
sign-aware loop. Longer spans still use the exact signed 64-bit endpoint check
and branch-free packed-pair loop added in the previous promotion.

## Validation

- Candidate timedemo parity: PASS, three runs at 969 frames and checksum
  `1047377823` each.
- Strict i486 audit: PASS; 275,727 build instructions and 314,024 linked
  instructions verified across 435 executable ranges; zero above-i486, unknown,
  or exempt instructions.
- Startup and DPMI provider proof: PASS; 529 startup code rows and 9,207
  provider instructions, with zero exemptions.
- Final source mapping: PASS; 2,375 CODE and 35 DATA ranges.
- The pinned profile hash matched for control and candidate.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-nonnegative-cutoff24-20261023
```
