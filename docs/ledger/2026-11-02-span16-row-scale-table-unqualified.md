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

The candidate was not qualified for correctness, performance, or strict i486
compatibility. Its opt-in assembly and selector changes were removed, leaving
the control implementation active. No speedup or pixel-exactness claim is
made. A future attempt needs complete matched frame parity and a strict ISA
audit before uninstrumented timing.
