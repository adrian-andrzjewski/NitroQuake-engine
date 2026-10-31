# Alias long-edge negative division reduction promoted (2026-10-31)

## Change

`D_PolysetSetUpForLineScan_asm486` keeps the existing `adivtab` path for deltas
in `[-31, 32]` and the existing signed divide for positive horizontal deltas.
For a negative horizontal delta on a long edge, it now divides the unsigned
magnitude once, then applies the exact floor-division correction. If
`|tm| = q*tn + r`, the result is `-q` when `r == 0`, otherwise `-q-1`; the
corresponding error increment is `0` or `tn-r`. This replaces two signed
divides with one unsigned divide on that path.

The `INT_MIN` case falls back to the C reference because negating that value
overflows its signed magnitude. Non-positive large edge heights also retain
the reference C path. No span interpolation or per-pixel code changed.

## Profile and remaining span cost

The instrumented 320x200 `demo1` profile recorded 5,470 alias models and
417,090 alias vertices. It attributed about 15.38 seconds to alias rasterization
overall; line-scan setup accounted for 109,961 calls and about 1.76 seconds,
while `D_PolysetDrawSpans8` accounted for 153,895 calls and about 3.30 seconds.
The setup optimization therefore targets a bounded part of alias work rather
than the pixel loop itself.

The span drawer is already hand-written and unrolled for 8- and 16-pixel
groups, with a dedicated one-pixel path. Each pixel still needs its own depth
comparison and, on a pass, its texture and colormap lookup. The current
evidence does not establish a safe way to skip those per-pixel tests or merge
segments without changing affine interpolation. Earlier span address,
advancement, alignment, and scheduling experiments are recorded in the span
ledger entries; the packed T/light descriptor trial was discarded because it
did not establish a reliable full-stream correctness and timing win.

## 320x200 performance

The baseline and candidate used DOSBox-X 2026.08.31, `cputype=486`, fixed
33,445 cycles, the pinned profile SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`, and the
same `id1` data root.

| Variant | FPS samples | Median FPS |
|---|---|---:|
| Control | 16.320498 / 16.320485 / 16.320479 | 16.320485 |
| Candidate | 16.343258 / 16.343242 / 16.343254 | 16.343254 |

The candidate improved the median by **0.022769 FPS (+0.139512%)**, about
0.083 seconds per 969-frame timedemo. Every run rendered 969 frames and ended
at framebuffer checksum `1047377823`.

## Correctness and i486 gates

The focused DOSBox line-scan harness passed **16,416 cases across four x87
rounding modes with zero mismatches**, including the `INT_MIN` fallback. The
strict object audit passed 276,037 project instructions (276,036 i386 and one
i486; zero above-i486, unknown, or exempt instructions). The source-bound
linked audit matched all 314,334 instruction sites with zero opcode mismatches;
the full linked executable disassembly also completed.

The timedemo's intermediate per-frame hashes were not enabled. Earlier repeated
control launches differed on some intermediate frames because the demo consumes
time-dependent random updates, while the deterministic line-scan harness and
the enforced final framebuffer checksum passed. The recorded timedemo source
fingerprint is `CE28D266B907EAE73676EEFA537BA6396DF8AE851C6900A3AF1E4D6BA9C83E8D`;
after that build, only assembly comments and trailing whitespace were cleaned,
without changing instruction bytes.

## Artifacts

- Control timedemo: `out/dos-timedemo-20261031-071736/timedemo-result.json`
- Candidate timedemo: `out/dos-timedemo-20261031-092204/timedemo-result.json`
- Line-scan parity: `out/dos-bench-20261031-092626/bench-result.json`
- Profile: `out/dos-timedemo-20261030-204521/quake/PROFILE.JSN`
- Strict build and ISA audit: `out/local-alias-linescan-negdiv-final-20261031/`
