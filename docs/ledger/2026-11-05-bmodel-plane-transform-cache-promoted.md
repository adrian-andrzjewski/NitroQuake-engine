# Brush-model splitter-plane transform cache promoted (2026-11-05)

## Candidate and profile

`R_RecursiveClipBPoly_asm486` transformed the same BSP splitter plane into
brush-model coordinates on every recursive call, even when another face in
the same entity and frame had just used that plane. A 32-slot direct-mapped
cache now stores the four binary32 results (`dist` and three normal
components), tagged by splitter-plane pointer, current-entity pointer, and
`r_framecount`. The slot is selected by `(plane_pointer >> 2) & 31`; collisions
only cause misses. The four values occupy 896 bytes of BSS.

The pinned `demo1` profile made 41,158 plane-transform requests: 26,704 hits
and 14,454 misses (64.88%). It also counted 170,266 brush clip edges and
105,123 adjacent-endpoint matches across the two edge endpoints (30.9%). The
endpoint observation was diagnostic only; this change caches the more
expensive repeated splitter-plane transform.

## Output and i486 checks

The cache-on profile at `out/dos-timedemo-20261105-010048` matched the pinned
cache-off profile at `out/dos-timedemo-20261104-224740` across all 970
per-frame color and Z checksum values. Both color checksum files have SHA-256
`F1D99DA654FF6B849FE09713D87BA93316B6B2220975920EB41119C958742FF1`; both Z
checksum files have SHA-256
`3C886D24243FCE937F3EF483F723B2CD3389C9C54B84EAD8625C59F2A0F874F3`. The
final framebuffer checksum remained `1047377823`.

The release cache-on and cache-off checksum captures also ended at
`1047377823`. Independent release captures varied in the known late
wall-clock-sensitive window around frames 727-731, including repeated runs of
the same binary; the profile stream comparison above is the exact per-frame
parity result. The release cache-on build passed the complete strict i486 ISA
gate: 314,667 relocated application instructions, 529 startup code rows, and
9,207 DOS provider instructions, with zero above-i486, unknown, or exempt
instructions.

## Matched release timing

Both variants used DOSBox-X 2026.08.31, the pinned `cputype=486` profile
(SHA-256 `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
320x200 `demo1`, and 969 timedemo frames. Only the assembly cache branch
differed between binaries. The three uninstrumented runs were:

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Cache off | 16.388056, 16.388062, 16.388061 | 16.388059667 |
| Cache on | 16.390118, 16.390135, 16.390111 | 16.390121333 |

The cache-on mean is **+0.01258%**. This small but positive matched result
meets the renderer's current promotion rule. The DOSBox result artifacts are
`out/dos-timedemo-20261105-012218` (cache on) and
`out/dos-timedemo-20261105-013655` (cache off).
