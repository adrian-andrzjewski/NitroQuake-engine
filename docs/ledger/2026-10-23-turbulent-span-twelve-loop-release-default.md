# Promote the twelve-pixel turbulent span loop to the i486 default

The twelve-pixel turbulent-span loop is now the i486 release default. It was
compared with the checked-in eight-pixel (`octa`) loop using three alternating,
uninstrumented DOSBox-X `demo1` pairs. Both variants used CWSDPMI, the full i486
selector profile, the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and the
same source-tree fingerprint
`98C6A1AF353E8F91B595B96FEAD8AFBD052FD130AE562B75E949717F1C1D4DD8`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| Eight-pixel `octa` control | 15.606222 / 15.606195 / 15.606198 | 15.606205 | 0.000027 |
| Twelve-pixel loop | 15.606965 / 15.606946 / 15.606966 | 15.606959 | 0.000020 |

The candidate gains **0.000754 FPS (+0.00483141%)**. Every candidate run exceeded
every control run. All six runs rendered 969 frames with framebuffer checksum
`1047377823`; each run enforced both parity gates. The only selector difference
between the benchmark builds was `TurbulentImplementation=octa` versus
`TurbulentImplementation=twelve`.

Both strict i486 ISA gates passed. The control covered 313,623 linked
instructions and the candidate covered 313,883 across 435 executable ranges.
Neither build had above-i486, unknown, exempt, or unenforced instructions. The
startup audit covered 529 instructions and the external DPMI-provider audit
covered 9,207 instructions, both with zero exemptions.

Artifacts:

- Control runs: `out/dos-timedemo-20261023-051527/`,
  `out/dos-timedemo-20261023-051811/`, and
  `out/dos-timedemo-20261023-052047/`
- Candidate runs: `out/dos-timedemo-20261023-051652/`,
  `out/dos-timedemo-20261023-051928/`, and
  `out/dos-timedemo-20261023-052205/`
- Strict control build: `out/profile-4c7cfb0c1bb71b71/`
- Strict candidate build: `out/profile-07ee78cd86bf229b/`
