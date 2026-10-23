# D_DrawZSpans nonnegative span fast path

Status: promoted after a positive three-run mean, exact framebuffer parity, and
the complete strict i486 gate.

## Measurement

The paired `demo1` timedemos used DOSBox-X 2026.08.31 and the pinned 32 MB i486
profile `out/dosbox-x-486-high-32mb-profile.conf` with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Variant | Source tree fingerprint | Run FPS | Mean FPS | Spread |
| --- | --- | --- | ---: | ---: |
| Control | `B2278EDD8CF908A54273F056F817BF2AE11888BFC3461AAB792888CF2ED4BE8C` | 15.750052, 15.750072, 15.750062 | 15.750062000 | 0.000020 |
| Candidate | `D95CCDF22EEB2DFB477D2A45DA1758566A055BFC549105C61DB86D86FCEA56E4` | 15.790356, 15.790362, 15.790361 | 15.790359667 | 0.000006 |

Gain: `+0.040297667 FPS` (`+0.255857%`). The candidate median was 15.790361
FPS.

- Control result: `out/dos-timedemo-20261023-201441/timedemo-result.json`
- Candidate result: `out/dos-timedemo-20261023-212323/timedemo-result.json`
- Strict candidate build: `out/local-zspan-nonnegative-fast-20261023/`

## Change

On the i486 `LZDraw` path, the span setup now checks that the starting depth is
nonnegative and computes the final depth using a signed 64-bit product. If the
final value is also within the nonnegative signed 32-bit range, every
fixed-step sample in the span is nonnegative. The span uses a packed-pair loop
that omits the repeated per-pair sign branches. If either endpoint falls
outside that range, the existing sign-aware loop handles the whole span. The
i386 fallback is unchanged.

## Validation

- Candidate timedemo parity: PASS, three runs at 969 frames and checksum
  `1047377823` each.
- Strict i486 audit: PASS; 275,730 build instructions and 314,027 linked
  instructions verified across 435 executable ranges; zero above-i486, unknown,
  or exempt instructions.
- Startup and DPMI provider proof: PASS; 529 startup code rows and 9,207
  provider instructions, with zero exemptions.
- Final source mapping: PASS; 2,375 CODE and 35 DATA ranges.
- The pinned profile hash matched for control and candidate.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-nonnegative-fast-20261023
```
