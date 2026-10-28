# Edge-list target-U caching promoted within replacement i486 assembly (2026-10-22)

Status: the target-U load hoists are promoted in the replacement i486 assembly
path under the any-positive pooled-mean rule. The `asm` selector remains
opt-in: its separate comparison against the `legacy` default was slower.

`R_InsertNewEdges_asm486` now loads `et_u(%ebx)` into `%edx` once before its
four-way unrolled search and compares each candidate edge against that cached
target. `R_StepActiveU_asm486` reuses the already-loaded next pointer and caches
the target U value across its reinsertion search. The control restored only
these load schedules; both variants used the same surrounding renderer source.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, the pinned 32 MB i486
profile, and the profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Selector | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---|---:|---:|
| Cached target U (strict candidate) | `asm` | `out/dos-timedemo-20261022-001256` | 15.564262 / 15.564259 / 15.564253 | 15.564258 | 0.000009 |
| Prior target-load order (parity control) | `asm` | `out/dos-timedemo-20261022-001805` | 15.554989 / 15.554981 / 15.554982 | 15.554984 | 0.000008 |

The strict pooled delta is **+0.009274 FPS (+0.0596208%)**. Every run completed
969 frames with framebuffer checksum `1047377823`. The strict candidate passed
the linked i486 audit: 313,315 instructions across 435 executable ranges, with
zero above-i486, unknown, or exempt instructions. The parity-control command
used `-VisualParityOnly` and explicitly skipped the ISA audit.

The replacement assembly path was also compared with the `legacy` selector
using three runs per variant and the same pinned profile:

| Variant | Artifact | Run FPS | Mean FPS |
|---|---|---|---:|
| Cached replacement assembly | `out/dos-timedemo-20261022-001256` | 15.564262 / 15.564259 / 15.564253 | 15.564258 |
| Legacy default | `out/dos-timedemo-20261022-002459` | 15.598457 / 15.598459 / 15.598469 | 15.598461667 |

Both selector variants retained the exact 969-frame checksum. The replacement
assembly averaged **0.034203667 FPS (0.2192759%) slower** than `legacy`, so the
build default remains `legacy`. The legacy comparison used `-VisualParityOnly`
and skipped its ISA audit; the replacement assembly candidate above has the
full strict audit result. Matched-frame visual acceptance remains open.
