# Span16 tfrac load between address store and cache-width add (2026-10-30)

Status: reverted after a negligible negative 320x200 mean.

## Candidate

In both `LZeroTSetup` and `LNonZeroSetup` in `src/renderer/d_draw16.s`, the candidate
moved `movl tfracf,%edx` between the `advancetable+4` store and the following
`cachewidth` add. The intent was to overlap the independent global load with
the address setup. No data or flag dependency required this ordering. The
previously retained order has been restored.

## Matched 320x200 timedemo

Both timed runs used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the aggressive i486 selector profile.

| Variant | Source-tree fingerprint | FPS samples | Mean FPS |
|---|---|---|---:|
| Retained control | `FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D` | 16.328477 / 16.328473 / 16.328474 | 16.328474667 |
| Candidate | `D3895ED6229B80172E186FC2FD9D92805D1E37BF05E7E18DD05C7AE819E57932` | 16.328472 / 16.328472 / 16.328472 | 16.328472000 |

The candidate was **0.000002667 FPS slower (-0.00001633%)**. All six runs
rendered 969 frames, ended at framebuffer checksum `1047377823`, and recorded
the same event traces. The non-positive mean rejects the schedule.

## Rendering and capture provenance

The first comparison used an older control capture with `quakeExtraArgs=-stdvid`
against candidate captures with no extra arguments; those captures are not a
matched pair. A fresh control and candidate run with the same arguments produced
pixel-identical 320x200 frame-169 PCX images (0 changed pixels of 64,000).

The per-frame checksum streams differed at 19 frames for a control/candidate
pair. Repeating the control capture alone differed at 18 frames while retaining
the same final checksum and event trace, so this timed capture path does not
isolate exact intermediate-frame parity. The saved frame-169 image is exact.

## Genuine-486 instruction gate

The candidate passed the complete linked i486 gate: 314,303 relocated
instructions, 529 startup instructions, and 9,207 CWSDPMI provider
instructions; zero above-i486, unknown, or exempt instructions.

Build root: `out/local-local-span16-tfrac-between-store-width-20261030`.
Candidate timing: `out/dos-timedemo-20261030-194009/timedemo-result.json`.
Control timing: `out/dos-timedemo-20261030-162411/timedemo-result.json`.
Candidate capture: `out/dos-timedemo-20261030-194350/runs/run-01/`.
Fresh control capture: `out/dos-timedemo-20261030-200044/runs/run-01/`.
