# Packed surface-span coordinate store rejected (2026-11-07)

## Candidate

Starting from `b851813c11e3`, `src/renderer/r_edgea.s` cached `current_iv << 16` once
at `R_GenerateSpans` entry. The three forward span-emission sites loaded
that cached word, inserted U with `movw %dx,%ax`, and stored the adjacent
16-bit U/V fields together with one `movl`. This replaced two short stores
per span while adding three setup instructions per scanline. The 12-byte
record layout and backward span path were unchanged.

The isolated worktree is `out/worktree-span-coordinate-store-20261107`.
Its `out/rejected-coordinate-store.patch` preserves the experiment;
`out/comparison.json` records the timing decision. The experimental source
was restored after rejection.

## Strict i486 audit

The release build passed the complete executable gate: 315,219 relocated
instructions, 529 DOS startup rows, and 9,207 provider instructions, with
zero above-i486, unknown, or exempt instructions. Project and runtime source
proofs passed for 168 and 235 objects, respectively. The build log is
`out/worktree-span-coordinate-store-20261107/out/build-span-coordinate-store-release.log`.

## Matched uninstrumented timing

The control's source and tool files were compared against the current
checkout with CRLF normalized; all compared files matched. Its executable
was reused from the accepted 12-byte span experiment, with fresh timing runs.
Both variants used DOSBox-X 2026.08.31, `cputype=486`, 320x200 `demo1`, CWSDPMI,
the same `testdata/id1` input, and profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All six runs completed 969 frames with final framebuffer checksum `1047377823`.
Instrumentation, per-frame timing, color checksum recording, and Z checksum
recording were disabled for these timing samples.

| Variant | FPS samples | Mean FPS | FPS spread |
| --- | --- | ---: | ---: |
| Control | 16.816088, 16.816069, 16.816076 | 16.816077667 | 0.000019 |
| Packed coordinate store | 16.812213, 16.812226, 16.812219 | 16.812219333 | 0.000013 |

The candidate mean regressed **0.0229443%**. Every candidate sample was slower
than every control sample. Control report:
`out/worktree-span12-debug/out/dos-timedemo-20261107-143955/timedemo-result.json`.
Candidate report:
`out/worktree-span-coordinate-store-20261107/out/dos-timedemo-20261107-145448/timedemo-result.json`.

## Decision and correctness scope

Reject under the non-positive pooled-mean rule. A fresh control replay also
recorded 970 color and Z checksum records and captured frame 154 at
`out/worktree-span12-debug/out/dos-timedemo-20261107-144403`. Candidate
per-frame and captured-image parity was not tested: the timing regression
already rejects this version. Matching final checksums and the ISA audit
are not a claim of complete output parity. No candidate code was promoted.
These measurements describe the pinned emulator, not physical 486 hardware.
