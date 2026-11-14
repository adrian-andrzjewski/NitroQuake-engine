# Z-span row-table lookup before second FILD rejected (2026-10-30)

## Candidate

In both `LFSpanLoop` and `LFNegSpanLoop` in `src/renderer/d_draw.s`, the lookup
`zspantable[espan_t_v]` moved from after the second coordinate `FILD` and its
first multiply/swap to immediately before the second `FILD`. This tested
whether the 486 integer pipeline could perform the independent row lookup while
the x87 stack setup continued. The x87 arithmetic order did not change.

## Matched 320x200 measurement

Both variants used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile with
SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
the `demo1` 969-frame workload, and `CacheCheckImplementation=asm`.

| Variant | FPS samples | Mean FPS |
|---|---|---:|
| Control | 16.321765 / 16.321718 / 16.321720 | 16.321734333 |
| Candidate | 16.321754 / 16.321710 / 16.321691 | 16.321718333 |

The candidate was **0.000016 FPS slower (-0.0000980%)**. All six runs rendered
969 frames and reported framebuffer checksum `1047377823`. The candidate does
not meet the positive-mean promotion rule.

## i486 gate and disposition

The candidate passed the complete executable i486 gate: 314,338 relocated
instructions, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The candidate source-tree
fingerprint was
`7011889C0D21A3DC82991D990F3F186C0691A4BBB1F9BF07A939A6F5E02D04F4`; the
control fingerprint was
`E97BF109AE978C99529F1764349C201F85F7A821B3B3E09ED59C95AC06F14957`.

The lookup returned to its previous position. The already-promoted row-index
interleave remains in both loops; no candidate code from this experiment is
retained.

## Artifacts

- Control timing: `out/dos-timedemo-20261030-124853/timedemo-result.json`
- Candidate timing: `out/dos-timedemo-20261030-130358/timedemo-result.json`
- Candidate executable: `out/profile-107ff6406936b458/qbench.exe`
