# Alias span constant-depth full-occlusion rejection (2026-11-02)

## Hypothesis

`D_PolysetDrawSpans8Prepared` tests signed 16-bit inverse depth at every pixel,
then skips texture lookup, Z store, and color store for an occluded pixel. For a
span with exactly zero horizontal inverse-depth step, every pixel uses the same
depth. A preliminary Z scan can therefore reject the whole span when every old
Z value is strictly greater than that constant depth.

This is an exact condition: the normal loop rejects when `candidate < oldZ`
(`cmpw (%ecx),%bp; jl ...`). Equality must fall back to the normal loop because
it passes the existing depth test. The candidate was limited to spans of at
least 16 pixels and checked `lzistepx == 0`; all other spans used the original
path.

## Candidate and proof

The opt-in assembly path saved the original loop count, loaded the span's Z
pointer and depth, and scanned each Z word. It returned to the original loop on
the first `oldZ <= candidate`; if all words satisfied `oldZ > candidate`, it
advanced to the next span without touching either output buffer.

Because zero is added to the full inverse-depth accumulator for every pixel,
the low-word depth tested by the existing loop is invariant over the span. The
scan checks every covered pixel, so its skip condition is sufficient and
necessary for the normal loop to reject the entire span. The implementation
passed the complete linked i486 audit (314,453 relocated instructions, 529
startup rows, 9,207 provider rows, zero above-i486/unknown/exempt instructions).

## Correctness evidence

The candidate and control rendered 969 demo frames with final framebuffer
checksum `1047377823` and matching event traces. Per-frame Z-buffer hashes
matched for all 970 records, including the initial record. With identical
`host_framerate 0.05` and `con_notifytime 0` autoexec commands, the captured
320x200 PCX at frame 50 had **zero differing pixels** and identical palettes.

The full color-hash stream was not deterministic even between repeated control
runs: one control repeat differed at frames 28, 50, 137, 225, and 627. The
control/candidate comparison differed at frames 50, 261, 374, 449, and 452.
Those differing-index sets do not establish a candidate-specific error; they do
mean the per-frame hash stream cannot be claimed as fully identical. The exact
frame-50 PCX and complete Z-hash stream are retained as separate evidence.

At measurement time, a temporary `AliasSpanDepthReject=control|constant`
selector selected the two builds. The selector and assembly candidate were
removed after rejection, so the following is the historical invocation rather
than a directly runnable command on the current source tree:

```powershell
rtk proxy pwsh -NoProfile -File tools/timedemo-dos.ps1 `
  -AliasSpanDepthReject control `
  -NoBootstrap -NoFpsStats -Runs 1 -FrameChecksums `
  -FrameCaptureIndex 50 -AllowGateOverride `
  -AutoexecCommandsJson '["host_framerate 0.05","con_notifytime 0"]' `
  -QuakeExtraArgs '-zchecksums'
```

Repeat with `-AliasSpanDepthReject constant` for the candidate. Compare
`FRAME.PCX` palette indices pixel-by-pixel, `FRAMECHE.TXT` for color hashes,
and `FRAMEZCH.TXT` for Z hashes.

## Benchmark and decision

Three uninstrumented 320x200 runs per variant used the pinned DOSBox-X profile
(`cputype=486`, fixed 33,445 cycles), fixed `host_framerate 0.05`,
`con_notifytime 0`, and the same 969-frame demo. All six runs returned
framebuffer checksum `1047377823`.

| Variant | FPS samples | Median |
|---|---|---:|
| Control | 16.458649, 16.457915, 16.458546 | 16.458546 |
| Constant-depth scan | 16.446626, 16.446631, 16.446313 | 16.446626 |

The candidate lost **0.011920 FPS (-0.0724%)**. The full-span scan duplicated
depth comparisons on spans that encountered a potentially visible pixel and
did not save enough per-pixel work on fully occluded spans. It was rejected and
the assembly and selector changes were removed. These are DOSBox-X results,
not measurements of physical 486 cache or bus behavior.

The next higher-grain candidate is whole-model rejection in
`R_AliasCheckBBox`: it runs after `R_EdgeDrawing` has populated world Z and
before `R_AliasDrawModel` transforms vertices or generates spans. A safe test
would need a padded projection of the active frame's model bounds and must
reject only when every Z word in that rectangle is strictly nearer than a
conservative upper bound for the model's inverse depth; near-plane crossings
must fall through. An existing instrumented profile
(`out/dos-timedemo-20261101-174832/quake/PROFILE.JSN`) counted 5,470 alias
model draws and 153,852 alias draw-span calls over 969 frames. The profile's
timer is diagnostic, so these counts identify a possible target but do not
establish a speed estimate. The rectangle scan's cost and actual fully hidden
model count remain unmeasured.

Run artifacts remain under `out/`: parity hashes at
`dos-timedemo-20261102-103719` (control), `103926` (candidate), and `104219`
(control repeat); frame-50 captures at `104454` (control) and `104659`
(candidate); and uninstrumented three-run timing at `104914` (control) and
`105246` (candidate). The audited control and candidate executables are under
`out/profile-4dbf890a6daa3d54` and `out/profile-90bf3e5b9ee60835` respectively.

The optional BENCH486 `-zchecksums` diagnostic used here remains available for
future experiments. It writes one hash of the complete Z buffer per captured
frame to `framezchecksums.txt` (the DOS 8.3 filename is `FRAMEZCH.TXT`); it does
not affect ordinary builds or timedemo runs unless explicitly enabled.
