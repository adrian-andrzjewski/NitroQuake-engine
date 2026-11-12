# Mip-0 horizontal-flat surface rows fully unrolled (2026-11-12)

## Candidate

`LSurf8Mip0HorizontalFlat` now emits all sixteen row bodies in one straight-line
sequence. This removes the two-iteration counter loop left by the promoted
eight-row body. Texture, destination, and row-step updates retain their order.
The patch table adds sixteen horizontal-flat rows (I through P), and
`R_Surf8Patch` accounts for 512 sites. The change is limited to `src/surf8.s`
and continues to use the already-selected i486 assembly path.

The candidate was based on `0e68112d414c0d06910a624e990cd65e74f131fe`. The
parent and candidate source-tree fingerprints were respectively
`4E3011371D2DD100969C0C124B19F0DC370FAC55B68F60CE2ADB6496858EAF5C` and
`444527EFABCC5D7882F08C058651B2F927F173EE85297E72C3CB063774AD7FEA`.

## Strict i486 gates

The Build 875 benchmark executable passed the complete strict i486 gate:
317,412 linked instructions, 529 startup rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. Its SHA-256 is
`1175EBC007C2684405154CABE4985C133719D481E1ED96732614FCD078CE79DB`.

The fresh release build also passed the complete strict i486 gate. It verified
164,998 linked instructions, 529 startup rows, and 9,207 provider instructions,
with zero above-i486, unknown, or exempt instructions. The release executable
SHA-256 is
`CEA74965EE44F54B5EA6B1CF1ACDF327E19FB0B1711DAE1ACF67EA48EFCD4199`.

## Exact rendering parity

Control and candidate used DOSBox-X 2026.08.31 and the pinned profile
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

For demo1, the fixed-clock commands were `host_framerate 0.0783` and
`d_subdiv16 1`. Both runs passed the 969-frame and `1047377823` final checksum
gates. All 970 color records and all 970 Z records matched byte-for-byte; the
exact color comparator confirmed zero differences across the 964 compared
frames after six startup frames. The frame-169 PCX files were byte-identical
with SHA-256
`D63788DE7D75959CC45A0ACFEA50DE772A03145D9788D23AB7431FD068594F96`. The raw
color checksum files share SHA-256
`E00B1C297ACCFB4C161DBB8F2448CBAF48CFABCCD3AC1DA98EBC836515B8F8CA`; the raw
Z checksum files share SHA-256
`1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8`.

For demo3, `-parityclock` was enabled with `-zchecksums` so presentation time
stayed deterministic during the per-frame depth scan. Both runs passed the
1,090-frame and `2316550348` final checksum gates. All 1,091 color and Z records
matched byte-for-byte; exact comparators confirmed zero differences across the
1,085 compared frames after six startup frames. The frame-169 PCX files were
byte-identical with SHA-256
`6A446E35A1A30487526B189C1750652BEFB9AF721DAFD798E4AD14F05FD713B0`. The raw
color checksum files share SHA-256
`2ED0BB1F4EA7E51E33EEC82176EB8802C365BEC85016D7AF898A5F479735E1DF`; the raw
Z checksum files share SHA-256
`23CBA0BA44B9E609BD269F3ACC78C72CED609B4708E5C0565A2ACF3DF90DF83E`.

## Matched timing

Three alternating, uninstrumented demo1 pairs used the same data, renderer
settings, expected frame and framebuffer checksums, and pinned DOSBox-X
profile. No per-frame color or Z checksum instrumentation was enabled during
timing.

| Pair | Control seconds / FPS | Candidate seconds / FPS | Candidate lead |
| --- | ---: | ---: | ---: |
| 1 | 57.200634 / 16.940372 | 57.200358 / 16.940453 | 0.276 ms |
| 2 | 57.200633 / 16.940372 | 57.200369 / 16.940451 | 0.264 ms |
| 3 | 57.200624 / 16.940375 | 57.200365 / 16.940452 | 0.259 ms |

The mean rose from 16.940373 to 16.940452 FPS: `+0.000079 FPS` (`+0.0004656%`).
Every candidate sample beat its matched control. This is a small DOSBox-X
result under the project's positive three-pair rule, not a physical-486
performance claim.

## Artifacts and scope

- Parity reports and handoffs:
  `workspace\benchmarks\out\surf8-mip0-horizontal-flat-unroll16-20261112\`
- The raw DOSBox-X run directories are under
  `workspace\benchmarks\out\dos-timedemo-20261112-034315\`,
  `...-034627\`, `...-035724\`, and `...-035953\`; timing handoffs name each
  separate timing run.
- Control qbench SHA-256:
  `2605BF2DB53790BBFB99749B826908FCE6F3698562A97104F7849BE6103A772C`
- Candidate qbench SHA-256:
  `1175EBC007C2684405154CABE4985C133719D481E1ED96732614FCD078CE79DB`
- Release executable:
  `D:\NitroQuake-surf8-mip0-horizontal-flat-unroll16-20261112\out\local-surf8-mip0-horizontal-flat16-release-20261112\quake.exe`
- `tools/run-tests.ps1 -HostOnly`: 7 passed and 5 failed. The failures were
  stale ledger entry counts, renderer-profile/build-selector expectations,
  source assertions in `test-sysinfo-dos.py`, and missing host `gcc` for
  `test-video-dos.py`; no test or build scripts changed in this promotion.
