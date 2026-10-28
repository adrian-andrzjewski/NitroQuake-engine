# Promote caching the scan surface base in `EDI`

`R_ScanEdges_asm486` now loads `surfaces` once into `EDI`, using it for the
per-row `st_spanstate` store and for span-list clearing after a flush. The
exclusive row limit (`vrectbottom - 1`) moves to the local slot `-32(%ebp)` so
`EDI` can hold the surface base. The row loop no longer reloads `C(surfaces)`;
the callback remains cached in `ESI`, and the aligned span base remains in
`-28(%ebp)` for flush resets.

## Matched timedemo

The control and candidate used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the same i486 assembly selector profile. Both were uninstrumented
with per-frame FPS collection disabled. All six runs rendered 969 frames with
checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Cached callback control | 15.599831, 15.599815, 15.599823 | 15.599823 | 0.000016 |
| Cached surface base in `EDI` | 15.600949, 15.600939, 15.600941 | 15.600943 | 0.000010 |

The candidate gains **+0.001120 FPS (+0.00717957%)**. Every candidate sample
exceeds every control sample by at least **0.001108 FPS**, qualifying under the
any-positive promotion rule.

The full strict linked i486 audit passed: 313,319 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed. `ScanEdgesImplementation=asm` was already selected in
the i486 profile, so selector routing is unchanged. Full live-frame visual
acceptance for the scan-edge assembly path remains pending.

Artifacts:

- Control: `out/dos-timedemo-20261022-042420/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate build and ISA reports: `out/local-scan-surface-base-cache-20261022/`

Source-tree fingerprints:

- Control: `202E705EF2E2F52A392F76BCDDCD597D14C2FAD656506AB0B542A10A5DF5EAB7`
- Candidate: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
