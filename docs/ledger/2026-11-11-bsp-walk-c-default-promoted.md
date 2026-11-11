# World-BSP C walk selected as the i486 default (2026-11-11)

## Selector change

`BspWalkImplementation=c|asm` continues to select the recursive world-BSP
walk. The checked-in i486 profile now selects the original C walk because three
alternating, uninstrumented `demo1` pairs measured it faster than the assembly
walk. The handwritten assembly entry remains available for explicit builds;
i386 continues to use C.

The two variants used the same source tree fingerprint
`F2514508A8C904402D5FD76760D33CD6AD105472724067B93E474F4D274D09F9`. The only
selector difference was `BspWalkImplementation`. Both used the pinned DOSBox-X
profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`.

## Build and ISA gates

Both Build 858 benchmark executables passed the complete strict i486 gate. Each
had 168 exact project-object proofs and 403 project/runtime-object proofs, 435
source-bound contributions, 529 startup code rows, and 9,207 DPMI provider
instructions. The linked executable audits found zero above-i486, unknown, or
exempt instructions.

| Selector | Linked instructions | `qbench.exe` SHA-256 |
|---|---:|---|
| Assembly control | 316,333 | `9E3AC7897D076C1990A7C0EA00DDB9E428700D876158FAFE85E8A65B63C33C16` |
| C candidate | 316,141 | `73B52FAD1DABCF93A5E92C6B621351EED7905194E18F9229CBFF11DF7AA27FD8` |

## Exact rendering parity

Fixed-clock 320x200 `demo1` replays completed 969 timed frames for each
selector, with final framebuffer checksum `1047377823`. All 970 color records
and all 970 Z records, including the initial records, match byte-for-byte. The
frame 482 PCX files also match byte-for-byte at 65,012 bytes.

| Stream | SHA-256 |
|---|---|
| Color checksums | `FE21B79072C1221B0FEEF32AFCBB6AEB513EAFD72402E5E0AAD2112F61683C3C` |
| Z checksums | `4D995848BEF742F2E2B8362A978F21AB3F4A4885ACB95794DAC512964135FD37` |
| Frame 482 PCX | `437F3EA0349D226EE4BFD3A4C29CE7085C48FB873807B711AA599030AE413F87` |

## Matched release timing

Three alternating pairs used DOSBox-X 2026.08.31, the pinned 320x200 `demo1`
workload, 969 timed frames, and checksum `1047377823`. These timing runs had no
instrumentation, frame checksums, Z checksums, or parity clock.

| Pair | Assembly FPS | C FPS |
|---:|---:|---:|
| 1 | 16.888343 | 16.892446 |
| 2 | 16.888334 | 16.892441 |
| 3 | 16.888342 | 16.892421 |
| Mean | 16.888340 | 16.892436 |

The C walk gained **0.004096 FPS (+0.024255%)**. Every C sample exceeded every
assembly sample; the minimum gap was 0.004078 FPS. These are DOSBox-X results,
not a measurement on physical 486 hardware.

## Disposition and limits

Select C as the i486 release default and retain assembly as an explicit option.
The choice is based on a small but repeatable `demo1` gain and exact output
parity. The profile does not establish behavior or performance on physical
hardware or other workloads.

After updating the checked-in profile, Build 859 also passed the complete
strict gate with `BspWalkImplementation=c`. Its linked executable audit found
316,141 instructions, 435 source-bound contributions, 529 startup code rows,
and 9,207 provider instructions, with zero above-i486, unknown, or exempt
instructions. A default-selector `demo1` check completed 969 frames at
16.892474 FPS with checksum `1047377823`; this verification sample is not part
of the three-pair mean.

## Artifacts

- Control build: `out/local-local-bspwalk-asm-20261111/`
- Candidate build: `out/local-local-bspwalk-c-20261111/`
- Checked-in default build: `out/local-local-bspwalk-c-default-promoted-20261111/`
- Checked-in default `qbench.exe` SHA-256: `4EEC5274E9C6EF5EC96A7C7266CFEA2D726BB2A1013C958E26285EE0F340AF49`
- Checked-in default timedemo JSON: `benchmarks/out/bspwalk-default-current-20261111.json`
- Timing JSON: `benchmarks/out/bspwalk-{asm,c}-timing-0{1,2,3}-20261111.json`
- Exact parity JSON: `benchmarks/out/bspwalk-{asm,c}-parity-20261111.json`
- Fixed-clock run roots: `benchmarks/out/dos-timedemo-20261111-000254/` and
  `benchmarks/out/dos-timedemo-20261111-000504/`
