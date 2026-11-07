# Alias tile-depth cache packing rejected (2026-11-07)

Status: rejected. Packing the existing alias-occlusion tile cache reduced its
storage but regressed matched uninstrumented DOSBox-X timing. The original
12 KB cache remains in the renderer.

## Candidate

The 80-by-50 tile cache stores a conservative depth lower bound, an epoch, and
whether the depth is a partial anchor. The candidate encoded those values in a
single 16-bit entry: a 7-bit depth bucket rounded downward, a 7-bit epoch, and
one partial-anchor bit. This reduced storage from 12 KB to 8 KB. Downward
rounding could only reduce culls, not create a false occlusion result.

## Correctness and i486 evidence

The instrumented candidate replay used the same 320-by-200 DOSBox-X profile and
969-frame demo workload as its control. Its 971 framebuffer checksum rows and
971 Z-buffer checksum rows matched the control byte-for-byte. Both streams have
the following SHA-256 values:

| Stream | SHA-256 |
|---|---|
| Framebuffer | `3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B` |
| Z buffer | `1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8` |

The captured frame 482 PCX also matched, SHA-256
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`.
Both runs ended at framebuffer checksum `1047377823` across 969 timed frames.

The candidate passed the complete strict i486 audit: 315,259 relocated
instructions, 529 startup-code rows, and 9,207 DPMI-provider instructions were
checked, with no unsupported or unclassified instructions.

## Matched release timing

The candidate and clean-source control used the same DOSBox-X 486 profile,
profile hash `532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA`,
demo, frame count, and selector set. Each value below is one uninstrumented
969-frame run:

| Variant | Run 1 | Run 2 | Run 3 | Mean |
|---|---:|---:|---:|---:|
| Packed cache (`out/dos-timedemo-20261107-071009`) | 16.600401 | 16.600411 | 16.600419 | 16.600410 |
| Unpacked control (`out/dos-timedemo-20261107-071712`) | 16.756105 | 16.756066 | 16.756088 | 16.756086 |

The packed cache was 0.929071% slower. Its instrumented profile also culled
957 of 4,503 model queries and performed 25,452 tile checks and 354,215 Z
samples. The retained 12 KB anchor-cache profile recorded 1,627 culls, 36,940
tile checks, and 530,082 Z samples. The reduction in sampled Z values did not
offset the extra packing and decode work in release timing.

## Decision

Remove the packed representation and retain the existing two-array 12 KB
cache. The exact output and ISA results establish safety for the tested scene;
the matched release measurements reject its performance. Evidence is preserved
in `out/dos-timedemo-20261107-065055`, `out/dos-timedemo-20261107-071009`, and
`out/dos-timedemo-20261107-071712`.
