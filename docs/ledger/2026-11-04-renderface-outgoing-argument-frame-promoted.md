# RenderFace outgoing argument frame promoted (2026-11-04)

## Optimization

Status: retained after exact parity, the complete strict i486 gate, and a
positive pooled mean over three uninstrumented runs per variant.

`R_RenderFace_asm486` now reserves 12 bytes in its local frame for outgoing
`R_ClipEdge` arguments. The four call sites write their cdecl arguments into
those slots and no longer adjust `%esp` after each call. The frame grows from
28 to 40 bytes; locals and incoming argument offsets move by 12 bytes.

## Matched timing

The control source fingerprint is
`F13C45F2D8CFB6BCD91B4F6D77F9FE9123536D8137E8A6772650E4CCF68D87FE`; the
candidate fingerprint is
`B48AA70A67170A9978D234586F3A4C90E4F20AF44511CDCC6825A0CC9B346AC7`. All six
runs selected `RenderFaceImplementation=asm` and
`SurfaceCacheImplementation=asm`, as confirmed by each run's build-selector
manifest verification.

Both variants used DOSBox-X `2026.08.31`, profile
`tools/dosbox-x-486-high.conf` (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
`demo1`, CWSDPMI, and 969-frame uninstrumented runs. Every run ended at
framebuffer checksum `1047377823`.

| Variant | Run artifacts | FPS samples | Mean FPS |
|---|---|---|---:|
| Control | `out/dos-timedemo-20261104-133927`, `...-134043`, `...-134203` | 16.377717 / 16.377714 / 16.377681 | 16.377704 |
| Candidate | `out/dos-timedemo-20261104-133514`, `...-133630`, `...-133754` | 16.378050 / 16.378045 / 16.378046 | 16.378047 |

The candidate pooled mean is **+0.000343 FPS (+0.002094%)**. Every candidate
sample exceeded every control sample.

## Correctness and compatibility

A fixed-step `host_framerate 0.0783` replay recorded 970 checksums with zero overflow for each variant; the checksum
streams and frame-695 PCX captures were byte-identical. Replay artifacts are
`out/dos-timedemo-20261104-133115` (control) and
`out/dos-timedemo-20261104-133254` (candidate).

The candidate strict build passed the complete i486 executable gate: 314,634
relocated instructions, 529 startup rows, and 9,207 DPMI provider instructions;
zero above-i486, unknown, or exempt instructions. Build output:
`out/local-renderface-outgoing-args-candidate-20261104/`.

## Artifacts

- Control timing results: `out/dos-timedemo-20261104-133927`,
  `out/dos-timedemo-20261104-134043`, and
  `out/dos-timedemo-20261104-134203`.
- Candidate timing results: `out/dos-timedemo-20261104-133514`,
  `out/dos-timedemo-20261104-133630`, and
  `out/dos-timedemo-20261104-133754`.
- Fixed-step replay: `out/dos-timedemo-20261104-133115` (control) and
  `out/dos-timedemo-20261104-133254` (candidate).
