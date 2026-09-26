# DOS VESA default validation — 2026-09-26

Scope: automatic BIOS-discovered 320x200x8 VESA, single-page RAM presentation,
and bounded recovery to VGA mode 13h. No retained renderer, RNG, benchmark,
or assembly changes.
The pre-existing `tools/build-dos.ps1` change from `-falign-jumps=8` to `16`
was preserved byte for byte and is excluded from the video change.

## Build and focused checks

- Normal DJGPP build: `tools/build-dos.ps1 -NoBootstrap` passed.
- Benchmark build: `tools/build-dos.ps1 -Benchmark -DynamicLightImplementation asm -NoBootstrap` passed.
  Use Windows PowerShell 5.1, as documented in BUILD-DOS.md.
- `tools/smoke-dos.ps1 -NoBootstrap -SkipBuild -DataRoot <legal-id1>` passed.
- `python tools/test-video-dos.py` passed with native GCC. It compiles the
  production VBE decoder, discovery, initialization, presentation, mode
  recovery, startup update, and VGA direct-rectangle functions with mocked
  BIOS/DPMI/allocator calls. The assembly copy is represented by its existing
  dword-per-row contract; the test does not emulate the assembly instructions.

Covered cases include invalid attributes/planes/bpp/memory model, undersized
pitch, insufficient video memory/window size, unreadable bank windows,
window B segment selection, zero bank granularity, and a 320x200 mode after
the original 30-mode capacity. Faults cover controller/info/palette DOS
allocations, render-buffer allocation, DPMI mapping, BIOS mode set, bank
selection and initial palette load. Recovery reaches VGA once, including
with no previous mode, and releases mapped memory. Startup tests cover saved
nonzero modes, explicit mode zero, `-stdvid`, invalid saved defaults, and
failed automatic initialization without repeated attempts.

Sentinel tests cover full-screen contiguous copies, padded 328-byte hardware
pitch with tightly packed RAM, partial/odd-width rectangles, rejected
out-of-bounds rectangles, and direct-rectangle restoration through a fixed
bank window. No per-frame bank selection or display-start calls occur on
the tested single-page path.

## Emulator startup and mode checks

DOSBox-X 2026.08.31 reported BIOS mode `0x153` as 320x200x8 linear, pitch 320.
Automatic selection used one page with RAM copying. Separate startup runs
exercised `-stdvid` with a saved nonzero default, saved mode 1, explicit
`+vid_mode 0`, and `machine=vgaonly`. The VGA-only case logged the missing
VBE 2.0 support and remained usable through demo completion. `vesa_nolfb`
selected banked BIOS mode `0x153`, pitch 320, one RAM-backed page. Another run
completed the sequence mode 1 -> 0 -> 17 (linear VESA) -> 0 -> 17 before
finishing a demo. These functional runs use `cycles=max` and are not timing
evidence. Logs remain under `out/video-qa/{auto,std,saved,explicit,vga,banked,switch}/quake/id1/qconsole.log`.

## Matched timedemos

Pinned profile: `tools/dosbox-x-486-high.conf`, DOSBox-X 2026.08.31,
486 dynamic core, fixed 33445 cycles; profile SHA-256
`F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45`.
The same legal Steam `id1`, `demo1`, CWSDPMI, executable, and compiler flags
are used for both backends. The forced VGA command adds only `-stdvid`.

```powershell
./tools/build-dos.ps1 -Benchmark -DynamicLightImplementation asm -NoBootstrap
./tools/timedemo-dos.ps1 -NoBootstrap -SkipBuild -DynamicLightImplementation asm -Runs 3 -NoFpsStats -DataRoot <legal-id1>
./tools/timedemo-dos.ps1 -NoBootstrap -SkipBuild -DynamicLightImplementation asm -Runs 3 -NoFpsStats -DataRoot <legal-id1> -QuakeExtraArgs '-stdvid'
```

| Backend | Run 1 seconds | Run 2 seconds | Run 3 seconds | Frames each | Checksum each |
| --- | ---: | ---: | ---: | ---: | ---: |
| Automatic VESA | 59.471630 | 59.471654 | 59.471674 | 969 | 2955717646 |
| Forced VGA (`-stdvid`) | 59.454678 | 59.454389 | 59.454491 | 969 | 2955717646 |

The backends match each other, but **the required historical checksum
`4154140932` gate is NOT passed**. Median times are 59.471654 seconds for VESA
and 59.454491 for VGA: VESA took about 0.029% longer in this emulator test.
No speed improvement is demonstrated or claimed.

Reports: [VESA](out/dos-timedemo-20260926-123749/timedemo-result.json) and
[VGA](out/dos-timedemo-20260926-124444/timedemo-result.json). Both staged
executables have SHA-256
`9EEBAF6D2DC770D71567D94EA43839ABD18C8F9492B84B993FFC5AA1E55FC53C`.
The tested executable was restored to `out/dos-memasm-dlightasm/qbench.exe`
after discarding the diagnostic RNG experiment below.

Initial runs produced checksum `2955717646`, with either C or ASM dynamic
lights and with either PowerShell host. A byte-identical previously accepted
executable (SHA-256 `6AE868AEE381EAA48220EC3031A4236DCD6DA2B35E9A24581E13A1937F2E81BC`)
produced `4154140932` normally but `2955717646` with `-stdvid`. Its control
reports are in `out/video-control/out/dos-timedemo-20260926-123541` and
`out/video-control/out/dos-timedemo-20260926-124245`, respectively.
Raw captures from an isolated HEAD control and the new code isolated the
difference to 21 pixels at x=256..260, y=83..90; the new VESA framebuffer and
the old forced-VGA framebuffer were byte-identical.

The host loop advances `rand()` before rejecting frames at the 72 Hz limit,
and client entities use random animation phases. This is a plausible source
of the startup-dependent difference. A diagnostic benchmark-only reset to
seed 1 plus one random advance produced `3362242689`, not the historical
reference. That experiment was reverted; `host.c` and `host_cmd.c` are
unchanged. The exact historical checksum requirement cannot currently be
met for both startup paths even with the previously accepted executable.
Changing the benchmark fixture/reference requires a separate decision;
these results must not be described as passing that gate. Final builds use
Windows PowerShell 5.1 and the recent accepted runs' explicit
`-DynamicLightImplementation asm` selector; build defaults are unchanged.

## Visual validation boundary

Native DOSBox window capture failed with `FrameArrived timed out` / `window
capture timed out`. The user then stopped Computer Use with the physical
Escape key, and UI inspection stopped. Displayed gameplay, palette shifts,
menus/console and disk-icon appearance therefore still require manual visual
acceptance. BIOS success, checksum equality, and mocked direct-rectangle
tests do not establish displayed pixel/palette parity or real-hardware speed.
