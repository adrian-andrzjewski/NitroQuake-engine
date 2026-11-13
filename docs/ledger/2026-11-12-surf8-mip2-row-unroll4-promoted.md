# Mip-2 surface rows unrolled four at a time promoted (2026-11-12)

## Change

`R_DrawSurfaceBlock8_mip2`'s carry-controlled row body always emits four rows:
the accumulator starts with high nibble `0x3`, and each row adds the `0xF`
high-nibble step. The row body is now expanded four times, removing the
per-row carry branch while preserving the texel, light, and pointer update
order. Each row has four distinct colormap patch sites; `R_Surf8Patch` now
registers the additional twelve sites.

The current-source `demo1` profile recorded 66,049 mip-2 block draws across
969 frames. Instrumented profile time was diagnostic only and was not used for
the performance comparison.

## Exact output parity

The control and candidate used DOSBox-X 2026.08.31, the pinned 320x200 i486
profile
(`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, `-parityclock -zchecksums`, and the same timedemo commands. Both
completed 969 timed frames with final framebuffer checksum `1047377823`.
All 970 color and Z records matched byte-for-byte, as did the frame-169 PCX:

| Artifact | SHA-256 |
| --- | --- |
| Color checksum stream | `A221018CA9236D225CD96A4A3D5F2402548233EEA1EAB2FD4A02EFA619E834ED` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame-169 PCX | `BAB09D82AFABB7FD6765C14B7AB00D2016C9430DF12EB42BADED56E2949093C9` |

## Strict i486 gates

The qbench executable passed the complete strict gate with 317,499 linked
instructions, 529 startup rows, and 9,207 DPMI-provider instructions. The
release executable passed with 165,085 linked instructions and the same
startup/provider counts. Both audits reported zero above-i486, unknown, or
exempt instructions.

| Executable | SHA-256 |
| --- | --- |
| qbench | `FA5B34E335D3D8C26CB85322027F99315F9461908A210123AE5E5173D3D28741` |
| release | `486472F544AC6A4666B9C2C72A060CE5035B4E548C82DD913777AB2BE13165D1` |

## Matched timing

Three alternating uninstrumented `demo1` pairs used the same 969-frame
workload, final checksum gate, and pinned DOSBox-X profile. Frame/Z checksum
capture and per-frame FPS statistics were disabled during timing.

| Pair | Control seconds / FPS | Candidate seconds / FPS |
| --- | ---: | ---: |
| 1 | 57.245848 / 16.926991 | 57.240526 / 16.928566 |
| 2 | 57.245873 / 16.926985 | 57.240510 / 16.928571 |
| 3 | 57.245780 / 16.927012 | 57.240625 / 16.928537 |

The mean increased from 16.926996 to 16.928558 FPS (**+0.001562 FPS,
+0.0092279%**). Every candidate sample beat its matched control. This is a
pinned DOSBox-X result, not a physical-486 performance claim.

## Artifacts

- Full parity results:
  `benchmarks/out/dos-timedemo-20261112-144533/timedemo-result.json` and
  `benchmarks/out/dos-timedemo-20261112-144745/timedemo-result.json`
- Timing handoffs:
  `benchmarks/out/surf8-mip2-unroll4-control-01-20261112.json`,
  `...-control-02-20261112.json`, `...-control-03-20261112.json`,
  `...-candidate-01-20261112.json`, `...-candidate-02-20261112.json`, and
  `...-candidate-03-20261112.json`
- Candidate builds:
  `D:\NitroQuake-surf8-mip2-row-unroll4-20261112\out\local-local-surf8-mip2-unroll4-candidate-20261112\qbench.exe`
  and
  `D:\NitroQuake-surf8-mip2-row-unroll4-20261112\out\local-local-surf8-mip2-unroll4-release-20261112\quake.exe`
