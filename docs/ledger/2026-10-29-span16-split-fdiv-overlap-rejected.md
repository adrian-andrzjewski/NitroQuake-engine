# Span16 split FILD/FDIV integer schedule rejected (2026-10-29)

Status: rejected on a three-run parity screen; source restored to the complete
FILD-window schedule.

## Candidate and parity screen

This candidate kept the row and destination loads after the paired `FILD`s,
but moved the next-span push and `sadjust` load back to immediately after the
initial `FDIV`:

```asm
fildl   espan_t_v(%ebx)
fildl   espan_t_u(%ebx)
movl    espan_t_v(%ebx),%eax
movl    C(tadjust),%edx
movl    C(viewspantable)(,%eax,4),%edi
movl    espan_t_u(%ebx),%ecx
addl    %ecx,%edi
movl    espan_t_count(%ebx),%ecx
; x87 coordinate setup and initial FDIV
pushl   espan_t_pnext(%ebx)
movl    C(sadjust),%esi
```

DOSBox-X 2026.08.31, the pinned i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the aggressive i486 assembly profile were used at 320x200. The
three uninstrumented parity-screen samples were 16.321722, 16.321713, and
16.321726 FPS, mean **16.321720333 FPS**. All runs completed 969 frames with
framebuffer checksum `1047377823`.

## Disposition

The retained complete FILD-window schedule averaged 16.321723 FPS in its
strict three-run comparison. This screen was **0.000002667 FPS slower** by
pooled mean, so the split schedule was rejected before a strict ISA build. Its
result records `isaAuditStatus=SKIPPED`; it provides parity and timing only.
The source was restored to the complete FILD-window schedule.

- Candidate parity-screen result: `out/dos-timedemo-20261029-120036/timedemo-result.json`
- Retained strict result: `out/dos-timedemo-20261029-115044/timedemo-result.json`
