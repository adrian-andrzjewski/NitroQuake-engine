# Span16 T-step/store overlap extension rejected (2026-10-21)

Status: rejected in `src/renderer/d_draw16.s`; the earlier first-store T-step overlap
remains active.

The existing first-store schedule was extended by moving five additional
T-step additions before interior word stores in the A and B halves. The word
stores and following byte loads preserve the carry for the subsequent `sbb`,
and the timedemo retained exact output parity. The positive parity-screen mean
did not carry through to the matched strict mean, so the five added moves were
restored.

All runs used DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the pinned 32 MB i486
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

| Variant | Artifact | Run FPS | Mean FPS | Spread |
|---|---|---|---:|---:|
| Active control, parity screen | `out/dos-timedemo-20261021-201411` | 15.564258 / 15.564243 / 15.564254 | 15.564251667 | 0.000015 |
| Extended candidate, parity screen | `out/dos-timedemo-20261021-204349` | 15.564258 / 15.564247 / 15.564261 | 15.564255333 | 0.000014 |
| Active control, strict | `out/dos-timedemo-20261021-203820` | 15.564263 / 15.564259 / 15.564259 | 15.564260333 | 0.000004 |
| Extended candidate, strict | `out/dos-timedemo-20261021-210735` | 15.564256 / 15.564268 / 15.564245 | 15.564256333 | 0.000023 |

The parity-screen delta was **+0.000003667 FPS**, but the strict mean was
**−0.000004000 FPS (−0.00002570%)** against the active control. Every run
completed 969 frames with checksum `1047377823`. The strict candidate passed
the complete i486 audit: 313,315 relocated instructions across 435 executable
ranges, 529 startup code rows, and 9,207 provider instructions, with zero
above-i486, unknown, or exempt instructions. The negative strict mean rejects
the extension; the first-store T-step overlap remains promoted.

The audited extended candidate executable SHA-256 is
`13ABDB74E7DA6708993395111C3F9FEBD47BC403503F31A8759AB5F7227F0F92`; its
source fingerprint is
`A199074E0AD6345F9F07B5B4F02D0C26AFE2BE6D72B9159183869BB0D049221C` and its
source-tree fingerprint is
`0972AE652DF9E4DE09BFD8533F50900D3F7A977B9FC6921EBECE6FB33F0FCE8F`.
