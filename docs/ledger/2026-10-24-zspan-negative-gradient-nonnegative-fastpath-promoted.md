# D_DrawZSpans negative-gradient nonnegative fast path (2026-10-24)

Status: promoted for the i486 path after a positive strict three-run mean. The
i386 path retains its existing branch-tested loop.

For negative `d_zistepu`, spans of at least 22 pixels now use a guarded fast
path when both the initial depth and the computed final depth are nonnegative
32-bit values. The endpoint uses a signed 64-bit product; because the fixed
step is linear, both endpoints prove that every intermediate depth remains in
range. The fast path handles an alignment pixel, then processes 16-pixel
groups and grouped tails without the per-pair sign tests. If the span is short,
or the endpoint proof fails, execution returns to the existing general loop.
The i386 path is unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the aggressive i486
selector profile, `testdata/id1`, and the pinned 32 MB DOSBox-X profile with
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run times (s) | Reported run FPS | Mean FPS from recorded times | Frames/checksum |
|---|---|---|---|---:|---|
| Control, prior negative-gradient loop | `out/dos-timedemo-20261024-084705/timedemo-result.json` | 61.232830 / 61.232859 / 61.232847 | 15.824844 / 15.824836 / 15.824840 | 15.824840324259 | 969 / `1047377823` every run |
| Candidate, guarded 16-pixel groups | `out/dos-timedemo-20261024-092021/timedemo-result.json` | 61.232817 / 61.232836 / 61.232879 | 15.824847 / 15.824842 / 15.824831 | 15.824840668844 | 969 / `1047377823` every run |

The candidate mean increased by **0.000000344585 FPS (+0.000002177%)**. Each
reported run rate is rounded to six decimal places, so the displayed FPS means
tie at 15.824840; the positive delta comes from recomputing each rate from the
recorded microsecond-resolution run time. The gain is below the observed run
spread and is recorded under the current any-positive-mean policy.

The complete strict i486 gate passed: 314,310 linked instructions across 435
executable ranges, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. Control source fingerprint:
`78287F38119693CB33FD155B7EFBA57447AEB765A5986EEA41858C919BBD5EB9`; tree
fingerprint: `92BDA5833ED6C5BF52131ED42A4E97D289AECDEF0C57F0B83AFB65F1B3CEC3E4`.
Candidate source fingerprint:
`88A9BA4FDE62E3660531B6F7549A11AC3EA210B456ACC75D98F3403CA68AC0A1`; tree
fingerprint: `D48FBEDCA82AF79C8F33B32A0EA67BD15B8F74FE56BF8D73D5CF3C28C6D8AEB5`.

- Candidate strict build and audit reports:
  `out/local-zspan-negative-gradient-nonnegative-fastpath-20261024/`.
- Pinned profile SHA-256:
  `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

Reproduction command:

```powershell
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -CpuTarget i486 -OptimizationProfile aggressive -DemoName demo1 -Runs 3 -NoFpsStats -DosboxProfilePath .\out\dosbox-x-486-high-32mb-profile.conf -ExpectedProfileSha256 532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA -LocalOutputDirectoryName zspan-negative-gradient-nonnegative-fastpath-20261024 -NoBootstrap
```
