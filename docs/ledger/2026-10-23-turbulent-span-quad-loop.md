# Promote four-pixel turbulent span loop

The opt-in `quad` implementation writes four turbulent pixels per loop branch
and handles the remaining zero to three pixels with a short tail. It preserves
the existing pixel calculation and leaves the i486 default on the previously
promoted assembly path.

## Matched timedemo

The `demo1` timedemo used the same 32 MB 486 profile, cycle count, executable
selectors, demo data, and `-timedemoexit -nosound -nocdaudio` options as the
committed paired-loop baseline. The profile SHA256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
Every candidate run rendered 969 frames and produced framebuffer checksum
`1047377823`.

| Variant | FPS samples | Mean FPS |
|---|---|---:|
| ASM control | 15.591165, 15.591674, 15.591661 | 15.591500 |
| Committed paired loop | 15.601304, 15.601297, 15.601298 | 15.601299667 |
| Four-pixel loop | 15.602528, 15.602510, 15.602526 | 15.602521333 |

The four-pixel loop gains **0.001221667 FPS (+0.00783054%)** over the current
committed paired-loop baseline. Its three run times were 62.105319, 62.105393,
and 62.105328 seconds. All runs passed the 969-frame checksum gate.

The checkout's default DOSBox-X template currently specifies 16 MB, which
leaves only 5.2 MB available to Quake and fails its startup minimum. The
measurement used a temporary 32 MB profile whose normalized hash matches the
paired-loop baseline; the failed 16 MB startup attempt was excluded.

## Strict i486 validation

The benchmark executable passed the complete source-bound i486 ISA gate:
313,471 relocated instructions, zero above-i486 instructions, unknown
instructions, or exemptions. The audit covered 168 project objects, 235
runtime objects, 529 startup instructions, and 9,207 external DPMI-provider
instructions. The executable SHA256 was
`0BE4E3438A66B45CA1B91146737F77ABA096F9AC5ACD6DDD82257B6153E32BBD`.

Artifacts:

- Timedemo: `out/dos-timedemo-20261023-004725/timedemo-result.json`
- Strict build and ISA reports: `out/local-turbulent-quad-strict-20261023/`
