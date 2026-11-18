# i486 release guard baseline

`tools/golden/i486-release.sha256` records normalized hashes for the supported
`i486-release` build. CI compares a clean build against this file to catch
unexpected output changes; updating it is a reviewed source change, not an
automatic response to a failed check.

## Baseline refresh: 2026-11-18

The previous baseline predated the video host-interface refactor in
`ae55938` (`refactor(video): route colormap access through host interface`),
which added `Host_GetColormap` and changed its callers in the host and video
modules. The later public-source preparation commit `4a110b8` added attribution
notices to source files. A clean Windows CI build confirmed that only four
normalized outputs differed: `obj/host.obj`, `obj/vid_ext.obj`,
`obj/vid_vga.obj`, and the linked `quake.exe`. The remaining release hashes
matched.

The four entries were refreshed from the pinned hosted build after the release
guard reported both expected and actual SHA-256 values. The guard remains
enabled and unchanged; this refresh records the current source output rather
than weakening the comparison. The engine build number remains derived from
the optimization ledger and is not affected by the golden file.

## Updating the baseline

When an intentional source change alters a release output:

1. Run the full release test suite on a clean checkout with the pinned DJGPP
   toolchain.
2. Review the reported changed paths and hashes against the source diff.
3. Update only the entries explained by that diff.
4. Run the full suite again and retain the release guard as a required gate.

Do not refresh the baseline to make an unexplained mismatch pass.
