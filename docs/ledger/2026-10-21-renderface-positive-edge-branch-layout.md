# RenderFace positive-edge branch layout (2026-10-21)

Status: promoted in the working assembly source.

Both regular and submodel surfedge loops in `R_RenderFace_asm486` now make the
positive-edge branch the taken path. Negative and zero values fall through to
the existing magnitude/address calculation. This changes branch layout while
preserving the edge address, cache checks, and clipping behavior.

The candidate was measured with DOSBox-X 2026.08.31, `demo1`, CWSDPMI, and the
pinned 32 MB i486 profile `out/dosbox-x-486-high-32m-baseline.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`). The
parity-only screen in `out/dos-timedemo-20261020-222216/timedemo-result.json`
averaged **15.537298667 FPS** (15.537303 / 15.537300 / 15.537293). All three
runs completed 969 frames and reported the expected framebuffer checksum
`1047377823`.

The strict result is
`out/dos-timedemo-20261020-224647/timedemo-result.json`. Against the preceding
promoted source in `out/dos-timedemo-20261020-213827/timedemo-result.json`, the
strict mean rose from **15.536974667 FPS** to **15.537297333 FPS**:
**+0.000322667 FPS (+0.0020768%)**. Candidate samples were 15.537300 / 15.537292
/ 15.537300 FPS; every sample exceeded every baseline sample (15.536943 /
15.536991 / 15.536990). All runs retained the enforced 969-frame checksum.

The full linked i486 audit passed: 313,316 relocated instructions across 435
executable ranges, 529 startup code rows, and 9,207 DPMI-provider instructions.
It found zero above-i486, unknown, non-instruction, or exempted bytes. The
source-bound map covered 435 contributions, 2,377 CODE ranges, and 35 DATA
ranges. The result records `isaAuditStatus=PASS` and source-tree fingerprint
`E40384B12F44BE9F7540DE10198DC26E5E9D84510E60D965636DF48981AE3F19`.

This repeatable positive gain qualifies under the no-minimum-gain policy.
