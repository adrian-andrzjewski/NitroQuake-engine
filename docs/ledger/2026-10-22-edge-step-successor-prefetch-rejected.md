# Reject preloading the first edge-step successor

The active legacy `R_StepActiveU` candidate moved the first probe's
`et_next(%edx)` load before the order comparison. That makes the continuation
pointer available earlier on the common path but also loads it when the edge
must be pushed back. Exact checksum parity and the complete strict i486 audit
passed; the negative mean restores the original post-branch load.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the same i486 assembly selector profile, including
`EdgeListMaintenanceImplementation=legacy`. Runs were uninstrumented with
per-frame FPS collection disabled. All six runs rendered 969 frames with
checksum `1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Existing first-probe schedule | 15.600949, 15.600939, 15.600941 | 15.600943 | 0.000010 |
| Successor preload before order check | 15.600363, 15.600367, 15.600361 | 15.600363667 | 0.000006 |

The candidate loses **0.000579333 FPS (-0.00371345%)**. Every candidate
sample is slower than every control sample by at least **0.000572 FPS**, so the
negative pooled mean rejects the prefetch.

The complete strict i486 audit passed: 313,319 relocated instructions, 529
startup instructions, and 9,207 DPMI-provider instructions, with zero
above-i486 opcodes, unknown instructions, or exemptions. Exact framebuffer
checksum parity passed.

Artifacts:

- Control: `out/dos-timedemo-20261022-045301/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-061746/timedemo-result.json`
- Candidate build and ISA reports: `out/local-scan-step-first-next-prefetch-20261022/`

Source-tree fingerprints:

- Control: `35F7ECC8D782B4D2B679B956E043FC6C39971E6894DBA267D5AA4F1A279F1020`
- Candidate: `321CA3BD598F1C749A15938779D2B71832ACA5E11F92FB00AEDC21ED54AA454D`
