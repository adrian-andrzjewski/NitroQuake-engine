# The offline precomputation pass (2026-09-29)

Moved verbatim out of `BUILD-DOS.md`, section `## Current 486 performance-pass closure`, which
mixed result write-ups into the operational build reference. Each section is
now top-level here, so its heading lost one `#`; the prose is unchanged.
Ledger index: [`../INDEX.md`](../INDEX.md).

## Offline precomputation pass (2026-09-29) — one rejection, one cleanup, one closure

Ran the four precompute experiments staged in the plan of record. Two of the
four ended without code, and the two that mattered are the ones that produced
measurements rather than speedups. Full record in `ASM486-HANDOFF.md`.

**Precomputed `izistep` for the Z-span prologue — rejected, selector and code
removed.** `D_DrawZSpans` recomputed `d_zistepu * 2^31` once per call (58,051
per run) although `d_zistepu` was already cached per face by
`R_SetSurfaceZGradients` (`r_draw.c:390-425`). An opt-in
`-IzistepImplementation control|precomputed` selector stored the scaled value
in the 8 free pad bytes at `surf_t` offset 56 and had the assembly load it.
It was bit-exact by construction, and every correctness gate passed:
`486 benchmark correctness PASS` with end checksum `2378409472`, clean DOS
smoke, and 969 frames at framebuffer checksum `1047377823` on all six runs.

```text
control:     59.265374 / 59.265325 s                median 59.265374
precomputed: 59.285937 / 59.285888 / 59.285910 s    median 59.285910
delta        0.020536 s = 0.0347% slower
```

The control median is its two clean samples; the third control run was
59.660367 s, the isolated-outlier pattern already noted in this file. Every
clean control sample beats every candidate sample and the delta is about 420x
the 0.000049 s run spread, so this is a regression rather than noise.

The failure is worth keeping for a reason beyond the number. The change does
not merely remove x87 work, it *adds* a store: `R_SetSurfaceZGradients` now
writes a fourth field per face, on the miss path and the cache-hit path,
58,051 times per run, while the removed `flds` / `fmuls` / `fistpl` cost about
a cycle each here. Exchanging a real memory write for three emulator-cheap
instructions loses. Note this is **not** one of the invisible axes above — it
is an instruction-count and memory-traffic result, measured correctly, and the
answer is no. Anyone revisiting this must cut the producer-side store, not add
one.

A structural fact did survive: `LFNegSpan` in `d_draw.s` was dead code, entered
only when `d_zistepu == 0`, where `-0.0 * -2^31` truncates to 0 and it always
fell through to `LZeroStepSpanLoop` regardless. Deleting it let the candidate
drop the `flds` entirely, and the net was still negative. It is live again now
that the experiment is reverted.

**`d_mip_t16` as a constant table — landed, and kept as cleanup rather than as
a win.** `D_DrawSurfaces` rebuilt three 4-entry float tables on every span
flush (1,052 per run) under a standing TODO. `d_mip_t16[mip] = 0x10000 *
d_mipscale_values[mip]` is exactly `{0x10000, 0x8000, 0x4000, 0x2000}`, all
exactly representable, so it is now a `static const` table and the store is
gone.

```text
closure before:      59.265368 s  16.350189 FPS  checksum 1047377823
with const table:    59.265007 s  16.350289 FPS  checksum 1047377823
delta: -0.000361 s = 0.0006% faster
```

That is an order of magnitude below the 0.05% gate and near the run spread, so
no further timedemo is justified; the value is deleting a recomputation of a
compile-time constant. The planned hoist of `d_mip_xscale` / `d_mip_yscale`
into `D_ViewChanged` was deliberately **not** done. `xscaleinv` and `yscaleinv`
have one writer each, both inside `R_ViewChanged`, which calls
`D_ViewChanged()` last, so the ordering looks safe — but `R_ViewChanged` is
itself only reached from `R_SetupFrame` (`r_misc.c:454`, `:478`, `:491`) under
a condition, and from `SCR_UpdateScreen` (`screen.c:276`). Today `D_DrawSurfaces`
fills the tables on its first call regardless, so the code self-heals. The
hoist would trade that for a startup-ordering assumption where a missed first
frame leaves the tables zero and silently breaks texture mapping, in exchange
for an unmeasurable ~0.003%.

**E3 closed by measurement.** The drawn-face ratio was the open input: the
prior plan asserted a world `msurface_t` is drawn at most once per frame and
cited `gradients 58051 == surfaces work_items 58051`, but both counters count
*draws*, so the pair cannot distinguish the claim from a tautology. The counter
now counts **distinct** faces per frame through a 4096-slot direct-mapped table
keyed on the face pointer and tagged with `r_framecount` (`D_NoteFaceDrawn`,
`d_edge.c:46-68`). It is `#ifdef PROFILE486` only, costs nothing in release,
and adds no field to `msurface_t`, which is exactly 64 bytes and must stay so.
A collision merges two faces, so the count is a slight undercount and the true
hit rate a slight overstatement — the safe direction.

```text
gradients calls         58051
faces drawn (distinct)  55642
ratio                   0.9585   (repeats 2409, 4.15% of draws)
est. true ratio        ~0.966    (allowing ~426 expected collisions)
```

Faces do repeat, but only ~3.4% of the time — bmodel faces redrawn once per
visible leaf. A per-face table could serve at most that fraction, so the E3
ceiling of ~0.10-0.14% of frame scales to **~0.004%**. E3 was not built. This
also refines the ledger rule: for this family it was never the last-used
comparison that failed, it was the hit rate. The counter is kept so the ratio
can be re-measured instead of re-argued.

**E4 not attempted.** It was gated on E1-E3 landing; E1 was rejected and E3 is
closed. Its own stated ceiling was ~0.5% and remains the largest unclaimed item
on the offline-precompute list, but it is a cache-policy change rather than a
precompute.

Closure after this pass is 59.265007 s / 16.350289 FPS, 969 frames, framebuffer
checksum `1047377823` — unchanged from the recorded baseline of 59.265411 s /
16.350178 FPS. `BENCHMARK-COMPARISON.md` is deliberately not re-measured,
because no candidate was promoted.

## Latest PROFILE486 and texture-span STOSW experiment (2026-09-29)

The post-closure control profile is
`out\dos-timedemo-20260929-071039\timedemo-result.json`. It completed 969
frames with framebuffer checksum `1047377823`; its 67.718592-second duration
is attribution only. Texture spans remain the largest leaf at 18.900351
seconds (27.92%; 1,454,252 spans and 43,955,777 texture pixels), followed by
alias models at 8.999381 seconds (13.29%), world BSP at 11.42%, surface cache
at 10.61%, and Z spans at 9.31%.

The opt-in `-TextureSpanStores stosw` candidate uses unrolled `STOSW` for the
seven packed destination writes in each full 16-pixel span segment. Texture
sampling and fixed-point stepping are unchanged; `word` remains the default.
The candidate requires control texture-span load order, addressing, and row
path.

Reproduction commands:

```powershell
.\tools\build-dos.ps1 -Benchmark -NoBootstrap -TextureSpanStores stosw
.\tools\bench-dos.ps1 -SkipBuild -NoBootstrap -TextureSpanStores stosw -TimeoutSeconds 600
.\tools\smoke-dos.ps1 -NoBootstrap -TextureSpanStores stosw -DynamicLightImplementation asm -TimeoutSeconds 180
.\tools\timedemo-dos.ps1 -SkipBuild -NoBootstrap -Runs 1 -NoFpsStats -TextureSpanStores stosw
```

The candidate passed DOS smoke and the full `bench486` correctness suite with
checksum `2378409472`. Three alternating pinned `demo1` pairs all completed
969 frames with framebuffer checksum `1047377823`:

```text
word:  59.265536 / 59.265434 / 59.265502 s; median 59.265502 s; spread 0.000102 s
stosw: 59.325296 / 59.325327 / 59.779146 s; median 59.325327 s; spread 0.453850 s
```

The third `stosw` run (59.779146 seconds) is a high outlier; its first two
runs differ by 31 microseconds. Retaining all three samples, `stosw` is
59.825 ms (0.10094%) slower by median and remains rejected for promotion.
Retain it only as an explicit A/B option. Artifacts are in
`out\dos-memasm-spanstosw-zneg4-surf0rows4-surf0hflat-surf1rows8-aliasmatrixspecial-lightmapstylesasm-fusedlightmapasm-dlightasm`,
`out\dos-bench-20260929-074040`, `out\dos-smoke`, and timedemos
`out\dos-timedemo-20260929-075328` through
`out\dos-timedemo-20260929-075908`. The next measured hotspot is alias-model
rendering.

