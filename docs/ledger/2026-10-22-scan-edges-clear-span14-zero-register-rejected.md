# Reject zero-register stores in the fourteen-span `R_ScanEdges` clear loop

The fourteen-span clear loop was tested with `ECX` zeroed once per batch and
reused as the source for its fourteen surface-field stores. The candidate
preserved the output and passed the strict i486 audit, but its mean FPS was
below the immediate-store control. The any-positive rule rejects it; the
immediate stores remain active.

## Matched timedemo

Both variants used the pinned DOSBox-X profile
`out/dosbox-x-486-high-32m-baseline.conf`
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, the same i486 assembly selector profile, and three uninstrumented
timedemo runs. Every run rendered 969 frames with framebuffer checksum
`1047377823`.

| Variant | FPS samples | Mean | Spread |
|---|---|---:|---:|
| Immediate-store control | 15.601288, 15.601300, 15.601296 | 15.601294667 | 0.000012 |
| Zero-register candidate | 15.601274, 15.601279, 15.601290 | 15.601281 | 0.000016 |

The candidate delta is **−0.000013667 FPS (−0.00008759%)**. The candidate
samples overlap the control samples, but the negative mean does not qualify.

The complete strict i486 audit passed: 313,365 relocated instructions, 529
startup rows, and 9,207 DPMI-provider instructions, with zero above-i486
opcodes, unknown instructions, or exemptions. The final executable audit
verified all 313,365 instructions across 2,376 code ranges and 35 data ranges.
All three timedemos retained exact checksum parity.

Artifacts:

- Control: `out/dos-timedemo-20261022-134214/timedemo-result.json`
- Candidate: `out/dos-timedemo-20261022-152803/timedemo-result.json`
- Candidate build and ISA reports: `out/local-local-scan-edges-clear-span14-zero-register-20261022/`

Candidate fingerprints:

- Build source fingerprint: `1746623603BAC755E752309512D74F422F5C2F1ADD4B25FB9AA9395A071A73DC`
- Source-tree fingerprint: `91556A65005CF1E1E03B961728A06480D84634EB3EAE6C74CA7A42B8A91E82CD`
- Executable SHA-256: `2A4C930B3DB142C99CBAD9E67FCE6AE01E3C8F5F23DA6289BCC6402A09C9755D`
