# i486 Z-span schedule history and RenderFace no-clip rejection (2026-10-31)

## Historical positive result: Z-span start schedule

The candidate schedule moves the `d_ziorigin` addition ahead of the final x87
exchange in both positive and negative gradient loops, removing the second
`fxch` from each setup. It keeps the fixed-point depth updates, pixel stores,
and per-sample multiply/add operations. The reordered single-precision x87
operations can change rendered pixels. This schedule was previously the
omitted i486 default; the default has since been restored to `control` as
described below.

Three uninstrumented 320x200 `demo1` runs on DOSBox-X 2026.08.31 with
`cputype=486`, fixed 33445 cycles, and the pinned 969-frame profile gave:

| Run | Control FPS | Candidate FPS | Delta FPS |
|---:|---:|---:|---:|
| 1 | 16.331571 | 16.343224 | +0.011653 |
| 2 | 16.331577 | 16.343248 | +0.011671 |
| 3 | 16.331575 | 16.343232 | +0.011657 |
| **Mean** | **16.331574** | **16.343235** | **+0.011660 (+0.0714%)** |

Every full run reached 969 frames and final checksum `1047377823`. The focused
Z-span fixture passed 117 guarded C/assembly depth-buffer cases with zero
mismatches. The complete candidate i486 audit found 314,336 linked/executable
instructions, 529 startup rows, and 9,207 provider instructions, with no
above-i486 or unknown instructions and no exemptions.

The candidate frame-checksum stream differs from its control at 35 recorded
frame indices. The frame-99 captures differed at 37 of 64,000 pixels
(0.0578%), mean absolute channel error 0.00501, and maximum channel error 56.
The user initially accepted this measured visual delta because the timedemo was
faster. On 2026-11-03, after reporting visible rendering artifacts, the user
directed attention back to rendering correctness. The no-FXCH schedule is no
longer the default for omitted selectors; the pixel-exact `control` schedule is
the default for i486 and i386. The faster path remains available only through an
explicit `-ZSpanStartSchedule nofxch` selection.

## Default restored to control (2026-11-03)

The earlier 37-pixel frame-99 difference and 35 changed per-frame checksums are
now treated as unacceptable visual changes in light of the later artifact
report. A same-source follow-up compared a default `control` capture with an
explicit `nofxch` capture under the strict i486 build. Both rendered 969 frames
and ended with checksum `1047377823`, but the post-warmup streams differed at 37
of 964 indices (first frame 99, last 773). Frame 99 differed at 25 of 64,000
pixels; palettes matched, mean absolute channel error was 0.0041927, and the
maximum channel error was 60. This shows why matching final checksums alone did
not establish frame-by-frame correctness.

`Set-DefaultI486AssemblySelectors` now leaves an omitted `ZSpanStartSchedule`
at `control`, and the runner selector check enforces that default. The original
control implementation and the measured no-FXCH option remain available; the
historical speed result is not removed, but it no longer justifies changing
default rendering output. The restored default build passed the strict i486
gate with 314,465 linked instructions and zero above-i486, unknown, or exempted
instructions.

## Rejected: direct no-clip entry from `R_RenderFace`

The experiment branched around `R_ClipEdge`'s clip-pointer load/null test when
`RF_PCLIP` was zero, then entered the shared edge emitter through a small
no-clip entry point. It passed the complete i486 instruction audit, but three
uninstrumented runs were slower than the matched control:

| Run | Control FPS | Candidate FPS | Delta FPS |
|---:|---:|---:|---:|
| 1 | 16.331571 | 16.320498 | -0.011073 |
| 2 | 16.331577 | 16.320485 | -0.011092 |
| 3 | 16.331575 | 16.320479 | -0.011096 |
| **Mean** | **16.331574** | **16.320487** | **-0.011087 (-0.0679%)** |

Every run reached 969 frames and checksum `1047377823`. Its frame-99 capture
differed from a repeated control capture at 49 pixels; a repeated pair of
control captures differed at one pixel. Because it was slower and changed the
captured frame more than the accepted Z-span schedule, the helper, call-site
branches, and selector plumbing were removed.

## Artifacts

- Z-span candidate timings: `out/dos-timedemo-20261031-063217`
- Z-span control timings: `out/dos-timedemo-20261031-065339`
- Z-span frame capture/checksums: `out/dos-timedemo-20261031-065009`
- Direct-entry candidate timings: `out/dos-timedemo-20261031-071736`
- Direct-entry visual capture: `out/dos-timedemo-20261031-071305`
- Repeated control visual capture: `out/dos-timedemo-20261031-071524`
