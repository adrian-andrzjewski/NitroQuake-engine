# Mip-0 fully flat surface-block specialization

<!-- optimization-attempt: 2026-10-25-mip0-fully-flat-blocks accepted -->

This stable ledger entry records the retained mip-0 fully flat surface-block
specialization in `src/surf8.s`. It preserves the accepted classification of
the historical source-only change without tying the build number to a Git
commit hash. The later flat-dword-packing change to this helper is a separate
optimization attempt.

The historical change has no standalone FPS claim. This record keeps the
optimization inventory complete; it does not assert a performance result.
