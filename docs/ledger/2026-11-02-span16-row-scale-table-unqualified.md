# Span16 signed row-scale table unqualified and removed (2026-11-02)

## Candidate

The opt-in `TextureSpanAddressing=rowtable8` path cached exact products of the
surface-cache width and signed integer T steps from -8 through 8. Values
outside that range retained `IMUL`. The candidate changed `src/d_draw16.s` and
the build and timedemo selector scripts. The default selector remained
`control` throughout.

## Correctness and performance evidence

The two candidate checksum runs, `out/dos-timedemo-20261102-222239` and
`out/dos-timedemo-20261102-222456`, produced identical 970-record streams with
SHA-256
`23FF212F34AF0ACC87CC4AEFD7A980AF05EB9151062897B2BC96F0D9088313B8`. The
control streams from `out/dos-timedemo-20261102-202624` and
`out/dos-timedemo-20261102-203056` matched each other with SHA-256
`6A5C1EC913D3436B051A5B427FC5945901288D042DE8560B7B0758D7B09085C4`. The
candidate differed from control at indexed records 70, 270, 311, and 412,
although both ended with framebuffer checksum `1047377823`.

Only record 70 was captured for pixel inspection. Its 1,181 changed pixels
were confined to a centered pickup message near the top of the screen; the 3D
scene and lower HUD matched. This points to message-expiry timing for that
record, but does not explain the other three differences or establish full
pixel parity.

These were instrumented visual-parity runs, not valid performance runs. The
candidate build skipped the complete i486 ISA audit. No uninstrumented timing
result, full pixel comparison, or hardware result was obtained.

## Disposition

The `rowtable8` candidate remains unqualified and is removed from the active
source and selector profiles. The initial revision contained a register
liveness bug: it used EAX for the lookup index without restoring the fractional
T step consumed by the final-segment entry handlers. The corrected experiment
is preserved in the local Git stash for further diagnosis. `control` remains
the only active `TextureSpanAddressing` option. No performance gain is accepted.

## 2026-11-03 register fix and paired validation

The first candidate build passed the linked i486 instruction audit but had
visible rendering corruption. At frame 169, **5,784 of 64,000 pixel indices
differed** (first mismatch index 6, last 48332), and all **964 of 964**
post-warmup frame checksums differed. The original comparison and diff are
`out/rowtable8-parity-current-20261103/render-parity-result.json` and
`out/rowtable8-parity-current-20261103/framebuffer-diffs/demo1-vga-full-run-01.png`.

The defect was corrected by restoring the fractional T step to EAX after the
table lookup. The repaired candidate passed the strict i486 build gate. A
fresh, source-matched `demo1-vga-full` pair at 320x200 then passed exact parity:
all **964 of 964** compared frame checksums matched, and frame 169 had **0 of
64,000** pixel-index differences with an exact palette match. The paired report
is `out/rowtable8-parity-repaired-full-20261103/render-parity-result.json`.

One separate repaired-candidate run compared offline against a control report
from a different source-tree fingerprint and showed 407 checksum differences
of 964 (frames 28 through 948). Two control runs matched each other exactly;
the later fresh source-matched candidate pair also matched exactly. This leaves
the earlier candidate run unexplained and warrants repeated source-matched
parity before the experiment can be promoted. Details are in
`out/rowtable8-parity-repaired-compare-20261103.json` and
`out/rowtable8-control-repeat-compare-20261103.json`.

No valid performance comparison was obtained: the DOSBox-X timings ran while a
separate Quake2 DOSBox-X instance was active. The results are not physical 486
measurements. No speedup is claimed.
