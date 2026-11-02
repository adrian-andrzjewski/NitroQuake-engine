# Alias span triangle-constant setup (2026-11-01)

Status: the triangle-constant setup hoist remains promoted after three uninstrumented 320x200 screens (15 runs), exact fixed-clock frame parity, identical full per-frame checksum streams, and the strict i486 audit. The 2026-11-02 register-entry follow-up is recorded separately in `2026-11-02-alias-span-register-entry-promoted.md`.

## Change and correctness

The alias rasterizer entered `D_PolysetDrawSpans8` 153,852 times for 124,771 triangles in the instrumented profile. The extra 29,081 entries repeated triangle-constant setup for `lzistepx`, `advancetable`, and `tstep`.

The release path now runs that original instruction sequence once after `D_PolysetCalcGradients` for each triangle. Both alias span call sites use `D_PolysetDrawSpans8Prepared`, which preserves the same callee-saved registers and reads the same first span count while skipping repeated setup. The regular `D_PolysetDrawSpans8` entry remains available and still builds the constants for its other callers. `PROFILE486` keeps using the profiled cdecl wrapper. The follow-up changes only the prepared entry's private pointer convention from a stack argument to caller-saved EAX.

This is an exact setup hoist: the arithmetic, widths, truncation, and instruction order are unchanged. The gradients are produced by `D_PolysetCalcGradients`; the following edge and span-package setup only reads the four inputs and does not overwrite them or the derived constants. The span pixel/Z loop is unchanged.

The first ad hoc frame comparison omitted the scenario's fixed `host_framerate 0.0783`, so its nonzero image diff was invalid evidence. Under the actual `demo1-drawspans8` scenario settings (`host_framerate 0.0783`, `d_subdiv16 0`), the candidate and current-HEAD baseline each match the committed frame-169 golden at zero tolerance: 0 of 64,000 changed pixels, matching palette, and maximum channel error 0. Candidate and baseline captures also match each other exactly in both runs. All 970 per-frame framebuffer checksums match across candidate repeats, baseline repeats, and corresponding candidate/baseline runs; each full run ends at checksum `3987640479` with identical event traces.

- Candidate fixed-clock validation: `out/dos-timedemo-20261102-061556/timedemo-result.json` (source fingerprint `149A64F789A0A18314307AF77BF9FEAE1C0FED6981800BEC25A06FC5F7C93540`)
- Current-HEAD baseline fixed-clock validation: `out/dos-timedemo-20261102-061958/timedemo-result.json` (source fingerprint `879D6A581381BB99D38479220449F3DE5904F6B79D18A120EEE57E727E9BD027`)
- Zero-tolerance image reports: candidate vs golden `out/dos-timedemo-20261102-061556/frame169-golden.json` and `frame169-golden-run2.json`; baseline vs golden `out/dos-timedemo-20261102-061958/baseline-run1-golden.json` and `baseline-run2-golden.json`; candidate vs baseline `out/dos-timedemo-20261102-061958/candidate-run1-comparison.json` and `candidate-run2-comparison.json`.

The separate uninstrumented performance screens omit fixed `host_framerate` so the timing result measures renderer throughput. They rendered 969 frames with final checksum `1047377823` and identical event traces. Frame-checksum instrumentation runs are correctness evidence only; their FPS is not used for promotion.

The earlier alias prepare source-cursor optimization was already carried into the assembly path: `R_AliasPreparePointsVertices_asm486` keeps the input vertex cursor in `%ebx` and stores `r_apverts` once at exit. It did not need reimplementation.

## Benchmarks

All runs used DOSBox-X 2026.08.31, the pinned i486 profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, CWSDPMI, `demo1`, and the same data root. Runs were uninstrumented.

| Variant | FPS samples | Median FPS |
| --- | --- | ---: |
| 14-comparison control | 16.343255 / 16.343267 / 16.343265 / 16.343260 / 16.216210 | 16.343260 |
| Span setup screen A | 16.345700 / 16.345690 / 16.345695 / 16.345700 / 16.345695 | 16.345695 |
| Span setup screen B | 16.345693 / 16.345700 / 16.345697 / 16.345697 / 16.345686 | 16.345697 |
| Bracketed span setup screen | 16.345703 / 16.345710 / 16.345710 / 16.345675 / 16.345703 | 16.345703 |

The control includes one host hitch at 16.216210 FPS; its other four samples average 16.343261750 FPS. The 15 candidate samples averaged 16.345696933 FPS with a pooled median of 16.345697, a median gain of **0.002437 FPS (+0.0149%)** against the five-run control median. Each candidate screen's median exceeded the control median.

- Control: `out/dos-timedemo-20261031-095456/timedemo-result.json`
- Candidate A: `out/dos-timedemo-20261101-180857/timedemo-result.json`
- Candidate B: `out/dos-timedemo-20261101-181659/timedemo-result.json`
- Bracketed candidate: `out/dos-timedemo-20261101-185046/timedemo-result.json`

## Compatibility and disposition

The complete linked i486 gate passed: 314,344 relocated instructions, one i486 instruction, zero above-i486, unknown, exempt, or unaccounted bytes; 529 startup code rows; 9,207 provider instructions; 403 exact source proofs. No post-486 instruction was introduced.

- Build and audit: `out/local-alias-prepared-spans-20261101/`
- Source fingerprint: `149A64F789A0A18314307AF77BF9FEAE1C0FED6981800BEC25A06FC5F7C93540`
- Executable SHA-256: `F282B3A33685D1D0C370AB52A6F8E524E5723A43CDE4B08CA0F401C48FB99D7D`
- Combined edge-sort interaction results: `2026-11-01-edge-sort-nonbmodel-sixteen-recheck-rejected.md`


To repeat the five-run timing screen against the already audited executable:

```powershell
rtk proxy pwsh -NoLogo -File tools/timedemo-dos.ps1 -NoBootstrap -SkipBuild -Runs 5 -TimeoutSeconds 180 -DataRoot workspace\quake\out\dos-timedemo-20261030-231008\quake\id1 -LocalOutputDirectoryName alias-prepared-spans-20261101
```

The first candidate screen omitted `-SkipBuild` to build and strictly audit the candidate executable. The earlier source-cursor result was already represented by the assembly port's `%ebx` input cursor and one final `r_apverts` store; the 2026-10-02 `D_DrawSpans16` segment-dependent setup proposal is a separate calculation and was not hoisted.
