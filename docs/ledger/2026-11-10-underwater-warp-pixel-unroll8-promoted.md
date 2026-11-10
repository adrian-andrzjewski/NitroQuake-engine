# Underwater warp pixel loop unrolled to eight pixels (2026-11-10)

## Candidate

`D_WarpPixels_asm486` now copies eight pixels per loop iteration instead of
four. It halves the four-pixel group count and uses an odd four-pixel tail at
the start of each row, preserving left-to-right stores and the original pixel
mapping. The experiment targets the underwater warp path; the 2026-11-10
`demo2` detailed profile attributed 1.877079 seconds (3.13%) to 210 warp
calls. That instrumented profile ranked the path but is not timing evidence.

The control is nested repository revision `2a2448a`. After normalizing line
endings, the candidate differs only in `src/asm486_experiments.s`; the promoted
file has the same assembly lines. The run artifacts report source fingerprints
`5B25DC782817314DEBB975F7EC01C3682BEDCFCB202113FD792C896453E47512` for the
control and `ABE5CC7D45185369C2CEAE3AB4D4C814AB3FEC527586AB774760C73ED1FF33CD`
for the candidate. Their source-tree fingerprints are
`5555126FDDD71C350EB9ED7AA077042C8EA9E12610EDAC91EB9E8A39289666A5` and
`24BEA536AE0D013F15B5B0E35EA795161A7E8EFA82165DA603C070C3A6CE425E`,
respectively. These hashes identify the trial worktrees, including their line
endings.

## Output parity

The fixed-clock `demo2` control and candidate each completed 985 timed frames
and ended at framebuffer checksum `1887495667`. Both produced 986 color rows
with zero overflow and 986 Z rows. Color and Z streams matched byte for byte;
frame 984's 320-by-200 PCX also matched.

| Evidence | SHA-256 |
| --- | --- |
| Color checksum stream | `8ECE67E9B58CD3ED9281B5AC5B1473714C5D0351429CED3E3EB0163DD218DB52` |
| Z checksum stream | `CD43EA9D321A0761966AA40505134388C5996C1778DE2F13F4681DCA543E30A8` |
| Captured frame PCX | `AD1CE8DCEE8C1D4E43A82ED646B156F4A3939A42DD8FBD7282192348DC789DD9` |

## Strict i486 audit

The candidate passed the complete strict i486 gate: 316,344 linked
instructions, 529 DOS startup rows, and 9,207 DPMI-provider instructions,
with zero above-i486, unknown, or exempt instructions. The assembly ISA audit,
168-object source proof, 403-object runtime source proof, and final source
mapping (435 source-bound contributions, 2,389 code ranges, 35 data ranges)
passed.

## Matched release timing

Three alternating uninstrumented pairs used DOSBox-X 2026.08.31, the pinned
`demo2` workload, an i486 profile at VGA 320-by-200, 985 timed frames, and the
same framebuffer checksum. The profile SHA-256 is
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`; the
DOSBox-X executable SHA-256 is
`F17F47DFD6DA895747ACFC70A533077D0B4C55B3A8B79551A04750E2A51B8D34`. Timing
runs disabled instrumentation, frame checksums, and FPS statistics.

| Pair | Control FPS | Candidate FPS |
| ---: | ---: | ---: |
| 1 | 17.185945 | 17.241287 |
| 2 | 17.185962 | 17.241245 |
| 3 | 17.185947 | 17.241279 |
| Mean | 17.185951333 | 17.241270333 |

The candidate mean is **0.321885% faster**. All three paired results are
positive. This is a DOSBox-X result for the `demo2` workload; it does not
establish performance on a physical 486 or overall gameplay frame pacing.

## Evidence and decision

Promote the eight-pixel copy loop after exact output parity, the complete strict
i486 audit, and a positive three-pair uninstrumented mean. Workspace-relative
parity artifacts, six timing JSON files, and their logs are retained under
`benchmarks/out/warp-pixel-unroll8-*20261110.*`. The candidate executable and
audit records remain under
`quake/out/worktree-warp-pixel-unroll8-20261110/out/local-warp-pixel-unroll8-20261110/`.
