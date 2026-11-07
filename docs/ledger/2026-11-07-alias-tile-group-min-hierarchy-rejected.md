# Alias tile-group minimum hierarchy rejected (2026-11-07)

## Candidate

The candidate added one summary level above the existing 4-by-4-pixel alias
occlusion minima. Each summary represented sixteen adjacent tile minima over a
16-by-16-pixel block. A cached group minimum could skip four per-tile checks on
each of four rows when the complete block lay inside a model bound and every
tile minimum was nearer than the model's conservative nearest depth. The three
summary arrays used 960 bytes for 240 groups; the underlying tile minima and
epoch cache were unchanged.

## Profile work

The instrumented `demo1` replay rendered 969 timed frames and recorded 4,503
occlusion queries and 1,627 model culls. It performed 32,493 leaf-tile checks
and 462,838 Z samples, compared with 36,940 checks and 530,082 samples in the
existing tile-anchor profile. Those are reductions of 12.04% and 12.69%,
respectively. The profile ended at framebuffer checksum `1047377823`.

## Exact output

The candidate's color and Z checksum files matched the pinned control
byte-for-byte. Its captured frame 482 PCX also matched. The hashes were:

| Output | SHA-256 |
| --- | --- |
| Color checksum stream | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z checksum stream | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |
| Frame 482 PCX | `31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213` |

## Strict i486 audit

The candidate release passed the complete strict gate: 315,541 relocated
instructions, 529 startup code rows, and 9,207 DPMI-provider instructions.
There were zero above-i486, unknown, exempt, or unclassified instructions; all
403 source proofs matched.

## Matched release timing

The candidate used DOSBox-X 2026.08.31, `cputype=486`, the pinned 320-by-200
`demo1` profile and data, fixed `host_framerate 0.05`, and 969 timed frames. The
three uninstrumented samples were 16.864250, 16.864582, and 16.864364 FPS, for
a mean of 16.864398667. The matched control mean was 16.897614 FPS
(16.897615, 16.897610, 16.897617), so the candidate was 0.19657% slower. All
candidate runs ended at framebuffer checksum `1047377823`.

The instrumented result is in `out/dos-timedemo-20261107-025152`; the
uninstrumented three-run result is in `out/dos-timedemo-20261107-030919` with
candidate source fingerprint
`8C7810FACD592C6820F64E9384616585CC139060339006E1B82D9BEE724CEF92`. The
control samples are recorded in the [world clipvertex cache rejection
ledger](2026-11-07-world-clipvertex-one-hit-sign-cache-rejected.md).

## Correctness review and disposition

Final review found that a group summary's old minimum was not cleared when its
epoch advanced. A query could therefore see the current epoch after only one
child tile had been populated and use a previous frame's minimum to skip the
incomplete group. The canonical replay happened to preserve every checksum,
but that does not make this invalidation scheme safe. Clearing the summary on
epoch change fixes the identified condition, but that corrected source was not
rebuilt or timed.

The candidate was removed. Its measured tile-check reduction did not improve
release FPS, and the invalidation defect left the tested implementation short
of the correctness requirement. No hierarchy code is retained; the existing
4-by-4 tile-min cache and anchor early-out remain the reference.
