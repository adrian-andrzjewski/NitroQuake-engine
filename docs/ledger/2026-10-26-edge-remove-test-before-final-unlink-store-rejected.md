# `R_RemoveEdges`: test `nextremove` before the final unlink store — rejected

**Date:** 2026-10-26

**Status:** Rejected; the source was restored to the control schedule.

The candidate moved `testl %eax,%eax` ahead of the final
`movl %edx,et_prev(%ecx)` store in both unrolled removal iterations. The store
does not change flags, so branch behavior and unlink order remained the same.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile (`cputype=486`, dynamic core, fixed 33,445 cycles; SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Gate | Candidate FPS samples | Mean | Result |
|---|---|---:|---|
| Parity screen | 15.942833 / 15.942865 / 15.942877 | 15.942858333 | Exact frames/checksum |
| Strict | 15.942846 / 15.942871 / 15.942834 | 15.942850333 | Exact frames/checksum; ISA audit PASS |

The strict control mean was `15.942859333 FPS`; the candidate was slower by
`0.000009000 FPS`. The complete executable i486 audit verified 314,408 linked
instructions, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. Since the strict mean regressed,
the edit was reverted and no code commit was made.

Artifacts:

- `out/dos-timedemo-20261026-114155/timedemo-result.json` (parity screen)
- `out/dos-timedemo-20261026-121400/timedemo-result.json` (strict run)
