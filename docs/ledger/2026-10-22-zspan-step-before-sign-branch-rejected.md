# Reject advancing the Z accumulator before the sign branch (2026-10-22)

The candidate moved the first accumulator add/subtract in each
`ZSPAN_ADD_PAIR` / `ZSPAN_SUB_PAIR` macro ahead of its sign test. The negative
handler then packed the already-advanced sample and applied the second step.
This preserved the per-pixel recurrence and framebuffer output, but its strict
mean FPS was lower than control. The original `TEST`, branch, then add/subtract
order remains active in `src/renderer/d_draw.s`.

Both variants used the same uninstrumented DOSBox-X `demo1` timedemo, CWSDPMI,
and pinned 32 MB i486 profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
control and candidate each ran three times; one trailing control sample checked
for drift. All runs rendered 969 frames with framebuffer checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Control | 15.601307, 15.601300, 15.601302 | 15.601303 | 0.000007 |
| Candidate | 15.601292, 15.601295, 15.601280 | 15.601289 | 0.000015 |
| Trailing control | 15.601297 | — | — |

The candidate delta is **−0.000014 FPS (−0.00008974%)**. The trailing sample
was **−0.000005 FPS** from the control median, and the candidate remained
**−0.000008 FPS** below that trailing sample. Under the any-positive pooled-mean
rule, the negative strict mean rejects this candidate.

The complete strict i486 audit passed: 313,342 relocated instructions across
435 executable ranges, 529 startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. Final source mapping
covered 2,376 CODE ranges and 35 DATA ranges. All seven timedemo runs retained
exact frame and checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-155952/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-162901/timedemo-result.json`
- Trailing control: `out/dos-timedemo-20261022-163316/timedemo-result.json`
- Candidate build and ISA reports: `out/local-zspan-sign-step-before-branch-20261022/`

Candidate fingerprints:

- Build source fingerprint: `4011DCF53E018872B5B991145B9BC56F65E40982E1591A50F14EC2519C1687E9`
- Source-tree fingerprint: `DD50D92339E3C1B682BF060F8B105D74C0177D18DC3C4C00B2F9B98BFC8798EB`
- Executable SHA-256: `247E5A3CA2E9F56E6BB770B166C3EFCA554308517D3277DE6DC10CF37905A653`
