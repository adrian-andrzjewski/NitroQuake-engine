# Cache the turbulent texture base in EBX (2026-10-27)

Status: promoted after a positive matched three-run mean, exact framebuffer
parity, and the complete strict i486 audit.

In the existing fourteen-pixel turbulent-span path, load `r_turb_pbase` into
EBX once per span and use it for every texel fetch. The span count moves to a
stack local so EBX remains available for the cached base; full groups and tail
checks update or inspect that local. This removes one global base load per pixel
at the cost of one stack-local count decrement per fourteen-pixel group.

All timedemos used DOSBox-X 2026.08.31, `demo1`, and the pinned 32 MB i486
profile (`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`).

| Variant | Artifact | FPS samples | Mean FPS |
|---|---|---|---:|
| Accepted control (`d9c1b36`) | `out/dos-timedemo-20261027-060739/timedemo-result.json` | 16.165754 / 16.165786 / 16.165774 | 16.165771333 |
| EBX cache parity screen | `out/dos-timedemo-20261027-065400/timedemo-result.json` | 16.178407 / 16.178418 / 16.178426 | 16.178417000 |
| EBX cache strict run | `out/dos-timedemo-20261027-071815/timedemo-result.json` | 16.178397 / 16.178429 / 16.178426 | 16.178417333 |

The strict-run mean increased by **0.012646 FPS (+0.078227%)**. All six
candidate runs rendered 969 frames and produced framebuffer checksum
`1047377823`; all candidate samples exceeded every control sample.

The full strict gate passed. Exact source proofs covered 168 project objects
and 235 installed runtime objects. The final executable audit verified all
314,300 linked instructions, 529 startup instructions, and 9,207 DPMI-provider
instructions, with zero above-i486, unknown, or exempt instructions.
