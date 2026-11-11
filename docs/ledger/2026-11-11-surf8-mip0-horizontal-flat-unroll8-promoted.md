# Mip-0 horizontal-flat surface rows unrolled eight at a time promoted (2026-11-11)

## Candidate

LSurf8Mip0HorizontalFlat now emits eight row bodies per loop iteration. The
16 output rows therefore use two counter iterations instead of four. The
texture, destination, and row-step update order stays unchanged. Rows E through
H add 64 lookup patch sites; LPatchTable8 now registers 128 copied sites and
R_Surf8Patch includes 144 entries.

This changes the already-selected i486 assembly path. It adds no selector or
runtime policy.

## Strict i486 gate

The Build 870 candidate passed the complete source-bound i486 audit. The
profile executable SHA-256 is
1C048CD648E5E7D7C15A4332A350D382892A2F33CAA1BF7B0E7C90E2EF6B6C97.
The audit verified 324,320 linked instructions, 529 startup instructions, and
9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions.

The uninstrumented candidate qbench SHA-256 is
76BAAF832A81A3CA6CD8010AAD6C82B23284E8167D9E8345F043AA387CCC196D.
Its source-tree fingerprint is
7921548FCDB5F5B1215C691BE8DF0939FC1A55DB151049C946AB44F8953C60C2.

## Exact rendering parity

The candidate passed the committed demo1-vesa-full golden check with its
established 12-pixel tolerance and the demo3-world-workload check with zero
changed pixels. Control and candidate frame-169 demo1 PCX captures were
byte-identical with SHA-256
D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96.
The demo3 PCX captures were byte-identical with SHA-256
6A446E35A1A30487526B189C1750652BEFB9AF721DAFD798E4AD14F05FD713B0.

Every control/candidate color stream matched exactly. The demo1 stream contains
970 records; the demo3 stream contains 1,091. All paired Z-checksum files also
matched byte-for-byte: demo1 SHA-256
1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8 and
demo3 SHA-256
23CBA0BA44B9E609BD269F3ACC78C72CED609B4708E5C0565A2ACF3DF90DF83E.
The per-run records are in z-parity.json.

## Matched timing

Three alternating, uninstrumented pairs per scene used DOSBox-X 2026.08.31,
the pinned profile
532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA, identical
renderer settings and game data, and the established timed-frame and final
checksum gates. No frame-checksum instrumentation was enabled during timing.

| Scene | Pair | Control seconds / FPS | Candidate seconds / FPS | Candidate lead |
| --- | ---: | ---: | ---: | ---: |
| demo1 | 1 | 57.209144 / 16.937852 | 57.208952 / 16.937909 | 0.192 ms |
| demo1 | 2 | 57.209135 / 16.937854 | 57.208948 / 16.937909 | 0.187 ms |
| demo1 | 3 | 57.209140 / 16.937853 | 57.208950 / 16.937909 | 0.190 ms |
| demo3 | 1 | 68.609211 / 15.887079 | 68.608976 / 15.887134 | 0.235 ms |
| demo3 | 2 | 68.609223 / 15.887077 | 68.608972 / 15.887135 | 0.251 ms |
| demo3 | 3 | 68.609212 / 15.887079 | 68.609000 / 15.887128 | 0.212 ms |

The demo1 mean rose from 16.937853000 to 16.937909000 FPS
(+0.000056000 FPS, +0.0003315%). The demo3 mean rose from 15.887078333 to
15.887132333 FPS (+0.000054000 FPS, +0.0003391%). Every candidate sample
was faster than every control sample in its scene. The positive pooled means
meet the current acceptance rule. These are pinned DOSBox-X results, not
physical-486 performance claims.

## Artifacts and scope

- Candidate render validation:
  workspace\benchmarks\out\surf8-mip0-flat-unroll8-candidate-render-validation-dataroot-20261111\render-validation-result.json
- Control render validation:
  workspace\benchmarks\out\surf8-mip0-flat-unroll8-control-render-validation-20261111\render-validation-result.json
- Color and Z parity evidence:
  workspace\benchmarks\out\surf8-mip0-flat-unroll8-exact-parity-20261111\
- Matched timing results:
  workspace\benchmarks\out\surf8-mip0-flat-unroll8-timing-uninstrumented-20261111\
- Control qbench SHA-256:
  79287CAC7A61948E40723FFCBD07DBA3DDFB4C38574A2CFCCACD8BA574366C62
- Candidate worktree:
  D:\NitroQuake-surf8-mip0-flat-unroll8-20261111
