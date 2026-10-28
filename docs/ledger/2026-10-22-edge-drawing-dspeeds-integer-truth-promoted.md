# Promote the edge-drawing integer float-truth check

The local `R_EdgeDrawing_asm486` helper that tests `r_dspeeds.value` now uses
integer operations instead of the x87 `FTST`/status-word sequence. Masking the
sign bit makes both positive and negative zero false; every nonzero binary32
value, including NaN, remains true as in the C truth test. The helper returns
the same zero-or-one value and no longer uses the x87 stack.

## Matched timedemo

The control and candidate used the same pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, and the i486 assembly selector profile. Both runs were uninstrumented
with per-frame FPS collection disabled. The candidate and control each rendered
969 frames with checksum `1047377823` on all three runs.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| x87 helper control | 15.598456, 15.598468, 15.598469 | 15.598464333 | 0.000013 |
| integer truth test | 15.598612, 15.598642, 15.598645 | 15.598633 | 0.000033 |

The candidate gains **+0.000168667 FPS (+0.00108130%)**. Every candidate
sample also exceeds every control sample. This positive mean qualifies under the
any-positive promotion rule.

The candidate passed the full linked strict i486 audit: 313,321 relocated
opcodes, 529 startup instructions, and 9,207 DPMI-provider instructions, with
zero above-i486 opcodes, unknown opcodes, or exemptions. The framebuffer
checksum and timedemo gates passed. The selector was already
`EdgeDrawingImplementation=asm`; this change promotes the helper schedule and
does not change selector routing. Full live-frame visual acceptance for the
edge-drawing assembly path remains pending.

Artifacts:

- Control: `out/dos-timedemo-20261022-023110/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-030124/timedemo-result.json`
- Candidate build and ISA reports: `out/local-dos-timedemo-dspeeds-int-20261022/`

Source-tree fingerprints:

- Control: `DB27F40690187D296BAB82BCB2BACFDB10BA309F34B3E5054BC7E22FE5E30689`
- Candidate: `D020C6C230DC26ACBDD1DC0676AD47D76CBFDA7B4374FDCCA81FF09E0D020575`
