# `R_GenerateSpans` non-bmodel sort twelve-way unroll promoted (2026-10-29)

Status: retained under the current positive pooled-mean policy after matched
320x200 timing, exact per-frame and framebuffer parity, and a strict i486 ISA
audit of the exact changed renderer object.

`Lsortloopnb` now checks twelve active-surface nodes per back-edge, branching
to insertion as soon as a signed comparison ends the search. The original
sixteen-way body's final four comparisons and their optional diagnostic
counter/probe statements were removed. Comparison ordering, signed condition,
and insertion path are unchanged. This tests whether a smaller loop body and
shorter hot instruction footprint can offset the occasional additional
back-edge.

## Matched 320x200 timedemo

Both variants used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, `-stdvid`, the
aggressive i486 selector profile, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
three-run uninstrumented measurements were:

| Variant | Evidence | FPS samples | Spread | Mean FPS |
|---|---|---|---:|---:|
| Sixteen-way control | `out/dos-timedemo-20261029-213237/timedemo-result.json` | 16.329118 / 16.329103 / 16.329114 | 0.000015 | 16.329111667 |
| Twelve-way candidate | `out/dos-timedemo-20261029-213827/timedemo-result.json` | 16.329113 / 16.329111 / 16.329131 | 0.000020 | 16.329118333 |

The candidate mean improved by **0.000006667 FPS (+0.00004083%)**. This is
smaller than either run set's spread and should be treated as a tiny, noisy
gain; it qualifies under the project's policy of retaining any positive mean
from at least three matched runs. All six runs completed 969 frames with
framebuffer checksum `1047377823`.

## Output and i486 proof

A fixed-step candidate replay produced 971 checksum records, exactly matching
the control stream in `out/dos-timedemo-20261029-204044/runs/run-01/`. The
320x200 captured PCX was also byte-identical to the already visually validated
control capture (SHA-256
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`). The
candidate replay is recorded in
`out/dos-timedemo-20261029-215140/timedemo-result.json`.

The control source fingerprint/tree fingerprint were
`E52CED4175DD2955D4631AFB0432C9111FC18C730E96A6D74313D3714A64BD9A` /
`469FB4427C8E8DAAF5137C90FCF127938486EDE315C13A70F242D070D72DCE43`; the
candidate values were
`1317F4FE11F2459AE4C487607CB8F63E483475C0ADB15F09042EC4F9F5DA2206` /
`32CE86078CC63ED86A8E24ADD52B9FD51D4743AC937EBB5EA2D8B9516187D228`.

The strict linked audit at
`out/local-edge12-strict/isa-qbench/isa-audit-linked-objects.json` passed with
maximum ISA i486 and 314,306 instructions, with no above-target, unknown, or
exempt instructions. Its `r_edgea.obj` was byte-identical to the candidate
timing build's changed object (SHA-256
`5C0DC1F01E3EABCD5051360F2A433205CF8B7127370832B2FBD098ACDF0BC859`). The
strict and timing executables were not hash-identical, so this evidence is
limited to the exact changed object plus the separate strict whole-build
audit. Measurements use DOSBox-X and do not establish physical 486 cycle
counts.
