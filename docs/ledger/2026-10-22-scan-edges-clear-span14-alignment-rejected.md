# Reject sixteen-byte alignment of the fourteen-span scan-edge loop (2026-10-22)

The candidate added `.p2align 4,,15` before the fourteen-span clear-loop entry
in `R_ScanEdges`. It retained the same stores and grouped tail, passed exact
framebuffer parity and the strict i486 audit, but its mean FPS was below
control. The alignment directive has been removed; the unaligned fourteen-span
loop remains active.

The control and candidate used the same uninstrumented DOSBox-X `demo1`
timedemo, CWSDPMI, and pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Each
ran three times; a trailing control sample checked for drift. Every run
rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Aligned candidate | 15.601292, 15.601279, 15.601266 | 15.601279 | 0.000026 |
| Trailing control | 15.601291 | — | — |

The candidate delta is **−0.000024 FPS (−0.00015383%)**. It remained
**−0.000012 FPS** below the trailing control sample. Under the any-positive
pooled-mean rule, the negative strict mean rejects this candidate.

The complete strict i486 audit passed: 313,365 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All seven timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-170106/timedemo-result.json`
- Trailing control: `out/dos-timedemo-20261022-170456/timedemo-result.json`
- Candidate build and ISA reports: `out/local-scan-edges-clear-span14-alignment-20261022/`

Candidate fingerprints:

- Build source fingerprint: `8253C293398F53DB5F7AF15BE753397F592D5130F61B954FCE5C83257B35BEC7`
- Source-tree fingerprint: `5EC5807E0F02006ECC41914F91B9F2F83F9E53429D6EF3540A0AC3DC558D281F`
- Executable SHA-256: `73C42DC8F84B10F888D8BA207E53A09505EDC0D3CB479C9E07F3BB19BEE1EA3C`
