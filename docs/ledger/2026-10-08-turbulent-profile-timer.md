# Turbulent profiling timer correction

## Correct subtraction and unchanged normal assembly

The profiling-only turbulent-span timer used an ambiguous AT&T x87 stack
subtraction and accumulated `start - end`. It now keeps the returned end time
in ST(0) and explicitly subtracts the start value with `fsubl`. The original
renderer operations and floating-point state remain unchanged.

`out/normal-timer-isolation-verification-20261008.json` proves identical
allocated bytes, section flags and normalized relocations in all 34 normal
assembly objects against the accepted view-control build. The profiling
change does not alter the normal renderer's machine code.

## Exact instrumented scene acceptance

The accepted `demo2` run uses the same `host_framerate 0.0783` command as the
dispatch reference. It matches all 980 post-warmup frame checksums, all 64,000
captured pixel indices and all 768 palette bytes exactly. The timer reports
positive 2.314825 seconds; the profiling stack reports zero overflows and bad
leaves, with two expected shutdown-discarded scopes. FPS is 10.002591 against
10.002572 in the reference; timing improvement is not an acceptance criterion.

Evidence and immutable executable/manifest/linked-report snapshots reside in
`out/dos-timedemo-20261008-014721`, including `timer-fix-parity.json`.
The executable SHA256 is
`E1BD733C75C5ABACD66D2EEA93F4F04C991DB396F754E8334EC7BCC6D45D1B00`.
An earlier comparison with console notifications disabled had 348 checksum
differences. Restoring the reference command set resolved all of them. That
nonmatching diagnostic is retained and does not count as parity acceptance.
