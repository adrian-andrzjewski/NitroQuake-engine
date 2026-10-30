# `R_GenerateSpans` trailing-edge direct-call layout rejected for parity (2026-10-29)

Status: rejected after one complete 969-frame 320x200 run failed the framebuffer
checksum gate. Its reported FPS is invalid and is not a performance result.

## Candidate

The pure trailing-edge path used `pushl $Lgs_nextedge; jmp TrailingEdge`, with
the helper returning through the synthetic continuation. The candidate replaced
that pair with `call TrailingEdge` and moved the `Lgs_nextedge` scan advance and
right-edge cleanup directly after the call. This was intended to let the
helper's `ret` return to the continuation with one fewer dispatch instruction.

The candidate passed its complete linked i486 ISA gate: 314,306 instructions,
zero above-i486, unknown, or exempt instructions. Its first timedemo run rendered
969 frames in 51.835069 seconds (18.693908 FPS), but ended with framebuffer
checksum `3586745294`, not the expected `1047377823`. The runner rejected the
run before producing a valid timing comparison. Artifact:
`out/dos-timedemo-20261029-225615/quake/TIMEDEMO.TXT`.

## Cause and disposition

The checksum failure came from the code layout. In the original routine,
`LInsertAndExit` falls through directly to `Lgs_nextedge` after linking a leading
surface. Moving `Lgs_nextedge` before the `R_GenerateSpans` entry made that path
fall through into `Lxl_done`, which increments `st_spanstate` before advancing
the edge. The candidate therefore changed surface-span state on ordinary
leading edges.

The attempted layout was removed. The active code again uses
`pushl $Lgs_nextedge; jmp TrailingEdge`, and `Lgs_nextedge` remains after
`LInsertAndExit`. The fresh three-run control was 16.329108 / 16.329125 /
16.329110 FPS (mean 16.329114333, spread 0.000017); every run rendered 969
frames with checksum `1047377823`. Its result is
`out/dos-timedemo-20261029-224006/timedemo-result.json`.

A layout-preserving follow-up would need an explicit jump after leading-edge
insertion. The current profile counted 2,465,433 `LInsertAndExit` events and
2,238,033 trailing-edge calls, so that jump would execute more often than the
single trailing dispatch instruction it could remove. That variant was not
built or timed. No timing from the parity-failing candidate is retained as a
speed result.
