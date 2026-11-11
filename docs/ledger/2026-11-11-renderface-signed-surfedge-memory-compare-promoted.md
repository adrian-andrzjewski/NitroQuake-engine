# RenderFace signed-surfedge memory compare promoted (2026-11-11)

<!-- optimization-attempt: renderface-signed-surfedge-memory-compare accepted -->

## Candidate

The clipped world-edge and submodel loops in `R_RenderFace_asm486` used to
reload the signed surfedge into `%eax` and then test the register to select
vertex order. The promoted path compares the signed value in place with
`cmpl $0,-4(%esi)`. This removes the register load and test without adding a
move to the per-edge loop.

## Exact rendering and i486 compatibility

Control and candidate used Build 867, the current selectable i486 assembly
profile, and the pinned DOSBox-X 2026.08.31 486 profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). Both
used `host_framerate 0.0783` for fixed-time rendering; the `demo1` scene also
used `d_subdiv16 1`.

The `demo1` VESA replay completed 969 frames with final framebuffer checksum
`1047377823`. All 970 color records, all 970 Z records, and the captured
frame-169 PCX matched byte-for-byte:

| Artifact | SHA-256 |
| --- | --- |
| Color checksums | `E00B1C297ACCFB4C161DBB8F2448CBAF48CFABCCD3AC1DA98EBC836515B8F8CA` |
| Z checksums | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 169 PCX | `D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96` |

The demo1 image passed the committed golden tolerance with the same 12 changed
pixels on control and candidate. The alternate-world `demo2` entity replay
completed 985 frames with checksum `1887495667`; all 986 color records, all
986 Z records, event traces, and the captured frame-169 PCX matched exactly.
Both images were pixel-exact against the committed golden:

| Artifact | SHA-256 |
| --- | --- |
| Demo2 color checksums | `B252B85D83519D885CB072ECB430BCEFB56ECD7DDD102FAF051BA6D5421EB4D1` |
| Demo2 Z checksums | `C66711F7D2E177C46146852C15C1E9F0544CA3BD99471512478C17F353A794AB` |
| Demo2 frame 169 PCX | `36CFDB9731F4E66FC5B8CD882CF528ED54FD250EA2C87EA25DAEC12D08302353` |

The candidate passed the complete strict i486 gate with 316,122 relocated
instructions, 529 startup rows, and 9,207 DPMI-provider instructions; zero
instructions were above i486, unknown, or exempt. Source proofs covered 403
objects and 435 linked contributions.

## Matched timing

Three uninstrumented `demo1` runs per variant used the same profile, scene
commands, 969-frame count, and final-checksum gate:

| Variant | FPS samples | Mean FPS |
| --- | --- | ---: |
| Control | 16.931061 / 16.931061 / 16.931061 | 16.931061000 |
| Candidate | 16.937459 / 16.937457 / 16.937459 | 16.937458333 |

The candidate mean improved by **0.006397333 FPS (+0.0377846%)**. Control
spread was zero, candidate spread was 0.000002 FPS, and the trailing control
drift was -0.000001 FPS. All candidate samples exceeded all control samples.
This is DOSBox-X evidence for the pinned workload, not a physical-486 claim.

## Artifacts

- Candidate build: `D:\NitroQuake-renderface-direct-memory-cmp-20261111\out\profile-f2fae35dccd9a099\`
- Parity and timing evidence: `workspace\benchmarks\out\renderface-direct-memory-cmp-20261111\`
- The evidence directory retains both parity summaries, all timing result JSON and logs, and `candidate.patch`.
