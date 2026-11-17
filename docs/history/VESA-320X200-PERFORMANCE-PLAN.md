# 320x200x8bpp VESA performance plan

Date: 2026-09-26

## Objective

Determine whether a 320x200, 8-bit VESA linear-framebuffer mode can improve
the current 486-class `demo1` timedemo without changing rendered pixels,
timing, scene content, or software-renderer behavior. The current performance
goal is to move the matched baseline toward 59 seconds while keeping the
standard VGA path as the control and default.

## Current implementation

- `vid_mode` defaults to mode `0` in `src/video/vid_dos.c`.
- VGA mode `0` is 320x200 standard VGA, packed 8-bit pixels. It enters BIOS
  mode `13h`, renders through a conventional-memory backbuffer, and copies
  changed rectangles to `A0000h`.
- The VGA mode list also contains Mode X-style planar modes; these are not the
  VESA candidate.
- `src/video/vid_ext.c` optionally enumerates VBE 2.0 modes. A VESA mode may be
  banked or linear. For a multi-page linear mode, the existing path can render
  into the mapped page and flip pages; a single-page path still performs a
  screen copy.
- The VESA mode list is hardware/BIOS dependent, so a numeric mode index must
  not be treated as a portable identity.

## Phase 1: Establish a matched control

1. Preserve the current source tree and unrelated dirty work.
2. Build the existing aggressive benchmark executable with the pinned DJGPP
   toolchain.
3. Run the existing `demo1` timedemo under the repository-owned DOSBox-X
   profile: `cputype=486`, dynamic core, fixed 33445 cycles, same data root,
   resolution, command-line options, and DPMI host.
4. Record three or five runs with:
   - frame count;
   - elapsed seconds and FPS;
   - framebuffer checksum;
   - DOSBox-X version and profile hash;
   - executable hash;
   - whether FPS-stat collection was enabled.
5. Run the existing benchmark correctness harness and retain its checksum as a
   separate correctness record.

The control must remain the standard VGA mode-13h path. Do not compare a VESA
run against a different optimization profile, cache size, data staging, or
vsync policy.

## Phase 2: Add deterministic VESA diagnostics

Add an opt-in diagnostic or harness selector, without changing the default
mode, that reports the selected mode's:

- resolution and bits per pixel;
- VBE mode number;
- linear versus banked status;
- bytes per scanline;
- number of available pages;
- VGA-compatible flag;
- mapped framebuffer address when linear.

Select the candidate by properties (`320x200`, 8bpp, linear, and preferably
at least two pages), not by assuming that the first VESA mode or a fixed BIOS
mode number is stable. If no matching mode exists, the run must fail clearly
and must not silently fall back to VESA banked mode.

Keep `-stdvid` available as the explicit standard-VGA control. Any new mode
selector should be benchmark-only or opt-in until it has passed the gates
below.

## Phase 3: Benchmark matrix

Run the same timedemo for each mode that the machine exposes:

1. Standard VGA 320x200 packed mode 13h - acceptance control.
2. VESA 320x200x8 linear, multi-page — primary candidate.
3. VESA 320x200x8 linear, single-page — diagnostic; expected to retain a copy
   path.
4. VESA 320x200x8 banked — diagnostic only; do not promote without clear
   evidence because bank switches may dominate on a 486.

Use alternating control/candidate samples to reduce host/emulator drift. Keep
the same number of runs per variant and report median, minimum, maximum, and
per-run values. Do not infer a win from one unusually fast DOSBox-X run.

## Correctness and promotion gates

A VESA candidate is eligible for promotion only when all of the following are
true:

- all runs complete the same 969-frame `demo1`;
- framebuffer checksum remains `4154140932` on every matched run;
- the benchmark correctness harness passes with its expected checksum;
- smoke startup and clean exit pass;
- the candidate median is faster than the VGA control beyond the observed run
  spread, with the improvement repeated in an independent matched sample;
- no unintended mode, resolution, page-flip, or vsync change is hidden in the
  harness;
- the result is recorded as DOSBox-X evidence, not as proof of every physical
  486/VBE implementation.

If the linear VESA result is tied or slower, retain standard VGA as the
default. If only banked VESA is available, document availability and stop
short of changing the default.

## Implementation risks

- VBE mode enumeration and page counts vary by BIOS, DOSBox-X configuration,
  and real hardware.
- Direct writes to a mapped framebuffer may cost more than a 64 KB mode-13h
  rectangle copy on a real 486.
- The single-page and multi-page VESA paths use different `vid.buffer`,
  `vid.direct`, and page-flip behavior; verify both before timing.
- A successful VESA mode set is not sufficient evidence of performance or
  visual parity. Keep the checksum, correctness harness, and timedemo records
  together.

## Rollback boundary

The standard VGA mode-13h path remains unchanged and remains the default until
the full promotion gates pass. Revert only the opt-in VESA selector,
diagnostics, and related documentation if the candidate fails; do not broaden
the change into rasterizer or scene-content edits during this experiment.
