# Alias-model lighting setup assembly port

## `R_AliasSetupLighting` scalar setup and light-vector rotation

`AliasSetupLightingImplementation=c|asm` now selects an i486 assembly entry
for the per-model alias lighting setup. The original C operations remain
available as `R_AliasSetupLighting_C`; both implementations take the input
lighting and the model-space forward, right, and up vectors explicitly. The
public renderer entry passes its existing vectors through that boundary.
Compile-time assertions pin the 32-bit `alight_t` offsets and size.

The assembly keeps Quake's ambient clamp and `VID_CBITS` transform in integer
operations. It stores the converted shade light as a 32-bit float before the
negative clamp and grade multiplication, then evaluates each light-vector dot
product left-to-right in x87 and rounds each result at the same global store as
the C implementation. The right-vector result is negated with `FCHS`, preserving
the sign of zero. The cdecl entry preserves EBX, ESI, and EDI and leaves the x87
control word unchanged.

## Direct C/assembly fixture and ISA audit

The focused `bench486` fixture compares ambient light, shade light, and all
three transformed light-vector components byte-for-byte. Six scenarios cover
the lower ambient clamp, negative shade, zero and positive shade, fractional
axes, cancellation-sensitive dot products, large inputs, and signed zero. All
24 scenario/rounding-mode combinations passed under the four x87 rounding
modes; both paths preserved the selected control word.

Run it with
`rtk pwsh -NoProfile -File tools/bench-dos.ps1 -AliasSetupLightingOnly -AliasSetupLightingImplementation asm`.
The report is
`out/dos-bench-20261006-233923/bench-result.json`.

The selected benchmark build passed the object and linked-closure i486 audits.
The object audit inspected 103 objects and 198441 instruction sites, with zero
enforced above-i486 and zero unknown instructions. The linked audit verified
237289 opcode sites across 235 runtime inputs and 333 executable `.text`
ranges, also with zero enforced post-i486 instructions. Existing runtime and
data exemptions remain listed in the reports. The reports are
`out/dos-memasm-fillrectasm-zpointasm-zneg4-surf0rows16-surf0hflat-surf1rows8-surf1hflat-surf1hflatidxhoist-aliasmatrixspecial-aliaslightingasm-lightmapstylesasm-fusedlightmapasm-dlightasm/isa-audit.json`
and `isa-audit-linked.json`.

## Paired gameplay result

The focused two-repeat Demo 2 C/assembly comparison is running under
`out/render-parity-20261006-233937/render-parity-result.json`. Both profiles
completed two 985-frame runs. Each run recorded 986 checksums including
startup; all 980 post-warmup checksums matched exactly on both repeats. The
captures at frame 169 also matched exactly on both repeats: 64,000 palette
indices and all 768 palette bytes. The shared source-tree fingerprint is
`66C5712BD3768567D6399DB0A86E62BCF8B2350226CB2B55FE60AC5618182143`.

The C median was 12.8056725 FPS and assembly was 12.805671 FPS. This pair shows
no material performance difference and is not a speed claim. The release
candidate's object audit covered 103 objects and 197331 instruction sites,
with zero above-i486 and zero unknown instructions. Its linked audit covered
235 runtime inputs, verified 236110 opcode sites, and reported zero linked
opcode mismatches. The C implementation remains the release default.
