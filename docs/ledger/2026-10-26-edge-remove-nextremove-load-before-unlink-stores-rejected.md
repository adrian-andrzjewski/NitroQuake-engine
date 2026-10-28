# `R_RemoveEdges`: load `nextremove` before both unlink stores — rejected

**Date:** 2026-10-26

**Status:** Rejected; the source was restored to the control schedule.

The candidate moved `movl et_nextremove(%eax),%eax` ahead of both unlink stores
in each of the two unrolled removal iterations. The neighbor loads and store
order stayed unchanged.

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB
i486 profile (`cputype=486`, dynamic core, fixed 33,445 cycles; SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Every
run completed 969 frames with framebuffer checksum `1047377823`.

| Gate | Candidate FPS samples | Mean | Result |
|---|---|---:|---|
| Parity screen | 15.942833 / 15.942856 / 15.942874 | 15.942854333 | Exact frames/checksum |
| Strict | 15.942836 / 15.942831 / 15.942839 | 15.942835333 | Exact frames/checksum; ISA audit PASS |

The strict control mean was `15.942859333 FPS`; the candidate was slower by
`0.000024000 FPS`. The complete executable i486 audit verified 314,408 linked
instructions, 529 startup rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. Since the strict mean regressed,
the edit was reverted and no code commit was made.

Artifacts:

- `out/dos-timedemo-20261026-121956/timedemo-result.json` (parity screen)
- `out/dos-timedemo-20261026-125321/timedemo-result.json` (strict run)
