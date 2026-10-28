# Nonnegative subtract-pair Z-span STOSL store (2026-10-28)

Status: promoted after a positive strict three-run mean, exact framebuffer
parity, and the complete strict i486 ISA gate.

## Change

In `ZSPAN_SUB_PAIR_NONNEGATIVE`, use `stosl` for the i486 path instead of
`movl %eax,(%edi)` followed by `leal 4(%edi),%edi`. Keep the original
store-plus-increment sequence under `TARGET_I386`.

## Timedemo

Control and candidate used `demo1`, DOSBox-X 2026.08.31, the aggressive
optimization profile, canonical `testdata/id1`, and pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.
All runs completed 969 frames and matched the enforced framebuffer checksum
`1047377823`.

| Variant | Artifact | FPS samples | Mean FPS | Median FPS |
| --- | --- | --- | ---: | ---: |
| Control | `out/dos-timedemo-20261028-070056/timedemo-result.json` | 16.238082 / 16.238076 / 16.238082 | 16.238080000 | 16.238082 |
| Nonnegative subtract-pair STOSL | `out/dos-timedemo-20261028-081215/timedemo-result.json` | 16.238097 / 16.238081 / 16.238103 | 16.238093667 | 16.238097 |

The candidate gained **0.000013667 FPS (+0.0000841%) by mean**. The gain is
smaller than the observed run spread; the project promotion rule accepts any
positive mean from at least three matched uninstrumented runs.

## i486 audit

The strict source-bound ISA audit passed with zero above-i486, unknown, or
exempt instructions: 314,214 relocated instruction sites, 529 startup
instructions, and 9,207 DPMI provider instructions. The audit was built from
source commit `a77fce722f57803d14db322e9b671aefb4d504c1`.

Candidate source fingerprint: `F1BCB422006E72387049E220D425847171C75DEE403B9882F7D96FA19AFD83CB`.
Candidate source-tree fingerprint: `736D371FC4D85D0881822BBBA599C5792C98E326DF3C1F17D50B424C7051DF4B`.
Candidate executable SHA-256: `3E82D8E68A5DD6B5B1DB69135CAC23E1B849382D8EC90E2C051BA90396098BBE`.

The strict build manifest is `out/local-zspan-sub-nonnegative-stosl-20261028/build-manifest-bench.json`.
