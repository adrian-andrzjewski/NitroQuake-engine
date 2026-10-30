# Span16 carry-table preload schedules rejected (2026-10-29)

Status: both candidates were rejected after three-run 320x200 parity screens.
The source retains the indexed memory-operand `ADC` schedule.

## Candidate schedules and results

Both candidates moved the selected T-carry base into a register before the
carry-dependent address update, replacing the indexed memory-operand `ADC`
with a separate load and register `ADC`.

Candidate A loaded the selected base after the S fractional add. Its three
samples were 16.178793, 16.304876, and 16.304891 FPS, mean **16.262853333 FPS**
and median 16.304876 FPS. Against the retained FILD-window control mean of
16.321723 FPS, this was **−0.058869667 FPS (−0.360683%)**.

Candidate B moved the existing carry-base store after the T carry test, then
loaded the selected base before the S fractional add. Its three samples were
16.304895, 16.304896, and 16.304892 FPS, mean **16.304894333 FPS** and median
16.304895 FPS. This was **−0.016828667 FPS (−0.103106%)** against the same
control.

Both screens used DOSBox-X 2026.08.31, the pinned i486 profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the aggressive i486 assembly profile at 320x200. All six runs
completed 969 frames and produced framebuffer checksum `1047377823`.

## Disposition

Both pooled means were negative, so both schedules were rejected. The strict
ISA audit was skipped for each parity-screen candidate after the performance
regression. The original indexed memory-operand `ADC` was restored; the
separately promoted FILD-window load schedule remains active.

- Control: `out/dos-timedemo-20261029-115044/timedemo-result.json`
- Candidate A: `out/dos-timedemo-20261029-125929/timedemo-result.json`
- Candidate B: `out/dos-timedemo-20261029-130443/timedemo-result.json`
