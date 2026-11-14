# Span16 branch-selected address update rejected for parity (2026-10-29)

Status: rejected. `TextureSpanAddressing=control` remains active. The candidate
does not preserve the reference framebuffer, so its timing is not eligible for
comparison and no strict ISA audit was run.

The candidate replaced the indexed carry-table address update in the unrolled
Span16 pixel paths with a test and conditional branches selecting the T-carry
advance. It used the same 320x200 `demo1` workload, pinned DOSBox-X 2026.08.31
486 profile (SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`),
aggressive optimization profile, and current source tree fingerprint
`E868748B19BC30F95ABE7F5D2BD64ABB5BEE7530C310A05597F218B03F72A071`.

The initial parity screen failed on run 1: framebuffer checksum
`1395248141` instead of `1047377823`. A captured diagnostic replay also failed,
ending at `3011009990`; the matched control replay ended at `1047377823`. The
first recorded frame hash already differed (`899858235` candidate,
`4202843875` control). Both captured PCX files have 320x200 dimensions, ruling
out a resolution mismatch. The diagnostic runs enabled per-frame checksums and
are not performance measurements.

The selector experiment left the promoted source unchanged. Since it fails
parity at the first recorded frame, the branch-address variant is closed unless
its address-selection logic is corrected and requalified from scratch.

## Direct-carry follow-up (2026-10-29)

A follow-up rewrote the opt-in branch path to test the T-carry flag directly
with `JC`, removing the `SBB`/`TEST` mask sequence. The 320x200 parity run was
interrupted after the user reported visible horizontal-line artifacts. It
produced no completed timedemo result, final checksum, or usable timing; the
temporary assembly rewrite was restored from the committed source.

After restoration, the default `TextureSpanAddressing=control` path completed
one 320x200 verification run at
`out/dos-timedemo-20261029-172543/timedemo-result.json`: 969 frames and the
expected framebuffer checksum `1047377823`. The branch path remains unqualified
and must pass exact parity before any performance screen.

A follow-up run of the named `demo1-vga-full` scenario also passed after
restoration. It rendered 320x200, captured frame 169, completed 969 frames, and
retained checksum `1047377823`. The capture differed from the committed golden
at 12 of 64,000 pixels (changed-pixel fraction 0.0001875; mean absolute channel
error 0.0009375), within the scenario tolerance. This was a visual-parity build;
the renderer ISA audit was skipped.

## Removal of the rejected path

After the horizontal-line report, both branch-address variants were deleted
from `src/renderer/d_draw16.s`. The DOS build, benchmark, smoke, and timedemo scripts now
accept only `TextureSpanAddressing=control`; `build-dos.ps1` rejects `branch`
at parameter validation.

A fresh current-source i486 build passed the complete linked ISA audit: 314,318
instructions, zero above-i486, unknown, or exempt instructions. The strict
timedemo wrapper then grew past 1.2 GB in a post-audit PowerShell step before
launching DOSBox, so no new strict timing was produced. The separate
320x200 `demo1-vga-full` visual-only run completed twice at
`out/render-validation-20261029-horizontal-line-fix-visual-rebuilt/render-validation-result.json`.
Both runs completed 969 timedemo frames with checksum `1047377823`; their full
971-entry frame-checksum streams match
`out/dos-timedemo-20261029-204044/runs/run-01/framechecksums.txt` exactly.
Each capture passed the committed golden comparison with 12 of 64,000 pixels
changed and mean absolute channel error `0.0009375`. The visual-only build
skipped its own ISA audit; the current-source strict audit passed separately.
