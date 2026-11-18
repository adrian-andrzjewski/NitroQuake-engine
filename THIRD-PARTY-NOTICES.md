# Third-party notices

## id Software Quake source

The DOS engine is derived from id Software's Quake GPL source release. Original
file notices are retained; `gnu.txt`, `readme.txt`, and `LICENSE` accompany the
source. The license covers the engine code, not Quake's game data or marks. No
PAK files, commercial game assets, original Quake logos, or rendered gameplay
images are distributed. See the [upstream source release](https://github.com/id-Software/Quake).

## CWSDPMI

The maintained DOS DPMI provider and its original comparison executable are
covered by the GPL and Charles W. Sandmann's additional terms in
`tools/isa-provider-reference/primary/COPYING.CWS`. The complete corresponding
source excerpts and provider change inputs are kept in
`tools/isa-provider-reference/primary/` and `cpu486-and-hex.s`. The two
executables are retained solely for the DOS runtime/provider verification and
are not Quake game data.

## DJGPP and GCC reference material

Selected DJGPP and GCC source files are included only as reproducibility inputs
for the linked-runtime ISA checks. Their upstream copyright and license files
remain under `tools/isa-runtime-reference/licenses/` and alongside the GCC
reference files. The DJGPP compiler packages and GCC toolchain binaries are not
vendored; the build bootstrap downloads the pinned components from their
upstream distribution sources. DJGPP redistribution guidance is documented by
[DJ Delorie](https://www.delorie.com/djgpp/doc/ug/basics/copy-redist.html).

The Windows host-only DJASM verifier is built from its pinned source and
requires a native Windows GCC. It is generated under `out/` and is not checked
in.

## Other tools

DOSBox-X and the optional HX/HDPMI runtime are not included. Obtain them
separately and follow their respective licenses. No vendor executables or
vendor documentation are bundled for the optional HDPMI path.
