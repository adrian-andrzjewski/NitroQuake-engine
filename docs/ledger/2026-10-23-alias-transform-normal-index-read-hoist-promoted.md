# Promote overlapping normal-index access in the i486 alias transform

The alias transform now reads and scales `tv_lightnormalindex` and advances
the vertex pointer immediately after loading the third coordinate. This moves
the normal-index work and pointer update into the remaining x87 transform
arithmetic while preserving the original index and vertex values.

The candidate was measured against committed control `214358b` in the same
aggressive i486 `demo1` timedemo, with
`AliasTransformFinalImplementation=asm` and the pinned 32 MB DOSBox-X profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`. The
control source-tree fingerprint was
`1215D37CC792A5F324C5D96D9FC148B6F7213DA6AFA6F3D35B866C2D62AF8D18`; the
candidate fingerprint was
`1CC7D7FBD5D0841208F3BCA0E527FDBDCB582E49EDCAB721B8896A9E2A0DB342`.

| Variant | FPS samples | Mean FPS | Spread |
|---|---|---:|---:|
| committed control | 15.626479 / 15.626519 / 15.626520 | 15.626506 | 0.000041 |
| early normal-index read and pointer advance | 15.626487 / 15.626519 / 15.626520 | 15.626508667 | 0.000033 |

The candidate mean increases by **0.000002667 FPS (+0.00001707%)**. Both
medians are 15.626519 FPS. All six runs rendered 969 frames with framebuffer
checksum `1047377823`; enforced frame and checksum parity passed.

The complete source-bound i486 gate passed: 275,596 project-object
instructions, 313,893 linked instructions, 529 startup code rows, and 9,207
DPMI-provider instructions, with zero above-i486, unknown, or exempt
instructions. Final source mapping passed for 435 contributions.

Artifacts:

- Candidate build: `out/local-local-alias-transform-normal-index-read-hoist-20261023/`
- Candidate timedemo: `out/dos-timedemo-20261023-154418/`
- Committed control timedemo: `out/dos-timedemo-20261023-151853/`
