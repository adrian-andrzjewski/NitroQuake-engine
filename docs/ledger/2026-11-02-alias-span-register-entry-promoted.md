# Alias span prepared-entry register argument (2026-11-02)

Status: promoted after two repeatable uninstrumented 320x200 candidate screens, a fresh prepared-only control screen, exact fixed-clock parity against current HEAD and the committed golden, and the strict linked i486 audit.

## Change

`D_PolysetDrawSpans8Prepared` is called only by the two internal assembly call sites in `D_RasterizeAliasPolySmooth_asm486`. Those callers now pass the span-package pointer in caller-saved EAX. The prepared entry moves it to ESI after saving the caller's ESI, then draws the same package count. The normal C entry remains cdecl and still computes per-call setup; `PROFILE486` continues through the profiled cdecl wrapper.

This removes the temporary stack argument write and reread, plus one `addl $4,%esp`, from each prepared-entry call. It avoids changing the caller's live registers: EAX is dead at both call sites, while ESI, EBX, EBP, and EDI remain preserved. The pixel/Z loop, span count, and fixed-point operations are unchanged. The new path uses only 486-compatible register moves.

## Benchmarks

All runs used DOSBox-X 2026.08.31, the pinned i486 profile SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, CWSDPMI, `demo1`, the same data root, and uninstrumented 320x200 timedemos. Every run completed 969 frames with framebuffer checksum `1047377823` and identical event traces.

| Variant | FPS samples | Median FPS |
| --- | --- | ---: |
| Prepared-only control | 16.345693 / 16.345686 / 16.345692 / 16.345692 / 16.345686 | 16.345692 |
| Register entry screen A | 16.346963 / 16.346960 / 16.346960 / 16.346944 / 16.346944 | 16.346960 |
| Register entry screen B | 16.346964 / 16.346961 / 16.346959 / 16.346957 / 16.221586 | 16.346959 |

Both candidate medians exceed the fresh prepared-only control median by about **0.001268 FPS (+0.0078%)**. Screen B contains one host hitch; its other four samples are within 0.000007 FPS of the median. The pooled candidate median is 16.3469595 FPS. Combined with the prior triangle-constant setup hoist, this is +0.003700 FPS (+0.0226%) versus the original 14-comparison control median of 16.343260 FPS.

- Candidate A: `out/dos-timedemo-20261102-063935/timedemo-result.json`
- Prepared-only control: `out/dos-timedemo-20261102-064857/timedemo-result.json`
- Candidate B: `out/dos-timedemo-20261102-065506/timedemo-result.json`
- Historical 14-comparison control: `out/dos-timedemo-20261031-095456/timedemo-result.json`

## Pixel parity and compatibility

The proper `demo1-drawspans8` validation settings are `host_framerate 0.0783` and `d_subdiv16 0`. With those settings, the register-entry candidate completed two 969-frame runs with final checksum `3987640479`. All 970 per-frame checksums match between both candidate runs and between each candidate run and the current-HEAD baseline. Each candidate frame-169 PCX matches the committed golden and the baseline capture at zero tolerance: 0 of 64,000 changed pixels, matching palette, and maximum channel error 0.

- Candidate runs: `out/dos-timedemo-20261102-070109/timedemo-result.json` (source fingerprint `D668091039829FEA11F7AB8ADA120DDDF504211848A7F0571F60420A7CDA1B22`)
- Current-HEAD baseline runs: `out/dos-timedemo-20261102-061958/timedemo-result.json`
- Candidate-to-baseline image reports: `out/dos-timedemo-20261102-070109/baseline-run1-image.json`, `baseline-run2-image.json`
- Candidate-to-golden image reports: `out/dos-timedemo-20261102-070109/golden-run1.json`, `golden-run2.json`

The complete i486 audit passed for the register-entry executable: 314,349 linked instructions, exactly one i486 instruction, zero above-i486, unknown, exempt, or unaccounted instructions; 529 startup code rows; 9,207 provider instructions; and 403 exact source proofs.

- Build root: `out/local-alias-prepared-spans-regcall-20261102/`
- Executable SHA-256: `A20B69D955A43BC0B438F03E4406EE1C81868E3BDC5F6E503571F474F9FFEB31`
- ISA report: `out/local-alias-prepared-spans-regcall-20261102/isa-qbench/isa-audit-linked.json`

Reproduce the uninstrumented five-run candidate screen with:

```powershell
rtk proxy pwsh -NoLogo -File tools/timedemo-dos.ps1 -NoBootstrap -SkipBuild -Runs 5 -TimeoutSeconds 180 -DataRoot workspace\quake\out\dos-timedemo-20261030-231008\quake\id1 -LocalOutputDirectoryName alias-prepared-spans-regcall-20261102
```
