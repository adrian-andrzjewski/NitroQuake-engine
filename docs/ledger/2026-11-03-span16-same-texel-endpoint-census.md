# Span16 same-texel endpoint census (2026-11-03)

## Measurement

A `PROFILE486`-only counter at `LClampReentry3` checked whether the starting
`s`/`t` coordinates and the clamped endpoints of each full 16-pixel segment
selected the same integer texel in both axes. With monotone interpolation, that
endpoint condition is sufficient for every intervening sample to remain in
one texel. It is conservative: a segment can still have identical emitted
samples when its next-segment endpoint has crossed a texel boundary.

One instrumented `demo1` run at 320x200 recorded **0 qualifying segments out of
2,059,043** full segments. The run rendered 969 frames and ended at the expected
framebuffer checksum `1047377823`. The pinned DOSBox-X 2026.08.31 profile hash
was `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`; the
strict linked i486 audit passed.

## Decision

Do not add a repeated-texel branch using this endpoint-equality condition: it
would not take in the measured workload. This result rejects only this
conservative predicate for this scene; it does not prove that no exact
sample-set predicate could find hits in other scenes. The experiment produced
no uninstrumented timing result and makes no FPS claim.

## Reproduction and checksum limits

The counter was added only to a detached scratch build based on `88c77df4516a` and
compiled under `PROFILE486`:

```powershell
rtk proxy pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\timedemo-dos.ps1 -SkipBuild -Instrumentation -Runs 1 -DataRoot <legal id1 data root> -LocalOutputDirectoryName dos-timedemo-span16-same-texel-census-20261103
```

The reported **11.135128 FPS** is instrumentation-heavy attribution data, not
a performance measurement. The single run verifies the expected final
checksum only; it does not establish per-frame-stream or pixel-by-pixel parity.
