# Brush-model splitter-plane cache at 1024 entries rejected (2026-11-06)

## Candidate and profile

The 512-entry direct-mapped transformed splitter-plane cache was doubled to
1,024 entries with the slot mask changed from 511 to 1,023. The key and lookup
path remained unchanged. This increased the four cache arrays from 14,336 to
28,672 BSS bytes.

The 1,024-entry fixed-step PROFILE486 run at
`out/dos-timedemo-20261106-132451` recorded 31,160 hits and 9,998 misses over
41,158 requests, exactly the same totals as the 512-entry control at
`out/dos-timedemo-20261106-124105`. The profile SHA-256 was
`532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA` for both.
The control and candidate profile source fingerprints were
`B5A8F8F3DC30ED4CDB0F746C7DE396C334D4F651F05B85E7AF4E9A7CB98BDD09` and
`645F57403D99C7DF96F81DF2CD534117D4AB3A3EBE875033D8E4849C9959B5CE`.

## Output and decision

The fixed-step candidate preserved all 969 color and Z checksum rows and the
captured frame 482 PCX byte-for-byte against the 512-entry control. The color
checksum SHA-256 is
`3B027A59E35E9290D554866AE078B2913A01A75F2E3A19665FFED8E9A5BC0E7B`; the Z
checksum SHA-256 is
`1B41D2AB5B0FC99FCCA5158C51E4D7B9028CBF4C3EC8DFDF32C6AB96C2DB85E8`; the
frame 482 PCX SHA-256 is
`31595BC38A502F9DF6598FD8C744DAD2556011AF36FF026E3E43A86C1133F213`. Both
profiles ended at framebuffer checksum `1047377823`.

The larger table recovered no additional transforms and therefore had no
measured work reduction to justify another 14,336 BSS bytes. It was screened
out before release timing and the strict linked i486 audit; the retained cache
capacity remains 512 entries.
