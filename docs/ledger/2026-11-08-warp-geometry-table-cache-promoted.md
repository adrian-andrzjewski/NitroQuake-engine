# Invariant underwater warp tables (2026-11-08)

## Change and invariant

`D_WarpScreen` retains its assembly row/column geometry tables between calls.
The key contains refdef X/Y/width/height, screen rectangle width/height, source
stride, source-buffer address and the full x87 control word. Any changed input
rebuilds through the existing table builder. Time-phase selection, source pixels,
destination origin/stride and the pixel-copy routine remain per-call work.

These tables are pure functions of the keyed inputs; they contain no map-specific
visibility or image contents. Reallocated buffers at the same address with the
same geometry need the same pointer/column values. The renderer is single-threaded.
Static storage is 9,304 bytes; the function's stack frame shrinks by 9,264 bytes.
Existing C selection remains available. The selected assembly path calls no C
implementation of table construction or pixel copying.

## Independent correctness and compatibility

Control source is `93e22507fcfd`. Only `asm486_experiments.s` differs after normalizing
line endings across 435 C/H/S/INC files. Its source SHA-256 is
`8bece8906cd87c4ddbb902cb882b4a8de6457c10edb84525556be241c3485a88`.

The native differential fixture passed 1,512 full-wrapper cases: three geometries,
twelve x87 precision/rounding modes, independent input changes and repeated hits.
It compares exact destination/guard bytes, preserved registers, ESP/DF, x87 CW,
TOP, preloaded values and tag word against the unchanged assembly wrapper.
The first fixture's undersized synthetic source image was corrected before
acceptance; those excluded failures and their diagnostics remain preserved.

All three demos passed two control/two candidate color and Z stream comparisons
and byte-exact PCX comparisons. The BENCH486 build passed complete i486 auditing:
316,148 relocated instructions, 529 startup rows and 9,207 provider instructions,
with zero above-target, unknown or exempt instructions.

## Independent timing

Three alternating uninstrumented pairs per demo use DOSBox-X 2026.08.31, dynamic
486/x87, fixed 33445 cycles, VGA 320x200, fixed simulation step 0.0625 and the same
PAKs/provider. Frame timing and checksum collection are disabled for timing runs.

| Demo | Control median FPS | Candidate median FPS | FPS change |
|---|---:|---:|---:|
| demo1 | 16.955347 | 16.955328 | -0.000110% |
| demo2 | 17.287107 | 17.299525 | +0.071831% |
| demo3 | 15.878671 | 15.878671 | +0.000004% |

Pooling all nine timing runs per variant gives 16.654398 -> 16.658120 FPS,
**+0.022348%**. This is a small measured win concentrated in the water workload;
it does not establish a large fraction of warp time as table setup. The tiny
demo1 regression is retained rather than hidden in the pooled result.

## Evidence and decision

Promote the invariant-work removal subject to the final combined integration
record. One accepted optimization attempt is recorded here; fixture repairs and
benchmark repetitions are not separate attempts. These are emulator measurements,
not physical 486 cycle/cache-stall or FPS measurements.

Workspace-relative evidence: `benchmarks/out/warp-cache-validation-20261108/`
contains 24 handoffs/30 executions, 36 matching parity artifacts and `audit.json`.
Its session SHA-256 is
`E94F7F137C4EECBD9817893DF28FFAE63280E3B7F4DC6086DEF960645165B2C1`.
The final combined build/runtime record is maintained in the benchmark suite's
`docs/I486-OPTIMIZATION-20261108.md`; it distinguishes these independent samples
from final-artifact checks. Native build identity remains derived automatically.
