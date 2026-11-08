# Alias-triangle tile-min occlusion rejected (2026-11-05)

## Experiment record

Status: rejected. Reusing the existing 4-by-4 alias tile-min cache to skip
individual triangles reached the common unclipped-model raster path and culled
work, but changed visible color output. The Z checksum stream and final frame
checksum matched; exact per-frame framebuffer parity did not. Increasing the
depth safety margin from 2 to 32 units did not change the failed frame-72 image.
No uninstrumented timing A/B was run because the parity gate failed.

### Candidate

The opt-in `-atoc` path examined each indexed triangle in an unclipped alias
model batch. It expanded each projected triangle's integer bounding box by one
pixel, queried all covered existing 4-by-4 tile minima, and skipped the triangle
when every tile minimum was greater than the triangle's maximum reciprocal-Z
bound plus a safety margin. Clipped single-triangle draws retained their
existing path. The initial profile had zero candidates because alias control
was assembly-owned; activation was moved to the common `D_PolysetDraw` entry.

### Profile and parity evidence

The full strict i486 build is `out/local-alias-triangle-occlusion-profile4-20261105`.
Its gate passed for 322,831 relocated instructions, 529 startup rows, and 9,207
provider instructions, with zero above-i486, unknown, exempt, or unclassified
instructions.

The instrumented candidate replay is `out/dos-timedemo-20261105-181635`; its
matched control without `-atoc` is `out/dos-timedemo-20261105-181936`. Both used
the pinned DOSBox-X profile, fixed `host_framerate 0.0783`, the same 969-frame
demo, capture index 482, and color plus Z checksums. The candidate examined
302,898 triangles, queried 212,117 times, and culled 39,125 triangles. It
finished at framebuffer checksum `1047377823`, matching control. The captured
frame-482 PCX hashes also matched. However, the 970-record color checksum
streams differed at frames 72, 466, 690, and 934. All 970 Z checksum records
matched.

To inspect frame 72, the same-index control capture is
`out/dos-timedemo-20261105-182532` and the candidate capture is
`out/dos-timedemo-20261105-182828`. Their PCX comparison found 756 changed
pixels out of 64,000 (1.18125%), 0.77552 mean absolute channel error, and a
maximum channel error of 164; palette contents matched. The candidate's
repeated color stream was stable. A repeated control with a different capture
index varied only at frame 495, separate from the four candidate mismatches.

A second visual-parity-only build changed the depth margin to 32 units. It
explicitly skipped the ISA audit and is not an acceptance build. Its replay is
`out/dos-timedemo-20261105-183424`; frame 72 still differed from the same-index
control by the same 756 pixels, and the Z stream remained exact. The adjustment
therefore did not repair the color mismatch.

### Decision

Remove the triangle culling path and its profiling counters. Matching Z
checksums and a final framebuffer checksum are insufficient when intermediate
color output differs. The exact cause of the color-only discrepancy was not
established, so this tile-min predicate is not considered safe. The ignored
`out` directories above are retained as benchmark and image-diff evidence; no
generated output is committed.

## Notification-strip recheck (2026-11-07)

The retained frame-72 images were compared again after the benchmark-only
deterministic presentation clock became available. All **756 changed pixels
are confined to x=10..231, y=1..7**. The control shows the notification
`You got the Grenade Launcher`; the candidate does not. Every pixel outside
that notification strip is identical in the captured images. The palette and
the previously recorded complete Z streams match.

This establishes that the inspected frame-72 discrepancy is presentation-time
notification expiry, rather than a changed visible triangle in that image.
It does not establish correctness for the other failed frames or all possible
inputs. The old simulation-only `host_framerate` replay did not control the
`realtime` value used by notifications. The evidence and comparison bounding
box are retained in `out/triangle-occlusion-ui-recheck.json`; the converted
inspection images are `out/triangle-ui-control.png` and
`out/triangle-ui-candidate.png`.

The triangle predicate remains absent from the accepted renderer. Its previous
rendering rejection can be reopened for a fresh full-clock, all-frame color/Z
and image comparison, strict i486 audit, and matched uninstrumented timing.
This follow-up is a reason to requalify the experiment, not a promotion.
