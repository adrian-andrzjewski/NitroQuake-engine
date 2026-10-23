# Promote the alias T-coordinate copy after reciprocal division

The loop now starts `fdivrs Lfloat_1` before loading `stv_t` and storing it to
`fv_v+12`. The integer copy is independent of the reciprocal result, so the
486 can execute it while the x87 computes inverse depth. Transform arithmetic
and the output values are unchanged.

The candidate was measured against committed control `26cb873` in the same
aggressive i486 `demo1` timedemo, with
`AliasTransformFinalImplementation=asm` and the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`1CC7D7FBD5D0841208F3BCA0E527FDBDCB582E49EDCAB721B8896A9E2A0DB342`; the
candidate fingerprint was
`698D0B85BF0C5FFDEC9DAB65FB769A17E068C30F1F5B2210E6C49CC35A1FF7AF`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.626487 / 15.626519 / 15.626520 | 15.626508667 | 0.000033 |
| T-coordinate copy after `fdivrs` | 15.626491 / 15.626519 / 15.626519 | 15.626509667 | 0.000028 |

The candidate mean increases by **0.000001 FPS (+0.00000640%)**. Both medians
are 15.626519 FPS. All six runs rendered 969 frames with framebuffer checksum
`1047377823`; enforced frame and checksum parity passed.

The complete source-bound i486 gate passed: 275,596 project-object
instructions, 313,893 linked instructions, 529 startup code rows, and 9,207
DPMI-provider instructions, with zero above-i486, unknown, or exempt
instructions. Final source mapping passed for 435 contributions.

Artifacts:

- Candidate build: `out/local-alias-tcoord-t-after-fdivrs-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-170514/`
- Committed control timedemo: `out/dos-timedemo-20261023-154418/`
