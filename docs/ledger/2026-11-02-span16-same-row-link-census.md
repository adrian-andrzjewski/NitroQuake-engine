# Span16 adjacent same-row link census (2026-11-02)

## Measurement

A `PROFILE486` counter in `D_DrawSpans16` counts a span descriptor when it has
a successor and both descriptors have the same `v`. The counter is active only
while frame profiling is enabled; the release build compiles it out.

Across three 969-frame `demo1` runs, each profile recorded **31,256** adjacent
same-row links out of **1,454,547** texture spans (**2.1488%**). All three runs
reported the same count. The counter can identify spans where the three
`dv * d_*stepv` products are reusable, but this workload exposes few such
links.

The profile build was produced by `build-dos.ps1 -Benchmark -Instrumentation
-CpuTarget i486 -NoBootstrap`. The complete linked i486 audit passed: 321,129
relocated instructions, 529 startup code rows, and 9,207 provider instructions;
no above-i486 or unknown instructions and no exemptions. The timedemo result
records source fingerprint
`39D4D1F1E2B6A0F7A6BBAC1D36B34D8679DF25B2AC1049BE8796B132EAA4C0B3` and the
pinned DOSBox-X 2026.08.31 profile hash
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Decision

Do not add a same-row reuse path. Even if all three vertical products were
skipped for every qualifying link, the maximum would be 93,768 avoided
multiplications across the timedemo. Detecting those links requires work on
every span, and preserving the x87 extended-precision values would require
additional storage or register pressure. The measurement does not justify a
candidate build or an FPS claim.

The qprof median of **9.880105 FPS** is instrumentation-heavy attribution data,
not timing evidence. The prior no-row-cross specialization also regressed, so
this does not reopen that path.

## Reproduction and checksum limits

```powershell
rtk proxy pwsh -NoProfile -File .\tools\build-dos.ps1 -Benchmark -Instrumentation -CpuTarget i486 -NoBootstrap
rtk proxy pwsh -NoProfile -File .\tools\timedemo-dos.ps1 -Instrumentation -CpuTarget i486 -SkipBuild -NoBootstrap -FrameChecksums -DataRoot .\out\dos-timedemo-20261102-173450\quake\id1
```

All three runs rendered 969 frames and ended at framebuffer checksum
`1047377823`. Runs 2 and 3 have identical frame-checksum files. Run 1 differs
from run 2 at frames 531, 532, 727, 728, 730, and 731. Therefore this profile
run does **not** establish exact cross-run frame-stream parity; it establishes
the stable span-link count and the expected final checksum only.

Artifacts: `out/profile-4dbf890a6daa3d54/` and
`out/dos-timedemo-20261102-195029/`.
