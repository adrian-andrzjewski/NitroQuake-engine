# Span16 spaced x87/integer load schedule rejected (2026-10-29)

Status: rejected after a strict three-run comparison; the paired `FILD`
schedule remains in `src/d_draw16.s`.

## Candidate and parity screen

The follow-up moved `tadjust` between the two independent x87 loads:

```asm
fildl   espan_t_v(%ebx)
movl    C(tadjust),%edx
fildl   espan_t_u(%ebx)
movl    espan_t_v(%ebx),%eax
```

It aimed to begin integer work while the first `FILD` was in flight. The
un-instrumented parity screen completed 969 frames in all three runs with
checksum `1047377823`; its mean was 16.321720667 FPS, just above the retained
candidate's 16.321709333 FPS. Because the apparent margin was smaller than the
run spread, the screen did not establish a performance win and was followed by
the complete strict gate.

## Strict result and disposition

Both candidates used DOSBox-X 2026.08.31, the pinned i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the aggressive i486 assembly profile, and 320x200 output. Each strict
variant ran three uninstrumented 969-frame timedemos.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Retained paired `FILD` schedule | 16.321722 / 16.321690 / 16.321716 | 16.321709333 |
| Spaced candidate | 16.321710 / 16.321695 / 16.321719 | 16.321708 |

The spaced candidate was **0.000001333 FPS slower (-0.00000817%)** by pooled
mean. All six strict runs preserved checksum `1047377823`. Its complete linked
i486 audit passed: 314,263 relocated instructions, 529 startup rows, and 9,207
CWSDPMI provider instructions, with zero instructions above i486, unknown
instructions, or exemptions. The candidate is still rejected under the
positive-mean rule because its strict mean did not exceed the retained parent.

- Parity-screen results: `out/dos-timedemo-20261029-110916/timedemo-result.json` (`isaAuditStatus=SKIPPED`)
- Strict results: `out/dos-timedemo-20261029-112531/timedemo-result.json`
- Retained schedule results: `out/dos-timedemo-20261029-110141/timedemo-result.json`

The source was restored to the paired `FILD` schedule. Measurements are
DOSBox-X evidence, not a physical 486 benchmark.
