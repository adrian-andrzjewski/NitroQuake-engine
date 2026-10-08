# Alias-model animation frame setup assembly port

## `R_AliasSetupFrame` single and grouped frame resolution

`AliasSetupFrameImplementation=c|asm` selects a 32-bit assembly helper for
resolving alias model frame data. The public C wrapper still validates the
entity frame against `pmdl->numframes`, logs the existing diagnostic, and
falls back to frame zero. The retained `R_AliasSetupFrame_C` reference and the
assembly entry both receive the normalized frame, `cl.time`, and entity
syncbase explicitly.

The helper implements the original single-frame pointer calculation and the
animated-group interval scan. Group and frame data offsets remain relative to
`paliashdr`; compile-time assertions pin the 32-bit descriptor offsets and
strides used by the assembly. The x87 path preserves the reference time and
division order, truncates the period quotient toward zero with a saved control
word, and selects the next frame at an exact interval boundary. EBX, ESI, and
EDI are preserved, and the caller's x87 control word is restored.

## Frame resolver direct C/assembly fixture and ISA audit

The focused `bench486` fixture compares the selected `r_apverts` pointer with
both the C reference and an expected fixture offset. It covers single frames,
three-frame and one-frame groups, interval boundaries, positive wraps,
negative-time truncation, syncbase, and a large exact boundary. Four x87
rounding modes exercise each scenario, for 56 exact pointer comparisons.

Run the fixture with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -AliasSetupFrameOnly -AliasSetupFrameImplementation asm`.
All 56 scenario/rounding-mode comparisons passed under DOSBox-X configured as
a 486; the assembly helper preserved the x87 control word. The candidate BENCH
object audit covered 103 objects and 198,942 instruction sites, with zero
enforced post-i486 instructions and zero unknown opcodes. The complete BENCH
object closure covered 338 objects and 240,454 instruction sites, with zero
enforced above-i486 instructions. The linked audit verified 237,779 opcode
sites across 235 runtime inputs and 333 executable `.text` ranges, with zero
linked mismatches. Existing data and library exemptions remain enumerated in
the reports. The focused result is
`out/dos-bench-20261007-001537/bench-result.json`; ISA reports are in
`out/dos-memasm-fillrectasm-zpointasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-aliasframeasm-lightmapstylesasm-fusedlightmapasm-dlightasm/`.

## Frame resolver paired gameplay parity

The focused `i486-asm-alias-frame` profile changes only
`AliasSetupFrameImplementation` from the C reference profile. Both reference
and candidate validation passed on the pinned `demo2-entity-workload`; the
shared source-tree fingerprint is
`A54DB8D6DEC21CB4B2844CE2446C024563FAC59BA5215C16C93AAE32FDFA9ECF`.

Each profile completed two 985-frame runs and recorded 986 checksum entries
including startup. All 980 post-warmup checksums matched on each repeat. The
frame-169 captures matched exactly on both repeats: 64,000 palette indices
and all 768 palette bytes, with zero pixel or palette differences. The C
median was 12.8054725 fps and assembly was 12.805427 fps; this difference is
not a performance claim, and the C implementation remains the release
default. The pair report is
`out/render-parity-20261007-001547/render-parity-result.json`.
