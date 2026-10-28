# Texture-span early packed-store schedule promoted (2026-10-21)

Status: promoted in the working assembly source under the user's direction to
promote any positive pooled FPS mean. This changes the performance acceptance
rule; exact framebuffer parity and the strict linked i486 audit remain required.

The assembly schedule moves each packed word store to immediately before the
final carry-based source-address update after both texels have been loaded. The
source tree fingerprint is
`7C225871669B3813A49DC337BA4B03E0FD871DCC1CF20B9AEE505DC0B159327A`, matching
the source snapshot used by the earlier candidate timing blocks.

The existing twelve-run parity-screen comparison used DOSBox-X 2026.08.31,
`demo1`, CWSDPMI, and the pinned 32 MB i486 profile with SHA-256
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`:

| Variant | Samples | Pooled mean |
|---|---|---:|
| Control, 12 runs | See [original measurement](2026-10-21-texture-span-early-store-rejected.md) | 15.537297833 FPS |
| Early store, 12 runs | See [original measurement](2026-10-21-texture-span-early-store-rejected.md) | 15.537298083 FPS |

The measured delta is **+0.000000250 FPS (+0.0000016%)**. Two candidate blocks
were faster and two slower, so the delta is below the observed spread. All 24
runs rendered 969 frames and produced framebuffer checksum `1047377823`. The
positive pooled mean qualifies under the updated user-directed rule; the result
is recorded at its measured magnitude without claiming a resolved causal speedup.

The current strict candidate build is
`out/profile-c86686d2e5e2448c/qbench.exe`, SHA-256
`A91446462B8527C0D213ADCB895836D5C0646D30E8E456F0402AAD4FDFA20397`. Its
complete i486 checks passed:

- 403 linked native/annotated objects; 313,316 linked instructions verified;
- 435 executable text ranges, with zero above-i486, unknown, or exempt
  instructions;
- final-byte startup proof for 1,660 loaded bytes and 529 startup code rows;
- 9,207 instructions in the exact CWSDPMI provider, with zero exemptions;
- final mapping covered 2,377 CODE ranges and 35 DATA ranges.

The strict timedemo runner rebuilt and audited this source, then its fresh
staging directory exited before producing `timedemo.txt`: DOSBox-X reported only
5,419,300 bytes available to Quake. A replay of the prior successful control
root still completed at 15.537299 FPS with the expected frame count and
checksum. No new FPS sample is claimed for the strict candidate build; the
promotion timing remains the earlier twelve-run comparison tied to the
identical source-tree fingerprint.
