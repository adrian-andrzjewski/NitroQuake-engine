# Span16 x87/integer load scheduling promoted (2026-10-29)

## Change and rationale

`src/d_draw16.s:D_DrawSpans16` now issues both independent x87 `FILD` loads
before loading the span's integer row and `tadjust` values:

```asm
fildl   espan_t_v(%ebx)
fildl   espan_t_u(%ebx)
movl    espan_t_v(%ebx),%eax
movl    C(tadjust),%edx
```

The FPU stack order and all subsequent arithmetic remain unchanged. The
schedule gives the independent integer loads an opportunity to overlap the
x87 conversions on the 486DX-class pipeline. This is a measured scheduling
hypothesis; DOSBox-X does not establish cycle counts for physical 486 hardware.

## Matched measurement

Both variants used DOSBox-X 2026.08.31, the pinned 486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), the
aggressive i486 assembly profile, CWSDPMI, and the same `demo1` workload at
320x200. Each variant ran three uninstrumented timedemos of 969 frames.

| Variant | FPS samples | Mean FPS | FPS spread |
| --- | --- | ---: | ---: |
| Baseline | 16.320914 / 16.320912 / 16.320921 | 16.320915667 | 0.000009 |
| Candidate | 16.321722 / 16.321690 / 16.321716 | 16.321709333 | 0.000032 |

The pooled mean improved by **0.000793667 FPS (+0.004863%)**. Every candidate
sample exceeded every baseline sample. All six runs produced checksum
`1047377823` and the expected 969 frames.

## Compatibility and artifacts

The candidate passed the complete linked i486 audit: 314,263 relocated
instructions, 529 startup rows, and 9,207 CWSDPMI provider instructions, with
zero instructions above i486, unknown instructions, or exemptions.

- Baseline results: `out/dos-timedemo-20261029-100717/timedemo-result.json`
- Candidate results: `out/dos-timedemo-20261029-110141/timedemo-result.json`
- Candidate source fingerprint: `E6C0FDBFE41A2B2E1CD0EEE9D049AB0767DC76C1516EC861EBA2EDF73C5F2001`
- Candidate `qbench.exe` SHA-256: `F7C4B1F8D5491C398D6CEE2E355CF4000D979AC58994F82FBB9BD5C545E99406`
- Current 320x200 profile: `out/dos-timedemo-20261029-104527/quake/profile.jsn`

Retain the reordered loads under the positive pooled-mean policy. Exact
framebuffer checksum parity establishes unchanged output for this workload;
the performance result is DOSBox-X evidence and is not a physical-hardware
benchmark.
