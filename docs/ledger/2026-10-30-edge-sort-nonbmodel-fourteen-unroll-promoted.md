# R_GenerateSpans non-bmodel edge-search fourteen-way unroll (2026-10-30)

Status: retained after three matched, uninstrumented 320x200 DOSBox-X pairs,
exact fixed-step frame and image parity, and a fresh strict i486 audit of the
fourteen-comparison source.

## Change

`Lsortloopnb` in `src/r_edgea.s` now checks fourteen surfaces before taking its
back-edge, up from twelve. The initial comparison remains outside the repeated
body. Each comparison keeps the original order, signed `jl LInsertAndExit`, and
immediate exit. The `PROFILE486` counter and optional sort probe remain attached
to every comparison. The added body is six instructions; the hypothesis was
that fewer taken back-edges offset the larger loop body.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, the pinned `cputype=486`, fixed-33445
cycle profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
CWSDPMI, `demo1`, `testdata/id1`, the aggressive selector profile, and the C
`R_RenderWorld` selector. Candidate and control were run in alternating pairs.

| Pair | Candidate 14-way FPS | Control 12-way FPS | Delta |
|---|---:|---:|---:|
| 1 | 16.321835 | 16.321799 | +0.000036 |
| 2 | 16.321799 | 16.321793 | +0.000006 |
| 3 | 16.321801 | 16.321795 | +0.000006 |

The candidate mean was **16.321811667 FPS** and the control mean was
**16.321795667 FPS**, a pooled gain of **+0.000016 FPS (+0.0000980%)**.
All six runs rendered 969 frames and ended at framebuffer checksum
`1047377823`. This is a positive, near-noise-sized DOSBox-X result and meets
the current positive-pooled-mean policy; it does not predict a physical 486
speedup.

Candidate samples: `out/dos-timedemo-20261030-061641`,
`out/dos-timedemo-20261030-061922`, and
`out/dos-timedemo-20261030-062203`. Control samples:
`out/dos-timedemo-20261030-061800`,
`out/dos-timedemo-20261030-062042`, and
`out/dos-timedemo-20261030-062322`.

The uninstrumented candidate and control executables were
`FC8B44AC1F06C2A1DD4DE865E8885216EA1E416D091DFFCFAE14613574829766` and
`BF5A11AA71F36CC81B96FE6547F48B32E5EAAFB7AD9A84207B21782BC51701A1`.
Their build manifests have identical renderer selectors. The object comparison
shows the intended `r_edgea` change plus build-time `__TIME__` strings in
`host` and `host_cmd`; those startup strings execute before timedemo timing.

## Exact output and ISA gates

The ordinary timedemo checksum stream was not stable across repeats of the
same candidate executable, so it was not used for exact image acceptance. A
fixed-step replay set `host_framerate 0.0783` for both variants. The 14-way
candidate and 12-way control then matched all 970 checksum records exactly.
Their frame-169 PCX captures both decode to 320x200, have identical palettes
and pixels, and have SHA-256
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`.
The fixed-step runs are `out/dos-timedemo-20261030-064607` and
`out/dos-timedemo-20261030-064752`.

A fresh build from the fourteen-comparison source passed the complete linked
i486 audit: 314,286 relocated instructions, 529 startup rows, and 9,207
CWSDPMI instructions, with zero above-i486, unknown, or exempt instructions.
Its source-bound capture build is
`out/local-edge-sort-14-final-20261030`; the candidate source SHA-256 is
`CC4AA7016C1E7BE8DB1239EA9B4B9DFC645ED0A99D12AB69883B7ECD042E597A`.
The 12-way control source SHA-256 is
`25B8A36811DD5A8745832DF51A1F2EBAEE66EFE7079C95C3E2F0CE1C17BFBD89`.

The emulator does not model a physical 486's cache occupancy, external-memory
wait states, VGA bus, or x87 latency closely enough to establish the hardware
effect of this small scheduling change.
