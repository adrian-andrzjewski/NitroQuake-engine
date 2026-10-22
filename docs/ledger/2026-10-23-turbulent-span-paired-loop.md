# Promote the paired-pixel turbulent span loop

The opt-in `pair` implementation processes two turbulent texture pixels per
loop branch and retains a single-pixel odd tail. Its matched strict `demo1`
mean is positive against the ASM control, with exact framebuffer checksum
parity. The improvement is small but clears the positive-mean promotion rule.
The aggressive i486 profile remains on `TurbulentImplementation: asm`; the
paired loop is selectable with `-TurbulentImplementation pair`.

## Matched timedemo

Both variants used the aggressive 32 MB 486 profile, `demo1`, and identical
implementation selectors except for `TurbulentImplementation` (`pair` versus
`asm`). Each uninstrumented run rendered 969 frames and produced framebuffer
checksum `1047377823`. Both runs reported the same profile SHA256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` and
source-tree fingerprint
`4F2CA2B28D23DE7AEF837DFD919F4006AB4EC6F5AD86E8462D010F4572BE87AE`.

| Variant | FPS samples | Mean FPS |
|---|---|---:|
| ASM control | 15.591165, 15.591674, 15.591661 | 15.591500 |
| Paired loop | 15.601304, 15.601297, 15.601298 | 15.601299667 |

The paired loop gains **0.009799667 FPS (+0.0629%)** over the matched ASM mean.
All six runs retained exact 969-frame checksum parity.

## Direct span fixture

The direct turbulent-span fixture passed correctness against C at widths 4,
8, 16, and 64 pixels. Its median timings were:

| Pixels | C seconds | ASM seconds | Pair seconds | Pair vs C | Pair vs ASM |
|---:|---:|---:|---:|---:|---:|
| 4 | 0.225776 | 0.183916 | 0.185405 | +17.881% | -0.803% |
| 8 | 0.423142 | 0.327449 | 0.322964 | +23.675% | +1.389% |
| 16 | 0.817866 | 0.614521 | 0.598076 | +26.874% | +2.750% |
| 64 | 3.186220 | 2.336959 | 2.248747 | +29.423% | +3.923% |

The four-pixel case is slightly slower than ASM control, while the wider spans
improve. The full-scene matched mean remains positive.

## Strict i486 validation

The pair build passed the complete executable ISA gate: 313,376 linked
instructions, 529 startup CODE rows, and 9,207 DPMI-provider instructions,
with zero above-i486 opcodes, unknown instructions, or exemptions. The
project-object audit covered 168 objects and 275,079 instructions; the final
source mapping covered 435 source-bound contributions, 2,376 CODE ranges, and
35 DATA ranges. Startup and provider helper audits passed. The pair selector
was the only implementation difference from the ASM timedemo control.

The repository-wide `tools/test-build-dos.py` integration suite was not
completed during this experiment.

Artifacts:

- Pair timedemo: `out/dos-timedemo-20261022-224942/timedemo-result.json`
- ASM control: `out/dos-timedemo-20261022-225358/timedemo-result.json`
- Pair direct fixture: `out/dos-microbench-pair-32m-20261023/quake/bench486.txt`
- ASM direct fixture: `out/dos-microbench-control-32m-20261023/quake/BENCH486.TXT`
- Pair build and ISA reports: `out/profile-4a2ba1f65a5ed652/`
- Linked ISA report: `out/profile-4a2ba1f65a5ed652/isa-qbench/isa-audit-linked.json`

Candidate executable SHA256:
`89402233DF86A103327288A6E00BD04BBCC66B0CC4620C5B577C2B29F6EDCB0A`.
