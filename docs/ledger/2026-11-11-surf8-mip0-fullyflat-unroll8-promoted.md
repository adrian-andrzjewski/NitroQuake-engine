# Mip-0 fully-flat surface rows unrolled eight at a time promoted (2026-11-11)

## Candidate

`LSurf8Mip0FullyFlat` now emits eight independently patchable row bodies per
loop pass and repeats the group twice for its 16 output rows. The prior body
decremented and branched once per row. Each emitted row owns 16 colormap patch
sites, so `LPatchTable8` now registers 128 fully-flat sites alongside the
existing 128 partially-flat sites. `R_Surf8Patch` adds 256 flat-path entries,
up from 144. Texture and destination row advancement remains in the original
order. No selector or runtime policy changed.

## Strict i486 gate

The Build 871 candidate passed the complete strict i486 audit. The linked
executable contains 316,728 relocated instructions, with 316,727 i386 and one
i486 instruction; there are zero above-i486, unknown, or exempted instructions.
The final-byte startup proof covered 529 instructions and the provider proof
covered 9,207 instructions, also with zero exemptions.

Candidate `qbench.exe` SHA-256:
`E063411D1F18CFBF23B75968BE34DCC3C841C4EC05D1B8E53DFF22EBBD55EC8F`.
The freshly rebuilt control passed the same gate with 316,434 relocated
instructions, 529 startup instructions, and 9,207 provider instructions, all
within i486 and with zero exemptions. Control `qbench.exe` SHA-256:
`027F65AE6CB31A41688AAAE80F85B3F0CDAA42CFA1614D69EE36048ED123463A`.

## Exact rendering parity

The canonical render-validation runs used DOSBox-X 2026.08.31, profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and
`workspace\quake\testdata\id1`. They enforced 969 demo1 frames
with framebuffer checksum `1047377823`, and 1,090 demo3 frames with checksum
`2316550348`.

Control and candidate canonical color streams matched exactly: all 971 demo1
records and all 1,092 demo3 records. Their frame-169 PCX captures were also
identical byte-for-byte. The demo1 PCX SHA-256 is
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`; demo3 is
`6A446E35A1A30487526B189C1750652BEFB9AF721DAFD798E4AD14F05FD713B0`.
Against the committed goldens, demo1 changed 12 pixels (mean channel error
`0.0009375`, within its established tolerance) and demo3 changed zero pixels.

The Z-enabled streams were compared against the promoted unroll8 parent using
the same `-zchecksums` and scene commands. All 971 demo1 and 1,092 demo3 records
matched exactly. The matching demo1 Z-stream SHA-256 is
`1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8`; demo3 is
`23CBA0BA44B9E609BD269F3ACC78C72CED609B4708E5C0565A2ACF3DF90DF83E`.

## Uninstrumented matched timing

Each sample used `timedemo-dos.ps1` without frame-checksum or profiler
instrumentation, the pinned profile and data above, identical renderer settings,
frame counts, and final framebuffer checksums. The first three samples per
variant ran as three-run batches; a fourth individually alternating confirmation
pair was added for each scene. Every candidate sample was faster than its paired
control.

| Scene | Sample | Control seconds / FPS | Candidate seconds / FPS | Candidate lead |
| --- | ---: | ---: | ---: | ---: |
| demo1 | 1 | 57.208950 / 16.937909 | 57.205091 / 16.939052 | 3.859 ms |
| demo1 | 2 | 57.208936 / 16.937914 | 57.205101 / 16.939049 | 3.835 ms |
| demo1 | 3 | 57.208936 / 16.937914 | 57.205098 / 16.939050 | 3.838 ms |
| demo1 | alternating confirmation | 57.208949 / 16.937909 | 57.205098 / 16.939050 | 3.851 ms |
| demo3 | 1 | 68.608968 / 15.887135 | 68.604124 / 15.888257 | 4.844 ms |
| demo3 | 2 | 69.072177 / 15.780595 | 68.604127 / 15.888257 | 468.050 ms |
| demo3 | 3 | 68.608966 / 15.887137 | 68.604127 / 15.888257 | 4.839 ms |
| demo3 | alternating confirmation | 68.608962 / 15.887137 | 68.604127 / 15.888257 | 4.835 ms |

Demo1 control samples ranged from 16.937909 to 16.937914 FPS; candidate samples
ranged from 16.939049 to 16.939052. Their means were 16.9379115 and 16.93905025
FPS (+0.00113875 FPS, +0.0067231%). Demo3 control samples ranged from 15.780595
to 15.887137 FPS; candidate samples were all 15.888257 FPS. Their means were
15.860501 and 15.888257 FPS (+0.027756 FPS, +0.1750008%). The 69.072177-second
demo3 control sample is retained; the other three controls took 68.608962 to
68.608968 seconds. The demo3 median speedup was +0.00706%, and every matched
sample still favored the candidate. Both scene means are positive under the
current acceptance rule. These are DOSBox-X results, not physical-486 claims.

## Artifacts and scope

- Candidate source worktree:
  `D:\NitroQuake-surf8-mip0-fullyflat-unroll8-20261111`
- Candidate and control strict build roots:
  `D:\NitroQuake-surf8-mip0-fullyflat-unroll8-20261111\out\profile-aeab673044e8f2ed`
  and
  `D:\NitroQuake-surf8-mip0-flat-unroll8-20261111\out\profile-aae1ea8ac1039d97`
- Canonical candidate render validation:
  `workspace\benchmarks\out\render-validation-surf8-fullyflat-unroll8-demo1-candidate-canonical-20261111\render-validation-result.json`
  and
  `workspace\benchmarks\out\render-validation-surf8-fullyflat-unroll8-demo3-retry1-20261111\render-validation-result.json`
- Canonical control render validation:
  `workspace\benchmarks\out\render-validation-surf8-fullyflat-unroll8-control-canonical-20261111\render-validation-result.json`
- Canonical color-stream and PCX captures are under timedemo runs
  `dos-timedemo-20261111-204308`, `204450`, `201242`, and `204618`.
- Z-stream comparisons use the promoted-parent control runs `175616` and
  `180221`, and candidate runs `202152` and `201809`.
- Uninstrumented timing JSON is under `dos-timedemo-20261111-205004`, `205336`,
  `205728`, `210133`, `210711`, `210827`, `210945`, and `211112`.
