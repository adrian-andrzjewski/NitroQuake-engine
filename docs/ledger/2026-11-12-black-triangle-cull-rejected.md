# Black alias-triangle culling rejected (2026-11-12)

<!-- optimization-attempt: alias-black-triangle rejected -->

## Candidate

The clear-color cvar now defaults to palette index 0, which is pure black.
World BSP surfaces are span drawn; the triangle rasterizer is used for alias
models. Because a black alias triangle can occlude later geometry, omitting its
depth work would be unsafe. The isolated candidate therefore kept the original
recursive coverage and depth tests, and only bypassed skin/colormap lookup and
redundant writes for front-facing triangles whose vertices shared one integer
S/T texel and one light row and whose final mapped texel was black.

The candidate is not in the active renderer because it did not improve the
measured workload.

## Output checks

Control and candidate used the same 320x200 DOSBox-X 2026.08.31 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`), local
Quake data, and `demo1`. Both completed 969 timed frames and ended at framebuffer
checksum `1047377823`. The captured frame-169 PCX matched exactly
(SHA-256 `E854F84B5CA412182DBD032808791A53CDBA3C0E491202B783D8743E9A3BE81F`).

Exact full-stream parity could not be established. The initial color and Z
streams differed around entries 727–731. Repeated control runs with the same
capture index also differed at those entries, and repeated candidate runs varied
there as well. The `demo1` run was therefore not repeatable over that segment in
this checksum configuration; these observations do not isolate a candidate
visual difference.

## Strict i486 gates

The control and candidate release builds passed with 165,071 and 165,238 linked
instructions. The qbench builds passed with 317,499 and 317,664 linked
instructions. All reported zero above-i486, unknown, or exempt instructions and
passed the 529-row startup and 9,207-instruction DPMI-provider proofs.

## Matched timing

Three alternating uninstrumented `demo1` pairs used the pinned DOSBox-X profile.
Per-frame checksums, Z checksums, FPS instrumentation, and profiling were off
during timing. Each run passed the final framebuffer checksum gate.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.240564 / 16.928555 | 57.243800 / 16.927597 |
| 2 | 57.240561 / 16.928555 | 57.243767 / 16.927607 |
| 3 | 57.240544 / 16.928560 | 57.243787 / 16.927602 |

The means were 16.928556667 FPS for control and 16.927602 FPS for the candidate,
a -0.0056394% change. All candidate samples were slower, so the culling path is
rejected. This is DOSBox-X evidence, not a physical-486 performance claim.

## Artifacts and disposition

- Candidate worktree: `D:\NitroQuake-black-triangle-20261112\`
- Build reports: candidate worktree `out\profile-64dd9f2156152453` (control) and
  `out\profile-d61404f9a167f150` (candidate)
- Benchmark handoffs and logs: `benchmarks\out\black-triangle-20261112\`
- The temporary `AliasBlackTriangleCull` parameter in
  `benchmarks/tools/timedemo-dos.ps1` was removed after the experiment; its file
  hash matches the pre-experiment version.

Only the pure-black clear-color default was applied to the active checkout. The
triangle-culling implementation remains in the isolated worktree for review; no
commit was created.
