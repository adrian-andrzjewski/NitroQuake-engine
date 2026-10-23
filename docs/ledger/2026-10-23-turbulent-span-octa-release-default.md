# Promote the eight-pixel turbulent span loop to the i486 default

The `octa` turbulent loop is now the i486 release default. This direct matched
comparison used the full current i486 selector profile and changed only
`TurbulentImplementation` from the prior `asm` default to `octa`. Both builds
used the same source-tree fingerprint
`24DCC8B22ECC8B453D358BE1782432A3CC96311287F59EDA8C3BF21B34C82477`, the same
pinned DOSBox-X profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, the same
32 MB 486 profile, `demo1`, and CWSDPMI host. All runs were uninstrumented.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| Previous `asm` default | 15.591670 / 15.591667 / 15.591677 | 15.591671333 | 0.000010 |
| Eight-pixel `octa` loop | 15.606222 / 15.606198 / 15.606199 | 15.606206333 | 0.000024 |

The `octa` loop gains **0.014535 FPS (+0.09322285%)**. Every candidate run
exceeded every control run. All six runs completed 969 frames with framebuffer
checksum `1047377823`; each result enforced the pinned checksum and passed its
strict i486 build gate. The control and candidate manifests had exactly one
selector difference: `TurbulentImplementation=asm` versus `octa`.

The control executable audit passed for 313,304 linked instructions across 435
code ranges. The `octa` executable audit passed for 313,623 linked instructions
across 435 code ranges. Both audits found zero above-i486, unknown, exempt, or
unenforced instructions. Startup and external DPMI-provider proofs passed with
zero exemptions; the provider audit covered 9,207 instructions.

Artifacts:

- `asm` control runs: `out/dos-timedemo-20261023-022048/`,
  `out/dos-timedemo-20261023-022400/`, and
  `out/dos-timedemo-20261023-022635/`
- `octa` candidate runs: `out/dos-timedemo-20261023-022235/`,
  `out/dos-timedemo-20261023-022517/`, and
  `out/dos-timedemo-20261023-022752/`
- Strict control build: `out/local-local-turbulent-default-asm-control-strict-20261023/`
- Strict `octa` build: `out/local-local-turbulent-octa-strict-20261023/`
