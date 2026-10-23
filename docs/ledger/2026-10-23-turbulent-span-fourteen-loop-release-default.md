# Promote the fourteen-pixel turbulent span loop to the i486 default

The fourteen-pixel turbulent-span loop is now the i486 release default. It was
compared with the checked-in twelve-pixel loop using three alternating,
uninstrumented DOSBox-X `demo1` pairs. Both variants used CWSDPMI, the full i486
selector profile, the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and the
same source-tree fingerprint
`7BAFA8C2F2521B94967F73C5D7663076DC31B934C7EBFE0E5F1C841416E2DE52`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| Twelve-pixel control | 15.606959 / 15.606960 / 15.606957 | 15.606958667 | 0.000003 |
| Fourteen-pixel loop | 15.607060 / 15.607061 / 15.607049 | 15.607056667 | 0.000012 |

The candidate gains **0.000098 FPS (+0.00062793%)**. Every candidate run exceeded
every control run. All six runs rendered 969 frames with framebuffer checksum
`1047377823`; each run enforced both parity gates. The only selector difference
between the benchmark builds was `TurbulentImplementation=twelve` versus
`TurbulentImplementation=fourteen`.

Both strict i486 ISA gates passed. The control covered 313,883 linked
instructions and the candidate covered 313,933 across 435 executable ranges.
Neither build had above-i486, unknown, exempt, or unenforced instructions. The
startup audit covered 529 instructions and the external DPMI-provider audit
covered 9,207 instructions, both with zero exemptions.

Artifacts:

- Control runs: `out/dos-timedemo-20261023-060435/`,
  `out/dos-timedemo-20261023-060712/`, and
  `out/dos-timedemo-20261023-060949/`
- Candidate runs: `out/dos-timedemo-20261023-060553/`,
  `out/dos-timedemo-20261023-060830/`, and
  `out/dos-timedemo-20261023-061106/`
- Strict control build: `out/profile-07ee78cd86bf229b/`
- Strict candidate build: `out/profile-9eea9650c5c9c4f1/`
