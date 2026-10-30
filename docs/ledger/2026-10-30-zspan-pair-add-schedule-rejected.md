# Z-span pair update scheduling (2026-10-30)

Status: reverted after a negative three-run 320x200 comparison.

## Candidate

In `ZSPAN_ADD_PAIR_NONNEGATIVE` in `src/d_draw.s`, move the second
`addl %ebx,%edx` between `shldl $16,%edx,%eax` and `rorl $16,%eax`. The add
advances the next inverse-depth sample and is independent of the packed pixel
in `%eax`; the instruction order preserves both values. The i486 code path was
the only path changed. The original order has been restored.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `cputype=486`, the pinned profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and the aggressive i486 selector profile.

| Variant | Source-tree fingerprint | FPS samples | Mean FPS |
|---|---|---|---:|
| Retained control | `FD83991C2451D64C6B7579499791395270C3B7C213213F420E4B606BBCBE614D` | 16.328477 / 16.328473 / 16.328474 | 16.328474667 |
| Add between SHLD and ROR | `78F3A1447B217F1624873CCF0F425DF847DB2C0580EEB9E732630DC84A22571A` | 16.328458 / 16.328482 / 16.328466 | 16.328468667 |

The candidate lost **0.000006 FPS (-0.0000367%)**, smaller than the sample
spreads. All six runs rendered 969 frames and ended with framebuffer checksum
`1047377823`; particle and damage event traces matched. No timing benefit was
measured, so the schedule was reverted.

Control: `out/dos-timedemo-20261030-162411/timedemo-result.json`.
Candidate: `out/dos-timedemo-20261030-180159/timedemo-result.json`.

## Genuine-486 instruction gate

The candidate passed the complete linked i486 audit: 314,303 relocated
instructions, 529 startup instructions, and 9,207 CWSDPMI provider
instructions; zero above-i486, unknown, or exempt instructions. The arithmetic
and sampled outputs are unchanged by the instruction reorder.
