# Span16 integer setup scheduled behind paired FILDs (2026-10-29)

## Change and rationale

After loading the two coordinates into the x87 stack, `D_DrawSpans16` now
loads the independent destination and continuation state before starting the
dependent x87 arithmetic:

```asm
fildl   espan_t_v(%ebx)
fildl   espan_t_u(%ebx)
movl    espan_t_v(%ebx),%eax
movl    C(tadjust),%edx
pushl   espan_t_pnext(%ebx)
movl    C(sadjust),%esi
movl    C(viewspantable)(,%eax,4),%edi
movl    espan_t_u(%ebx),%ecx
addl    %ecx,%edi
movl    espan_t_count(%ebx),%ecx
```

The x87 stack and arithmetic order are unchanged. This fills the conversion
and setup interval with independent integer work, and moves those reads out of
the post-`FDIV` interval. The effect is measured under DOSBox-X; the emulator
does not establish physical 486 cycle counts.

## Matched measurement

All variants used DOSBox-X 2026.08.31, the pinned i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the aggressive i486 assembly profile, and 320x200 output. Each
variant ran three uninstrumented 969-frame timedemos.

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Original schedule | 16.320914 / 16.320912 / 16.320921 | 16.320915667 |
| Paired `FILD` schedule | 16.321722 / 16.321690 / 16.321716 | 16.321709333 |
| Full integer setup in FILD window | 16.321754 / 16.321710 / 16.321705 | 16.321723 |

The full setup schedule improved the paired-`FILD` mean by **0.000013667 FPS
(+0.00008373%)**, for a cumulative **0.000807333 FPS (+0.004947%)** over the
original schedule. The screen-only three-run mean was 16.321717667 FPS. Every
run in all three variants rendered 969 frames with checksum `1047377823`.
Retain the full setup schedule under the positive pooled-mean policy.

## Compatibility and artifacts

The complete linked i486 gate passed: 314,263 relocated instructions, 529
startup rows, and 9,207 CWSDPMI provider instructions, with zero instructions
above i486, unknown instructions, or exemptions.

- Original results: `out/dos-timedemo-20261029-100717/timedemo-result.json`
- Paired-`FILD` results: `out/dos-timedemo-20261029-110141/timedemo-result.json`
- Screen results: `out/dos-timedemo-20261029-113506/timedemo-result.json` (`isaAuditStatus=SKIPPED`)
- Strict results: `out/dos-timedemo-20261029-115044/timedemo-result.json`
- Candidate source fingerprint: `91545531B9583D45A6FC43A8EF640E36516833BDDEB0B2972B984A0354319B0A`
- Candidate source-tree fingerprint: `E868748B19BC30F95ABE7F5D2BD64ABB5BEE7530C310A05597F218B03F72A071`
- Candidate `qbench.exe` SHA-256: `E623363940C12B5A4452E1BA8F0FB18F988C03F7731D734A7251FE5077F292F1`

Exact checksum parity establishes unchanged output for this workload. These
measurements are DOSBox-X evidence and are not a physical-hardware benchmark.
