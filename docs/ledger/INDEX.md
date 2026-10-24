# Experiment ledger

This index covers the dated measurements, rejections and corrections from the
486 optimization work and the ongoing renderer port. Historical experiment
entries moved from `ASM486-HANDOFF.md` beginning
2026-10-03; the prose was moved verbatim.

Read the entry by its heading, never by a line number - see the process rule in
`ASM486-HANDOFF.md` under "Process rules". Ten of twelve line-number citations in
this material were found wrong by an audit on 2026-10-03, each invalidated by a
later insertion above it.

## Files

| File | Entries | Region |
|---|---:|---|
| [`2026-10-24-zspan-nonnegative-step-between-shld-ror-promoted.md`](2026-10-24-zspan-nonnegative-step-between-shld-ror-promoted.md) | 1 | renderer performance / schedule the second fixed-point step between SHLD and ROR in the nonnegative i486 Z-span pair loop after a positive strict mean |
| [`2026-10-24-zspan-positive-gradient-overflow-guard-promoted.md`](2026-10-24-zspan-positive-gradient-overflow-guard-promoted.md) | 1 | renderer performance / replace the positive-gradient Z-span endpoint 64-bit carry chain with signed overflow checks after a positive strict mean and full i486 ISA audit |
| [`2026-10-23-alias-transform-t-store-after-fdivrs-promoted.md`](2026-10-23-alias-transform-t-store-after-fdivrs-promoted.md) | 1 | renderer performance / move the alias T-coordinate copy after reciprocal division so it overlaps x87 work after a positive matched mean, exact checksum parity, and complete i486 ISA gates |
| [`2026-10-23-alias-transform-normal-index-read-hoist-promoted.md`](2026-10-23-alias-transform-normal-index-read-hoist-promoted.md) | 1 | renderer performance / overlap the normal-index read, scaling, and vertex-pointer advance with alias transform arithmetic after a positive matched mean, exact checksum parity, and complete i486 ISA gates |
| [`2026-10-23-alias-transform-pointer-advance-promoted.md`](2026-10-23-alias-transform-pointer-advance-promoted.md) | 1 | renderer performance / move alias transform source-pointer increments after their final reads following a positive matched mean, exact checksum parity, and full i486 ISA gates |
| [`2026-10-23-sprite-clip-integer-distance-tests-promoted.md`](2026-10-23-sprite-clip-integer-distance-tests-promoted.md) | 1 | renderer performance / replace repeated sprite distance x87 comparisons with IEEE single-precision integer predicates after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [`2026-10-23-bsp-walk-double-distance-integer-test-promoted.md`](2026-10-23-bsp-walk-double-distance-integer-test-promoted.md) | 1 | renderer performance / classify the stored BSP plane dot with exact IEEE-754 binary64 integer checks after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [`2026-10-23-bmodel-clip-integer-distance-test-promoted.md`](2026-10-23-bmodel-clip-integer-distance-test-promoted.md) | 1 | renderer performance / replace two x87 strict-positive tests with IEEE single-precision integer range checks in brush polygon clipping after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [`2026-10-23-lightmap-fullbright-integer-truth-promoted.md`](2026-10-23-lightmap-fullbright-integer-truth-promoted.md) | 1 | renderer performance / promote an i486 integer truth test for lightmap `r_fullbright` after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [`2026-10-23-lightmap-fullbright-mask-promoted.md`](2026-10-23-lightmap-fullbright-mask-promoted.md) | 1 | renderer performance / promote immediate-mask float truth testing in the i486 lightmap builder after a positive matched three-run mean, checksum parity, and complete ISA audits |
| [`2026-10-23-turbulent-span-fourteen-loop-release-default.md`](2026-10-23-turbulent-span-fourteen-loop-release-default.md) | 1 | renderer performance / promote fourteen-pixel turbulent span loop to the i486 default after a positive matched three-run mean, checksum parity, and complete i486 ISA gates |
| [`2026-10-23-turbulent-span-twelve-loop-release-default.md`](2026-10-23-turbulent-span-twelve-loop-release-default.md) | 1 | renderer performance / promote twelve-pixel turbulent span loop to the i486 default after a positive matched three-run mean, checksum parity, and complete i486 ISA gates |
| [`2026-10-23-turbulent-span-paired-loop.md`](2026-10-23-turbulent-span-paired-loop.md) | 1 | renderer performance / promote two-pixel turbulent span loop after a positive strict mean, checksum parity, and complete i486 ISA gate |
| [`2026-10-23-turbulent-span-octa-loop.md`](2026-10-23-turbulent-span-octa-loop.md) | 1 | renderer performance / promote an opt-in eight-pixel turbulent span loop after a positive strict mean, checksum parity, and complete i486 ISA gate |
| [`2026-10-23-turbulent-span-octa-release-default.md`](2026-10-23-turbulent-span-octa-release-default.md) | 1 | renderer performance / promote the eight-pixel turbulent span loop to the i486 default after a positive matched three-run mean, checksum parity, and complete i486 ISA gate |
| [`2026-10-23-turbulent-span-quad-loop.md`](2026-10-23-turbulent-span-quad-loop.md) | 1 | renderer performance / promote four-pixel turbulent span loop after a positive strict mean, checksum parity, and complete i486 ISA gate |
| [`2026-10-22-edge-list-legacy-default-promoted.md`](2026-10-22-edge-list-legacy-default-promoted.md) | 1 | renderer performance / retain legacy edge-list assembly as the i486 default after a positive matched mean |
| [`2026-10-19-menu-state-entry-assembly-port.md`](2026-10-19-menu-state-entry-assembly-port.md) | 4 | renderer port / LAN and server-list menu state entries (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-server-list-menu-assembly-port.md`](2026-10-19-server-list-menu-assembly-port.md) | 4 | renderer port / server-list menu drawing and host-cache sorting (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-video-mode-menu-assembly-port.md`](2026-10-19-video-mode-menu-assembly-port.md) | 4 | renderer port / DOS video-mode menu list and callback renderer (`Video mode menu behavior and selector`; `Direct C/ASM parity matrix`; `Strict i486 release audit and current ownership`; `Remaining video-menu port scope`) |
| [`2026-10-19-vesa-lifecycle-assembly-port.md`](2026-10-19-vesa-lifecycle-assembly-port.md) | 4 | renderer port / VESA resource cleanup and palette-ready state (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-video-mode-assembly-port.md`](2026-10-19-video-mode-assembly-port.md) | 4 | renderer port / DOS video mode, palette, and shutdown orchestration (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-setup-menu-assembly-port.md`](2026-10-19-setup-menu-assembly-port.md) | 4 | renderer port / player setup menu drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-game-options-menu-assembly-port.md`](2026-10-19-game-options-menu-assembly-port.md) | 4 | renderer port / multiplayer game-options menu drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-modem-config-menu-assembly-port.md`](2026-10-19-modem-config-menu-assembly-port.md) | 4 | renderer port / modem configuration menu drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-net-menu-assembly-port.md`](2026-10-19-net-menu-assembly-port.md) | 4 | renderer port / network protocol menu and help panel (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-multiplayer-menu-assembly-port.md`](2026-10-19-multiplayer-menu-assembly-port.md) | 4 | renderer port / multiplayer menu page (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-menu-saveload-assembly-port.md`](2026-10-19-menu-saveload-assembly-port.md) | 4 | renderer port / Load and Save page drawing (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-menu-help-page-assembly-port.md`](2026-10-19-menu-help-page-assembly-port.md) | 4 | renderer port / six help-page picture renderer (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-vesa-default-mode-wrapper-assembly-port.md`](2026-10-19-vesa-default-mode-wrapper-assembly-port.md) | 4 | renderer port / exported VESA default-mode wrapper (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification and ownership`; `Scope and remaining work`) |
| [`2026-10-19-vesa-wait-assembly-port.md`](2026-10-19-vesa-wait-assembly-port.md) | 4 | renderer port / VESA wait gates and VGA status-port polling (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification`; `Ownership and remaining scope`) |
| [`2026-10-19-screen-pause-loading-assembly-port.md`](2026-10-19-screen-pause-loading-assembly-port.md) | 4 | renderer port / pause and loading overlay composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification`; `Scope and remaining work`) |
| [`2026-10-18-surface-cache-lifecycle-assembly-port.md`](2026-10-18-surface-cache-lifecycle-assembly-port.md) | 4 | renderer port / surface-cache sizing, initialization, and flush (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope limits and reproduction`) |
| [`2026-10-18-console-resize-assembly-port.md`](2026-10-18-console-resize-assembly-port.md) | 4 | renderer port / console scrollback resize and reflow (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and execution`; `Traceability and remaining scope`) |
| [`2026-10-18-console-print-assembly-port.md`](2026-10-18-console-print-assembly-port.md) | 4 | renderer port / console scrollback insertion and linefeed (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification and current ownership`; `Traceability and remaining scope`) |
| [`2026-10-18-scr-drawconsole-assembly-port.md`](2026-10-18-scr-drawconsole-assembly-port.md) | 4 | renderer port / per-frame screen console dispatch (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and execution`; `Traceability and remaining scope`) |
| [`2026-10-18-vga-direct-rect-assembly-port.md`](2026-10-18-vga-direct-rect-assembly-port.md) | 4 | renderer port / VGA direct-rectangle dispatch and planar/linear backup/restore (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope limits and reproduction`) |
| [`2026-10-18-player-translation-assembly-port.md`](2026-10-18-player-translation-assembly-port.md) | 4 | renderer port / player-color table generation and translation (`Scope and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope limits and reproduction`) |
| [`2026-10-18-sbar-mini-deathmatch-assembly-port.md`](2026-10-18-sbar-mini-deathmatch-assembly-port.md) | 4 | renderer port / widescreen mini-deathmatch scoreboard (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 gate and current ownership`; `Traceability and remaining scope`) |
| [`2026-10-18-sbar-deathmatch-assembly-port.md`](2026-10-18-sbar-deathmatch-assembly-port.md) | 4 | renderer port / full intermission deathmatch scoreboard (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Traceability and remaining scope`) |
| [`2026-10-18-sbar-intermission-assembly-port.md`](2026-10-18-sbar-intermission-assembly-port.md) | 4 | renderer port / normal intermission overlay and number formatting (`Behavior and selector`; `Exact C/ASM parity`; `Strict i486 verification`; `Scope and remaining work`) |
| [`2026-10-18-sbar-finale-assembly-port.md`](2026-10-18-sbar-finale-assembly-port.md) | 4 | renderer port / finale overlay composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Scope and remaining work`) |
| [`2026-10-18-zone-memory-trace-assembly-port.md`](2026-10-18-zone-memory-trace-assembly-port.md) | 4 | renderer port / zone, cache, and hunk diagnostic trace adapters (`Behavior and selector`; `Exact C/ASM fixture`; `Strict i486 verification`; `Scope and remaining work`) |
| [`2026-10-17-cache-free-assembly-port.md`](2026-10-17-cache-free-assembly-port.md) | 4 | renderer port / cache block removal and address/LRU unlink (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-cache-free-low-assembly-port.md`](2026-10-17-cache-free-low-assembly-port.md) | 4 | renderer port / low-end hunk cache reclamation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-cache-free-high-assembly-port.md`](2026-10-17-cache-free-high-assembly-port.md) | 4 | renderer port / high-end hunk cache reclamation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-hunk-mark-release-assembly-port.md`](2026-10-17-hunk-mark-release-assembly-port.md) | 4 | renderer port / low and high hunk mark release (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-hunk-high-mark-assembly-port.md`](2026-10-17-hunk-high-mark-assembly-port.md) | 4 | renderer port / high-hunk mark query and temporary unwind (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Cache and memory scope remaining`) |
| [`2026-10-17-hunk-temp-alloc-assembly-port.md`](2026-10-17-hunk-temp-alloc-assembly-port.md) | 4 | renderer port / temporary high-hunk allocation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-hunk-named-alloc-assembly-port.md`](2026-10-17-hunk-named-alloc-assembly-port.md) | 4 | renderer port / named low and high hunk allocation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 release verification`; `Ownership and remaining work`) |
| [`2026-10-17-zone-heap-assembly-port.md`](2026-10-17-zone-heap-assembly-port.md) | 6 | renderer port / zone initialization, tagged allocation, zero-fill allocation and free/coalescing (`Behavior and selector`; `Direct C/assembly parity`; `Initial non-BENCH release verification`; `Current strict BENCH i486 verification`; `Current non-BENCH i486 release verification`; `Ownership and remaining work`) |
| [`2026-10-17-cache-alloc-assembly-port.md`](2026-10-17-cache-alloc-assembly-port.md) | 4 | renderer port / cache allocation and LRU eviction (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-cache-move-assembly-port.md`](2026-10-17-cache-move-assembly-port.md) | 4 | renderer port / cache block relocation (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-cache-allocation-search-assembly-port.md`](2026-10-17-cache-allocation-search-assembly-port.md) | 4 | renderer port / cache allocation search (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-vesa-copy-rects-assembly-port.md`](2026-10-17-vesa-copy-rects-assembly-port.md) | 4 | renderer port / VESA dirty-rectangle copy (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining scope`) |
| [`2026-10-17-cache-check-assembly-port.md`](2026-10-17-cache-check-assembly-port.md) | 4 | renderer port / cache lookup and LRU promotion (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Ownership and remaining work`) |
| [`2026-10-17-sbar-frags-assembly-port.md`](2026-10-17-sbar-frags-assembly-port.md) | 4 | renderer port / status-bar frag strip and stable scoreboard sorter (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Traceability and remaining scope`) |
| [`2026-10-17-sbar-inventory-assembly-port.md`](2026-10-17-sbar-inventory-assembly-port.md) | 4 | renderer port / status-bar inventory composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and Demo 1 run`; `Traceability and remaining scope`) |
| [`2026-10-17-con-drawconsole-assembly-port.md`](2026-10-17-con-drawconsole-assembly-port.md) | 4 | renderer port / console composition (`Behavior and selector`; `Direct C/assembly parity`; `Strict i486 build and execution`; `Traceability and remaining scope`) |
| [`2026-10-16-find-touched-leafs-assembly-port.md`](2026-10-16-find-touched-leafs-assembly-port.md) | 5 | renderer port / 3D entity-to-BSP-leaf traversal (`Function and selector`; `ABI and recursive behavior`; `Exact C/ASM parity`; `Strict i486 gates`; `Reproduction and limits`) |
| [`2026-10-16-clip-move-to-entity-assembly-port.md`](2026-10-16-clip-move-to-entity-assembly-port.md) | 5 | renderer port / 3D entity trace wrapper (`Function and selection boundary`; `Wrapper and ABI`; `Exact trace parity`; `Strict i486 gates`; `Reproduction and limits`) |
| [`2026-10-16-clip-to-links-assembly-port.md`](2026-10-16-clip-to-links-assembly-port.md) | 5 | renderer port / 3D area-link entity clipper (`Function and selector`; `ABI and recursive behavior`; `Exact C/ASM parity`; `Strict i486 gates`; `Reproduction and limits`) |
| [`2026-10-16-entity-hull-selection-assembly-port.md`](2026-10-16-entity-hull-selection-assembly-port.md) | 5 | renderer port / 3D entity and BSP hull selection (`Function and selection boundary`; `Exact parity fixture`; `Strict BENCH i486 gate`; `Strict Release i486 gate`; `Reproduction`) |
| [`2026-10-16-chase-hull-check-assembly-port.md`](2026-10-16-chase-hull-check-assembly-port.md) | 4 | renderer port / 3D BSP collision trace (`Function and selection boundary`; `Exact parity fixture`; `i486 executable gate`; `Reproduction`) |
| [`2026-10-15-sbar-primitives-assembly-port.md`](2026-10-15-sbar-primitives-assembly-port.md) | 4 | renderer port / status-bar primitives (`Reference mapping and selector`; `Direct C/assembly parity`; `Strict i486 verification`; `Remaining C ownership`) |
| [`2026-10-13-screen-update-assembly-port.md`](2026-10-13-screen-update-assembly-port.md) | 5 | renderer port / full screen-update orchestration (`Reference mapping and ABI`; `Direct C/assembly fixture`; `Exact paired framebuffer and ISA evidence`; `Refreshed ownership inventory and remaining C paths`; `Reproduction`) |
| [`2026-10-13-screen-drawram-assembly-port.md`](2026-10-13-screen-drawram-assembly-port.md) | 4 | renderer port / RAM indicator overlay (`Mapping`; `Direct differential fixture`; `Strict i486 verification`; `Reproduction and scope`) |
| [`2026-10-13-screen-overlays-assembly-port.md`](2026-10-13-screen-overlays-assembly-port.md) | 5 | renderer port / screen update overlay dispatch (`Original branch block and selector`; `Direct C/assembly branch fixture`; `Exact paired scene and i486 audit`; `Ownership snapshot`; `Reproduction and remaining scope`) |
| [`2026-10-13-screen-calc-refdef-assembly-port.md`](2026-10-13-screen-calc-refdef-assembly-port.md) | 4 | renderer port / screen view rectangle and projection setup (`Original behavior and selected assembly`; `Differential state fixture`; `Paired framebuffer parity and strict i486 audit`; `Traceability and reproduction`) |
| [`2026-10-13-alias-projection-turbulent-span-parity.md`](2026-10-13-alias-projection-turbulent-span-parity.md) | 4 | renderer port / alias projection and turbulent spans (`Original-to-assembly traceability`; `Direct differential fixtures`; `Strict i486 instruction evidence`; `Reproduction and scope`) |
| [`2026-10-13-r-printdspeeds-assembly-port.md`](2026-10-13-r-printdspeeds-assembly-port.md) | 4 | renderer port / timing diagnostics (`Original routine and selector`; `24-case console and ABI parity`; `Complete i486 build audit`; `Reproduction command and limits`) |
| [`2026-10-13-timegraph-assembly-port.md`](2026-10-13-timegraph-assembly-port.md) | 4 | renderer port / timing overlay (`Mapping`; `Deterministic parity`; `i486 verification`; `Reproduction instructions`) |
| [`2026-10-12-render-dispatch-particle-stack-alignment.md`](2026-10-12-render-dispatch-particle-stack-alignment.md) | 5 | renderer port / particle call adapter (`C reference and assembly boundary`; `Call-frame contract`; `Tracked integration profile and exact parity`; `i486 instruction and runtime evidence`; `Traceability and reproduction`) |
| [`2026-10-12-screen-overlay-live-routing.md`](2026-10-12-screen-overlay-live-routing.md) | 4 | renderer port / screen drawing backend routing (`Fixture hooks and production calls`; `486 fixture and ISA evidence`; `Exact scene pair`; `Reproduction`) |
| [`2026-10-11-r-parseparticleeffect-assembly-port.md`](2026-10-11-r-parseparticleeffect-assembly-port.md) | 5 | renderer port / particle packet decoder (`Reference and assembly mapping`; `Direct C/assembly fixture`; `Strict 486DX+x87 executable evidence`; `Deterministic event-to-frame parity`; `Traceability and reproduction`) |
| [`2026-10-11-screen-erase-center-string-assembly-port.md`](2026-10-11-screen-erase-center-string-assembly-port.md) | 4 | renderer port / centered-message erase (`Reference and selector boundary`; `x87 arithmetic and the 486DX target`; `Exact differential fixture`; `Strict executable evidence`) |
| [`2026-10-10-screen-calc-fov-assembly-port.md`](2026-10-10-screen-calc-fov-assembly-port.md) | 6 | renderer port / view projection (`Original C behavior and selector boundary`; `Assembly mapping`; `Direct C/assembly and ABI fixture`; `i486 instruction evidence`; `Paired framebuffer evidence`; `CalcFov traceability and reproduction`) |
| [`2026-10-10-d-drawzspans-assembly-parity.md`](2026-10-10-d-drawzspans-assembly-parity.md) | 5 | renderer port / depth spans (`Traceability and scope`; `Arithmetic, stores, and ABI`; `Direct differential fixture`; `Strict i486 audit`; `Reproduction and limits`) |
| [`2026-10-10-screen-center-string-assembly-parity.md`](2026-10-10-screen-center-string-assembly-parity.md) | 4 | renderer port / centered messages (`SCR_DrawCenterString reference and assembly boundary`; `x87 arithmetic, state and calling convention`; `18-case C/assembly differential fixture`; `Strict 486DX+x87 executable evidence`) |
| [`2026-10-10-render-poly-assembly-parity.md`](2026-10-10-render-poly-assembly-parity.md) | 4 | renderer port / polygon projection (`Original routine and assembly behavior`; `Direct differential oracle`; `Strict i486 and paired-run evidence`; `Traceability and reproduction`) |
| [`2026-10-10-con-drawinput-assembly-port.md`](2026-10-10-con-drawinput-assembly-port.md) | 5 | renderer port / console input overlay (`Original C behavior and ownership boundary`; `Assembly mapping and x87 behavior`; `Direct C/assembly fixture`; `ISA validation and current status`; `Traceability and remaining scope`) |
| [`2026-10-10-d-drawparticle-assembly-port.md`](2026-10-10-d-drawparticle-assembly-port.md) | 6 | renderer port / particle rasterization (`Traceability and scope`; `x87 conversion and clipping parity`; `Direct differential fixture`; `Paired scene parity`; `Strict i486 audit`; `Reproduction and limits`) |
| [`2026-10-10-r-entityparticles-assembly-port.md`](2026-10-10-r-entityparticles-assembly-port.md) | 5 | renderer port / entity particles (`Reference behavior and assembly mapping`; `Direct C/assembly fixture`; `Paired rendered-frame parity`; `i486 machine-code evidence`; `Traceability and reproduction`) |
| [`2026-10-10-r-teleportsplash-assembly-port.md`](2026-10-10-r-teleportsplash-assembly-port.md) | 2 | renderer port / particles (`Port mapping and contract`; `TeleportSplash validation status`) |
| [`2026-10-10-r-runparticleeffect-assembly-port.md`](2026-10-10-r-runparticleeffect-assembly-port.md) | 5 | renderer port / particles (`C reference and assembly behavior`; `Selector and direct fixture`; `Paired frame parity`; `ISA evidence and remaining scope`; `RPE test commands`) |
| [`2026-10-10-v-parsedamage-assembly-port.md`](2026-10-10-v-parsedamage-assembly-port.md) | 5 | renderer port / view damage parsing (`Damage packet behavior and assembly mapping`; `Direct damage parsing and ABI fixture`; `Paired damage-event frame parity`; `Damage parser i486 instruction evidence`; `Damage parser traceability and reproduction`) |
| [`2026-10-10-v-bonusflash-assembly-port.md`](2026-10-10-v-bonusflash-assembly-port.md) | 5 | renderer port / view palette event (`Original command behavior and four assembly stores`; `256-pattern full-state and ABI fixture`; `Exact palette-transition differential`; `Strict i486 executable and provider evidence`; `Reference-to-assembly traceability and reproduction`) |
| [`2026-10-09-alias-stats-assembly-port.md`](2026-10-09-alias-stats-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-09-drawspans-dispatch-parity.md`](2026-10-09-drawspans-dispatch-parity.md) | 4 | renderer port / span dispatch |
| [`2026-10-09-line-graph-assembly-port.md`](2026-10-09-line-graph-assembly-port.md) | 3 | renderer port / timing overlay |
| [`2026-10-09-particle-explosion-assembly-port.md`](2026-10-09-particle-explosion-assembly-port.md) | 2 | renderer port / particles |
| [`2026-10-09-particle-explosion2-assembly-port.md`](2026-10-09-particle-explosion2-assembly-port.md) | 2 | renderer port / particles |
| [`2026-10-09-print-times-assembly-port.md`](2026-10-09-print-times-assembly-port.md) | 2 | renderer port / diagnostics |
| [`2026-10-09-r-blobexplosion-assembly-port.md`](2026-10-09-r-blobexplosion-assembly-port.md) | 4 | renderer port / particles (`C reference and behavior`; `Assembly, selector and fixture`; `Event-driven scene trace`; `Validation status`) |
| [`2026-10-09-r-check-variables-assembly-port.md`](2026-10-09-r-check-variables-assembly-port.md) | 3 | renderer port / variable checks |
| [`2026-10-09-r-lavasplash-assembly-port.md`](2026-10-09-r-lavasplash-assembly-port.md) | 3 | renderer port / particles (`Scope and traceability`; `Correctness fixture`; `LavaSplash validation status`) |
| [`2026-10-09-r-rockettrail-assembly-port.md`](2026-10-09-r-rockettrail-assembly-port.md) | 3 | renderer port / particles (`Port and traceability`; `Reference fixture`; `Acceptance evidence`) |
| [`2026-10-09-r-setupframe-assembly-port.md`](2026-10-09-r-setupframe-assembly-port.md) | 3 | renderer port / frame setup |
| [`2026-10-09-r-transformplane-assembly-port.md`](2026-10-09-r-transformplane-assembly-port.md) | 2 | renderer port / plane math |
| [`2026-10-09-selectable-84-alias-control-checkpoint.md`](2026-10-09-selectable-84-alias-control-checkpoint.md) | 5 | renderer port / alias-control integration |
| [`2026-10-09-selectable-83-vesa-checkpoint.md`](2026-10-09-selectable-83-vesa-checkpoint.md) | 5 | renderer port / 83-selector VESA checkpoint |
| [`2026-10-09-selectable-77-assembly-profile-acceptance.md`](2026-10-09-selectable-77-assembly-profile-acceptance.md) | 4 | renderer port / all-selector profile |
| [`2026-10-09-selectable-assembly-profile-acceptance.md`](2026-10-09-selectable-assembly-profile-acceptance.md) | 3 | renderer port / combined profile |
| [`2026-10-09-frustum-transform-assembly-port.md`](2026-10-09-frustum-transform-assembly-port.md) | 4 | renderer port / frustum |
| [`2026-10-09-zsubmodel-polygons-assembly-port.md`](2026-10-09-zsubmodel-polygons-assembly-port.md) | 1 | renderer port / BSP |
| [`2026-10-08-accepted-renderer-checkpoint.md`](2026-10-08-accepted-renderer-checkpoint.md) | 2 | renderer port / checkpoint |
| [`2026-10-08-world-control-assembly-port.md`](2026-10-08-world-control-assembly-port.md) | 2 | renderer port / world |
| [`2026-10-08-alias-pipeline-assembly-port.md`](2026-10-08-alias-pipeline-assembly-port.md) | 2 | renderer port / alias |
| [`2026-10-08-chase-camera-assembly-port.md`](2026-10-08-chase-camera-assembly-port.md) | 2 | renderer port / camera |
| [`2026-10-08-automatic-executable-isa-gate.md`](2026-10-08-automatic-executable-isa-gate.md) | 2 | compatibility / workflow |
| [`2026-10-08-cwsdpmi-486-provider.md`](2026-10-08-cwsdpmi-486-provider.md) | 2 | compatibility / provider |
| [`2026-10-08-framebuffer-drawing-assembly-port.md`](2026-10-08-framebuffer-drawing-assembly-port.md) | 2 | renderer port / drawing |
| [`2026-10-08-turbulent-profile-timer.md`](2026-10-08-turbulent-profile-timer.md) | 2 | validation / profiling |
| [`2026-10-08-view-control-assembly-port.md`](2026-10-08-view-control-assembly-port.md) | 2 | renderer port / view |
| [`2026-10-08-drawing-driver-assembly-port.md`](2026-10-08-drawing-driver-assembly-port.md) | 2 | renderer port / driver |
| [`2026-10-08-render-dispatch-assembly-port.md`](2026-10-08-render-dispatch-assembly-port.md) | 2 | renderer port / dispatch |
| [`2026-10-08-runtime-source-audit.md`](2026-10-08-runtime-source-audit.md) | 2 | compatibility / runtime |
| [`2026-10-07-sky-assembly-port.md`](2026-10-07-sky-assembly-port.md) | 2 | renderer port / sky |
| [`2026-10-07-public-entry-assembly-port.md`](2026-10-07-public-entry-assembly-port.md) | 2 | renderer port / entries |
| [`2026-10-07-combined-direct-acceptance.md`](2026-10-07-combined-direct-acceptance.md) | 2 | renderer port / parity |
| [`2026-10-07-all-selectable-combined-parity.md`](2026-10-07-all-selectable-combined-parity.md) | 2 | renderer port / parity |
| [`2026-10-07-visibility-assembly-port.md`](2026-10-07-visibility-assembly-port.md) | 2 | renderer port / visibility |
| [`2026-09-26-reproducibility-baseline.md`](2026-09-26-reproducibility-baseline.md) | 1 | harness / method |
| [`2026-09-28-span-micro-experiments.md`](2026-09-28-span-micro-experiments.md) | 8 | alias |
| [`2026-09-29-alias-and-surface-block-experiments.md`](2026-09-29-alias-and-surface-block-experiments.md) | 7 | alias |
| [`2026-09-29-harness-and-cost-model.md`](2026-09-29-harness-and-cost-model.md) | 12 | world-bsp |
| [`2026-09-30-harness-fidelity-and-sourcing.md`](2026-09-30-harness-fidelity-and-sourcing.md) | 5 | harness / method |
| [`2026-10-01-attribution-corrections.md`](2026-10-01-attribution-corrections.md) | 5 | alias |
| [`2026-10-02-edge-scan-and-texture-spans.md`](2026-10-02-edge-scan-and-texture-spans.md) | 4 | harness / method |
| [`2026-10-02-surf8-bundle-and-promotion.md`](2026-10-02-surf8-bundle-and-promotion.md) | 5 | renderface |
| [`2026-10-03-alias-glue-closure.md`](2026-10-03-alias-glue-closure.md) | 3 | ISA / i386 |
| [`2026-10-03-clamp-fusion-and-the-1.0-rate.md`](2026-10-03-clamp-fusion-and-the-1.0-rate.md) | 1 | harness / method |
| [`2026-10-03-isa-audit-and-i386-codepath.md`](2026-10-03-isa-audit-and-i386-codepath.md) | 3 | ISA / i386 |
| [`2026-10-03-region-pricing-sweep.md`](2026-10-03-region-pricing-sweep.md) | 4 | z-spans |
| [`2026-10-04-toolchain-refactor.md`](2026-10-04-toolchain-refactor.md) | 11 | harness / method |
| [`2026-10-04-renderer-assembler-port.md`](2026-10-04-renderer-assembler-port.md) | 23 | renderer port |
| [`2026-10-05-world-bsp-assembly-port.md`](2026-10-05-world-bsp-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-render-world-assembly-port.md`](2026-10-05-render-world-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-renderface-assembly-port.md`](2026-10-05-renderface-assembly-port.md) | 3 | renderer port / renderface |
| [`2026-10-05-bmodel-face-assembly-port.md`](2026-10-05-bmodel-face-assembly-port.md) | 2 | renderer port / renderface |
| [`2026-10-05-efrag-store-assembly-port.md`](2026-10-05-efrag-store-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-submodel-polygons-assembly-port.md`](2026-10-05-submodel-polygons-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-bmodel-polygon-clip-assembly-port.md`](2026-10-05-bmodel-polygon-clip-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-edge-drawing-assembly-port.md`](2026-10-05-edge-drawing-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-scan-edges-assembly-port.md`](2026-10-05-scan-edges-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-05-edge-list-maintenance-assembly-port.md`](2026-10-05-edge-list-maintenance-assembly-port.md) | 2 | renderer port / world-bsp |
| [`2026-10-06-renderer-selector-benchmarks.md`](2026-10-06-renderer-selector-benchmarks.md) | 1 | renderer port / performance |
| [`2026-10-06-alias-transform-order-parity.md`](2026-10-06-alias-transform-order-parity.md) | 3 | alias |
| [`2026-10-06-particle-update-assembly-port.md`](2026-10-06-particle-update-assembly-port.md) | 4 | renderer port / particles |
| [`2026-10-06-surface-cache-parity-fix.md`](2026-10-06-surface-cache-parity-fix.md) | 1 | renderer port / surface cache |
| [`2026-10-06-sprite-clipping-assembly-port.md`](2026-10-06-sprite-clipping-assembly-port.md) | 2 | renderer port / sprites |
| [`2026-10-06-sprite-frame-assembly-port.md`](2026-10-06-sprite-frame-assembly-port.md) | 1 | renderer port / sprites |
| [`2026-10-06-sprite-gradient-assembly-port.md`](2026-10-06-sprite-gradient-assembly-port.md) | 1 | renderer port / sprites |
| [`2026-10-06-sprite-scan-left-assembly-port.md`](2026-10-06-sprite-scan-left-assembly-port.md) | 1 | renderer port / sprites |
| [`2026-10-06-sprite-scan-right-assembly-port.md`](2026-10-06-sprite-scan-right-assembly-port.md) | 1 | renderer port / sprites |
| [`2026-10-07-sprite-draw-assembly-port.md`](2026-10-07-sprite-draw-assembly-port.md) | 3 | renderer port / sprites |
| [`2026-10-07-sprite-setup-assembly-port.md`](2026-10-07-sprite-setup-assembly-port.md) | 2 | renderer port / sprites |
| [`2026-10-07-alias-lighting-setup-assembly-port.md`](2026-10-07-alias-lighting-setup-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-frame-setup-assembly-port.md`](2026-10-07-alias-frame-setup-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-skin-setup-assembly-port.md`](2026-10-07-alias-skin-setup-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-gradient-setup-assembly-port.md`](2026-10-07-alias-gradient-setup-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-line-scan-setup-assembly-port.md`](2026-10-07-alias-line-scan-setup-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-edge-table-assembly-port.md`](2026-10-07-alias-edge-table-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-skin-table-assembly-port.md`](2026-10-07-alias-skin-table-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-rasterize-assembly-port.md`](2026-10-07-alias-rasterize-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-prepare-assembly-port.md`](2026-10-07-alias-prepare-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-alias-matrix-composition-assembly-port.md`](2026-10-07-alias-matrix-composition-assembly-port.md) | 3 | renderer port / alias |
| [`2026-10-07-bsp-dynamic-light-marking-assembly-port.md`](2026-10-07-bsp-dynamic-light-marking-assembly-port.md) | 6 | renderer port / lighting |
| [`2026-10-07-bsp-dynamic-light-push-assembly-port.md`](2026-10-07-bsp-dynamic-light-push-assembly-port.md) | 5 | renderer port / lighting |
| [`2026-10-07-combined-renderer-parity-after-restart.md`](2026-10-07-combined-renderer-parity-after-restart.md) | 1 | renderer port / combined parity |
| [`2026-10-07-sprite-orientation-and-render-math-port.md`](2026-10-07-sprite-orientation-and-render-math-port.md) | 3 | renderer port / sprites and math |
| [`2026-10-07-light-control-port.md`](2026-10-07-light-control-port.md) | 1 | renderer port / lighting |
| [`2026-10-07-palette-assembly-port.md`](2026-10-07-palette-assembly-port.md) | 3 | renderer port / palette |
| [`2026-10-07-frame-control-assembly-port.md`](2026-10-07-frame-control-assembly-port.md) | 2 | renderer port / frame control |
| [`2026-10-07-math-closure-assembly-port.md`](2026-10-07-math-closure-assembly-port.md) | 2 | renderer port / math support |
| [`2026-09-29-offline-precomputation-pass.md`](2026-09-29-offline-precomputation-pass.md) | 2 | harness / method |
| [`timedemo-baseline-history.md`](timedemo-baseline-history.md) | 6 | harness / method |
| [`microbenchmark-results.md`](microbenchmark-results.md) | 14 | harness / method |

## By region

The files are ordered by day, which is how the work happened. This table is the
other axis: one row per renderer region, newest entry first.

### renderer ownership and equivalence

- measured [Combined assembly selection passes the complete guest suite](2026-10-08-accepted-renderer-checkpoint.md)
- measured [Whitespace cleanup and release pins preserve all allocated behavior](2026-10-08-accepted-renderer-checkpoint.md)

- measured [Original rotation, efrag and edge preparation remain traceable](2026-10-08-world-control-assembly-port.md)
- measured [World ISA and exact scenes pass before reviewed integration](2026-10-08-world-control-assembly-port.md)

- measured [Original transforms, clipping and model state are preserved](2026-10-08-alias-pipeline-assembly-port.md)
- measured [ISA and exact scenes pass before reviewed integration](2026-10-08-alias-pipeline-assembly-port.md)

- measured [Original collision and camera behavior is preserved](2026-10-08-chase-camera-assembly-port.md)
- measured [ISA, active-camera scenes and reviewed integration pass](2026-10-08-chase-camera-assembly-port.md)

- measured [Drawing algorithms and direct fixtures](2026-10-08-framebuffer-drawing-assembly-port.md)
- measured [Drawing scene acceptance and reviewed integration](2026-10-08-framebuffer-drawing-assembly-port.md)

- measured [Correct subtraction and unchanged normal assembly](2026-10-08-turbulent-profile-timer.md)
- measured [Exact instrumented scene acceptance](2026-10-08-turbulent-profile-timer.md)

- measured [View algorithms and direct fixtures](2026-10-08-view-control-assembly-port.md)
- measured [View scene acceptance and reviewed integration](2026-10-08-view-control-assembly-port.md)

- measured [Driver algorithms and direct fixtures](2026-10-08-drawing-driver-assembly-port.md)
- measured [Drawing driver scene acceptance and reviewed integration](2026-10-08-drawing-driver-assembly-port.md)

- measured [Calling behavior and direct tests](2026-10-08-render-dispatch-assembly-port.md)
- measured [Dispatch scene acceptance and reviewed integration](2026-10-08-render-dispatch-assembly-port.md)

- measured [Exact runtime object boundaries](2026-10-08-runtime-source-audit.md)
- measured [Embedded executable startup code](2026-10-08-runtime-source-audit.md)
- measured [Original algorithms and exact direct tests](2026-10-07-sky-assembly-port.md)
- measured [Scene acceptance and reviewed integration](2026-10-07-sky-assembly-port.md)
- measured [Calling conventions and direct validation](2026-10-07-public-entry-assembly-port.md)
- measured [Public-entry scene acceptance and integration](2026-10-07-public-entry-assembly-port.md)
- measured [Exact algorithms, continuous state and ABI checks](2026-10-07-combined-direct-acceptance.md)
- measured [Reproduction and current ownership limits](2026-10-07-combined-direct-acceptance.md)
- measured [Exact six-scene comparison](2026-10-07-all-selectable-combined-parity.md)
- measured [Regression measurements and remaining scope](2026-10-07-all-selectable-combined-parity.md)
- measured [Original behavior and direct tests](2026-10-07-visibility-assembly-port.md)
- measured [Scene acceptance and integration](2026-10-07-visibility-assembly-port.md)

- `measured` [Accepted returning routines](2026-10-07-math-closure-assembly-port.md)
- `measured` [Scene equivalence and integration](2026-10-07-math-closure-assembly-port.md)
- `measured` [Accepted frame-control equivalence (2026-10-07)](2026-10-07-frame-control-assembly-port.md)
- `documented` [Reproducing the frame-control gates](2026-10-07-frame-control-assembly-port.md)
- `measured` [Direct equivalence and ABI checks](2026-10-07-palette-assembly-port.md)
- `measured` [Paired complete frames](2026-10-07-palette-assembly-port.md)
- `documented` [Reproduce](2026-10-07-palette-assembly-port.md)
- `measured` [Accepted animated-style and point-light equivalence (2026-10-07)](2026-10-07-light-control-port.md)
- `documented` [Implementation and traceability](2026-10-07-sprite-orientation-and-render-math-port.md)
- `measured` [ABI and arithmetic](2026-10-07-sprite-orientation-and-render-math-port.md)
- `measured` [Mechanical and emulator evidence](2026-10-07-sprite-orientation-and-render-math-port.md)
- `measured` [Exact output evidence](2026-10-07-combined-renderer-parity-after-restart.md)

### alias

- `documented` [Alias-stat leaf behavior and ownership](2026-10-09-alias-stats-assembly-port.md)
- `documented` [Alias-stat selector and oracle](2026-10-09-alias-stats-assembly-port.md)
- `pending` [Alias-stat validation status](2026-10-09-alias-stats-assembly-port.md)

- `measured` [`R_ConcatTransforms` call sites](2026-10-07-alias-matrix-composition-assembly-port.md)
- `measured` [Direct fixtures and i486 audit](2026-10-07-alias-matrix-composition-assembly-port.md)
- `measured` [Two-repeat Demo 2 parity](2026-10-07-alias-matrix-composition-assembly-port.md)
- `measured` [`R_AliasPreparePoints` per-vertex transform and clip setup](2026-10-07-alias-prepare-assembly-port.md)
- `measured` [i486 object audit and exact Demo 2 parity](2026-10-07-alias-prepare-assembly-port.md)
- `measured` [Release-default timing note](2026-10-07-alias-prepare-assembly-port.md)
- `measured` [`D_RasterizeAliasPolySmooth` setup and span orchestration](2026-10-07-alias-rasterize-assembly-port.md)
- `measured` [Selected-object and linked 486 ISA audit](2026-10-07-alias-rasterize-assembly-port.md)
- `measured` [Two-repeat Demo 2 parity and timing](2026-10-07-alias-rasterize-assembly-port.md)
- `measured` [D_PolysetUpdateTables cached skin-row lookup](2026-10-07-alias-skin-table-assembly-port.md)
- `measured` [Direct skin-table fixture and 486 ISA audit](2026-10-07-alias-skin-table-assembly-port.md)
- `measured` [Skin-table paired gameplay parity](2026-10-07-alias-skin-table-assembly-port.md)
- `measured` [D_PolysetSetEdgeTable 12-way triangle edge selection](2026-10-07-alias-edge-table-assembly-port.md)
- `measured` [Direct edge-selection fixture and 486 ISA audit](2026-10-07-alias-edge-table-assembly-port.md)
- `measured` [Edge-table paired gameplay parity](2026-10-07-alias-edge-table-assembly-port.md)
- `measured` [`D_PolysetSetUpForLineScan` edge-step setup](2026-10-07-alias-line-scan-setup-assembly-port.md)
- `measured` [Direct fixture and 486 ISA audit](2026-10-07-alias-line-scan-setup-assembly-port.md)
- `measured` [Paired gameplay parity](2026-10-07-alias-line-scan-setup-assembly-port.md)
- `measured` [`D_PolysetCalcGradients` x87 gradient setup](2026-10-07-alias-gradient-setup-assembly-port.md)
- `measured` [Gradient direct fixture and 486 ISA audit](2026-10-07-alias-gradient-setup-assembly-port.md)
- `measured` [Gradient paired gameplay parity](2026-10-07-alias-gradient-setup-assembly-port.md)
- `measured` [`R_AliasSetupSkin` single and grouped skin resolution](2026-10-07-alias-skin-setup-assembly-port.md)
- `measured` [Skin resolver direct C/assembly fixture and ISA audit](2026-10-07-alias-skin-setup-assembly-port.md)
- `measured` [Skin resolver paired gameplay parity](2026-10-07-alias-skin-setup-assembly-port.md)
- `measured` [`R_AliasSetupFrame` single and grouped frame resolution](2026-10-07-alias-frame-setup-assembly-port.md)
- `measured` [Frame resolver direct C/assembly fixture and ISA audit](2026-10-07-alias-frame-setup-assembly-port.md)
- `measured` [Frame resolver paired gameplay parity](2026-10-07-alias-frame-setup-assembly-port.md)
- `measured` [`R_AliasSetupLighting` scalar setup and light-vector rotation](2026-10-07-alias-lighting-setup-assembly-port.md)
- `measured` [Direct C/assembly fixture and ISA audit](2026-10-07-alias-lighting-setup-assembly-port.md)
- `measured` [Paired gameplay result](2026-10-07-alias-lighting-setup-assembly-port.md)
- `measured` [`R_ConcatTransforms` (2026-10-06)](2026-10-06-alias-transform-order-parity.md)
- `measured` [`R_AliasTransformVector` (2026-10-06)](2026-10-06-alias-transform-order-parity.md)
- `measured` [`R_AliasTransformFinalVert` (2026-10-06)](2026-10-06-alias-transform-order-parity.md)
- `in progress` [Alias polygon clipping now has i486 assembly paths](2026-10-04-renderer-assembler-port.md)
- `in progress` [The clipped alias vertex-preparation loop now has an i486 assembly selector](2026-10-04-renderer-assembler-port.md)
- `measured` [The alias-glue C block is **0.1703% of frame, 3.4x the gate** — the first price that region has ever had,...](2026-10-03-alias-glue-closure.md)
- `measured` [`alias-glue` reads 6.01% of frame and is **2.29%** — 62% of it is the profiler measuring itself (2026-10-...](2026-10-03-alias-glue-closure.md)
- `negative` [Aff8 AGI interlock investigation (2026-09-29) — null result, selector removed](2026-09-29-harness-and-cost-model.md)
- `superseded` [Alias-raster C-glue instrumentation (2026-09-29) — **SUPERSEDED 2026-10-01, the numbers below are instrum...](2026-09-29-harness-and-cost-model.md)
- `measured` [Alias attribution corrected (2026-10-01) — the profiler was measuring itself; C glue is 3.1x cheaper than...](2026-10-01-attribution-corrections.md)
- `measured` [Alias-raster child breakdown (2026-09-29) — C cost is 2.86%, not the predicted <1%](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Alias sub-node instrumentation and the alias cost breakdown (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `rejected` [Aff8 16-byte code-alignment experiment (2026-09-29) — rejected and reverted](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Monster gib trail zero-XY experiment (2026-09-29)](2026-09-28-span-micro-experiments.md)
- `measured` [Alias-span address-update experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Alias-model prepare source-cursor experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### edge-scan

- `closed` [The per-edge dispatch remainder, decomposed (2026-10-02, second pass) — `edge-scan` is now 78% mapped and...](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The complete `edge-scan` map — 78% of the bucket accounted for](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [A fifth probe trap, and it is a different failure from the other four](2026-10-02-edge-scan-and-texture-spans.md)
- `rejected` [What this does and does not license](2026-10-02-edge-scan-and-texture-spans.md)
- `rejected` [`edge-scan` cannot be decomposed (2026-10-01) — the arithmetic forbids it, do not retry](2026-10-01-attribution-corrections.md)

### harness / method

- `measured` [Live `bench486` progress reporting (2026-10-09)](2026-10-09-bench486-live-progress.md)
- `measured` [The duplication, measured](2026-10-04-toolchain-refactor.md)
- `measured` [Four defects that were producing a wrong...](2026-10-04-toolchain-refactor.md)
- `measured` [Two runners tested whatever binary was l...](2026-10-04-toolchain-refactor.md)
- `measured` [The generated DOSBox config was not repr...](2026-10-04-toolchain-refactor.md)
- `measured` [One selector, written five times](2026-10-04-toolchain-refactor.md)
- `measured` [Six latent defects in the source-level I...](2026-10-04-toolchain-refactor.md)
- `measured` [What is now a gate that was not](2026-10-04-toolchain-refactor.md)
- `measured` [Toolchain-audit ISA correction (2026-10-06)](2026-10-04-toolchain-refactor.md)
- `measured` [A checklist moved out of a script's tail](2026-10-04-toolchain-refactor.md)
- `measured` [Result](2026-10-04-toolchain-refactor.md)
- `measured` [Dead code, and one that was not](2026-10-04-toolchain-refactor.md)
- `measured` [The clamp fusion is measured at **0.0000%**, and the probe that explains it says **1.0 cycle per instruct...](2026-10-03-clamp-fusion-and-the-1.0-rate.md)
- `measured` [`edge-scan` decomposed by dead-scratch probe — pass 1 of 2 (2026-10-02): six probes, and **the closure be...](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The census, and what it overturned](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The six probes](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Decision 3's 0.66 rate is wrong — the risk was prospective, not realised](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Four probe traps, each of which cost a build-and-run cycle](2026-10-02-edge-scan-and-texture-spans.md)
- `closed` [What is NOT closed, and what is inadmissible](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The Z-span integer probe, measured and retired (2026-10-02) — the harness charges 1.0 cycles per instruct...](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [Harness integrity and the measured fidelity result (2026-09-30) — the gate problem is now measured, not a...](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Legal sources for a 486 machine ROM (not pursued here)](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Sourcing research: the legal-BIOS question, answered (2026-09-30)](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [86Box, verified against source (2026-09-30) — the best ROM-free candidate, still disqualified](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [`Turbulent8` setup precompute (2026-09-30) — priced with a bit-exact dead-scratch probe; 0.034% addressab...](2026-09-30-harness-fidelity-and-sourcing.md)
- `measured` [Static 486 cost model (2026-09-29) — built; it disqualifies all three blind axes and promotes nothing](2026-09-29-harness-and-cost-model.md)
- `measured` [E3 and E4 disposition (2026-09-29)](2026-09-29-harness-and-cost-model.md)
- `rejected` [Hot-code clustering (2026-09-29) — rejected, and object granularity is the blocker](2026-09-29-harness-and-cost-model.md)
- `measured` [What this harness can and cannot measure (2026-09-29)](2026-09-29-harness-and-cost-model.md)
- `measured` [Where this leaves the project](2026-09-29-harness-and-cost-model.md)
- `measured` [`renderface` priced by premise (2026-10-01) — large pool, but the x87 in it is essential work; no probe b...](2026-10-01-attribution-corrections.md)
- `measured` [Current parity-gated closure (2026-09-28)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Current reproducibility note (2026-09-26)](2026-09-26-reproducibility-baseline.md)

### ISA / i386

- `measured` [Strict source-bound proof is integrated into normal builds](2026-10-08-automatic-executable-isa-gate.md)
- `measured` [Cached execution and adversarial checks pass](2026-10-08-automatic-executable-isa-gate.md)
- `measured` [Exact provider boundaries and replacements are verified](2026-10-08-cwsdpmi-486-provider.md)
- `measured` [Three paired scenes preserve rendering and timing](2026-10-08-cwsdpmi-486-provider.md)
- `measured` [Correction (2026-10-06): `0F AF` IMUL is i386, not Pentium; all three i486 variants audit at zero above-target instructions](2026-10-03-isa-audit-and-i386-codepath.md)
- `measured` [The 161 `imul r32,r/m32` sites are **not** strength-reducible — three approaches refuted by measurement (2026-10-03) — historical claim, superseded by correction](2026-10-03-isa-audit-and-i386-codepath.md)
- `measured` [A separate i386 codepath exists, and the shipped "486" binary needs a Pentium — both from one root cause (2026-10-03) — historical claim, superseded by correction](2026-10-03-isa-audit-and-i386-codepath.md)
- `closed` [The alias-glue block is **63 instructions, minimal, and 5.5x the gate** — closed from its own disassembly...](2026-10-03-alias-glue-closure.md)

### lightmap

- `promoted` [`R_PushDlights` active-light enumeration](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Five-case direct fixture, i486 ISA audit, and six-scene exact frame parity](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `promoted` [`R_MarkLights` BSP traversal and surface marking](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Direct 128-case C/assembly parity and i486 instruction audit](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Exact Demo 1 C/assembly framebuffer parity](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [`R_BuildLightMap` is **0.06% of frame, not 7.5%** — and a real loop-invariant hoist in it is worth **0.04...](2026-10-03-region-pricing-sweep.md)

### renderface

- `negative` [Correction: the general block row is **minimal, and that is derivable** — the 31x gate is not reachable b...](2026-10-03-region-pricing-sweep.md)
- `closed` [`renderface` priced (2026-10-02) — **CLOSED with a price**, and the 1.0 cycle rate is not a constant](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [The rate is a dependency property, not a constant — this is the important result](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [What the price does to `renderface`](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Two probe mechanics specific to C, both of which would have produced a silently wrong number](2026-10-02-edge-scan-and-texture-spans.md)

### renderer port

- `measured` [`VID_GetModePtr`, `VID_ModeInfo`, `VID_SetMode`, `VID_SetPalette`, `VID_ShiftPalette`, and `VID_Shutdown` pass C/ASM parity and strict i486 BENCH/release gates](2026-10-19-video-mode-assembly-port.md)
- `open` [Hardware-specific callbacks, FPS, and full-scene parity remain](2026-10-19-video-mode-assembly-port.md)
- `measured` [`M_ModemConfig_Draw` passes 2,880 exact C/assembly cases and the complete strict i486 release gate](2026-10-19-modem-config-menu-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, incomplete renderer ownership graph, and remaining console/menu/video C dependencies](2026-10-19-modem-config-menu-assembly-port.md)
- `measured` [Pause/loading overlays pass 10 exact C/ASM cases and the strict i486 release gate](2026-10-19-screen-pause-loading-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, unresolved renderer ownership, and remaining menu/video dependencies](2026-10-19-screen-pause-loading-assembly-port.md)
- `measured` [Zone/cache/hunk diagnostic trace adapters pass 25 C/ASM cases and strict BENCH and release i486 gates](2026-10-18-zone-memory-trace-assembly-port.md)
- `open` [Shared console output services and full renderer ownership remain](2026-10-18-zone-memory-trace-assembly-port.md)
- `measured` [Normal intermission overlay and number formatting pass four exact C/ASM cases and the strict i486 gate](2026-10-18-sbar-intermission-assembly-port.md)
- `measured` [Finale overlay assembly passes six exact C/ASM cases and the strict i486 gate](2026-10-18-sbar-finale-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, and complete renderer ownership remain](2026-10-18-sbar-intermission-assembly-port.md)
- `measured` [`Sbar_DeathmatchOverlay` assembly passes six exact C/ASM cases and the strict i486 gate](2026-10-18-sbar-deathmatch-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, and broader renderer C ownership remain](2026-10-18-sbar-deathmatch-assembly-port.md)
- `measured` [`M_BuildTranslationTable` and `CL_NewTranslation` selected assembly; all 512 palette-pair cases and strict i486 gates passed (2026-10-18)](2026-10-18-player-translation-assembly-port.md)
- `open` [Full-scene parity, FPS measurement, and remaining renderer ownership](2026-10-18-player-translation-assembly-port.md)
- `measured` [`D_DrawParticle` -> verification of the existing i486 rasterizer (2026-10-10)](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [104 direct C/ASM comparisons across four x87 rounding modes](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [Exact two-repeat `demo2-wizspike-event` frame and palette parity](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [Strict i486 executable, startup, and provider audits](2026-10-10-d-drawparticle-assembly-port.md)
- `open` [Full renderer ownership, broader particle stress, sky coverage, and FPU-less 486SX scope](2026-10-10-d-drawparticle-assembly-port.md)
- `measured` [`R_EntityParticles` -> i486 assembly port (2026-10-10)](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [Exact particle-list, RNG-continuation and ABI fixture](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [Exact two-repeat `demo2` entity-particle event frame parity](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [Strict i486 executable, startup, and provider audits](2026-10-10-r-entityparticles-assembly-port.md)
- `measured` [`R_RunParticleEffect` -> i486 assembly port (2026-10-10)](2026-10-10-r-runparticleeffect-assembly-port.md)
- `measured` [12-case direct state/RNG/ABI fixture and strict i486 executable audit](2026-10-10-r-runparticleeffect-assembly-port.md)
- `measured` [Exact two-run `TE_WIZSPIKE` frame and event parity](2026-10-10-r-runparticleeffect-assembly-port.md)
- `open` [486SX FPU scope and the remaining renderer migration](2026-10-10-r-runparticleeffect-assembly-port.md)
- `measured` [`V_BonusFlash_f` -> i486 assembly port (2026-10-10)](2026-10-10-v-bonusflash-assembly-port.md)
- `measured` [256 full-state/ABI patterns and 9,728 exact palette-update frames](2026-10-10-v-bonusflash-assembly-port.md)
- `measured` [Strict i486 executable, startup, and provider audits](2026-10-10-v-bonusflash-assembly-port.md)
- `open` [Full renderer-profile parity and remaining view/screen ownership](2026-10-10-v-bonusflash-assembly-port.md)
- `measured` [`V_cshift_f` -> i486 assembly port (2026-10-10)](2026-10-10-v-cshift-assembly-port.md)
- `measured` [Original `v_cshift` command semantics and argument stores](2026-10-10-v-cshift-assembly-port.md)
- `measured` [Seven token cases and contents shift](2026-10-10-v-cshift-assembly-port.md)
- `measured` [This profile's strict i486 audit](2026-10-10-v-cshift-assembly-port.md)
- `measured` [V_cshift traceability and reproduction](2026-10-10-v-cshift-assembly-port.md)
- `open` [Full profile parity and remaining view/screen ownership](2026-10-10-v-cshift-assembly-port.md)
- `measured` [`V_Init` -> i486 assembly port (2026-10-10)](2026-10-10-v-init-assembly-port.md)
- `measured` [Original command, cvar and gamma order](2026-10-10-v-init-assembly-port.md)
- `measured` [Direct registration, gamma and ABI fixture](2026-10-10-v-init-assembly-port.md)
- `measured` [Strict i486 audit for the view-control profile](2026-10-10-v-init-assembly-port.md)
- `measured` [V_Init traceability and reproduction](2026-10-10-v-init-assembly-port.md)
- `open` [Remaining view initialization dependencies and full profile parity](2026-10-10-v-init-assembly-port.md)
- `measured` [`Con_DrawInput` console-input overlay passes exact direct C/ASM/public parity across 21 cases and four x87 rounding modes](2026-10-10-con-drawinput-assembly-port.md)
- `measured` [Strict linked-object, final-executable, startup and provider i486 audits pass with zero violations or exemptions](2026-10-10-con-drawinput-assembly-port.md)
- `measured` [`Con_DrawConsole` exact five-case C/ASM framebuffer and state parity under DOSBox-X](2026-10-17-con-drawconsole-assembly-port.md)
- `measured` [Strict i486 object, linked executable, startup and CWSDPMI provider gates pass with zero exemptions](2026-10-17-con-drawconsole-assembly-port.md)
- `measured` [`Con_DrawNotify` exact C/ASM/public framebuffer and state parity across eight cases and four x87 modes](2026-10-17-con-drawnotify-assembly-port.md)
- `measured` [Strict linked-object, executable, startup and CWSDPMI provider gates pass with zero exemptions](2026-10-17-con-drawnotify-assembly-port.md)
- `measured` [`SCR_DrawCenterString` exact 18-case C/assembly/public parity across 12 x87 settings](2026-10-10-screen-center-string-assembly-parity.md)
- `measured` [Strict linked executable, startup and CWSDPMI provider audits pass with zero violations or exemptions](2026-10-10-screen-center-string-assembly-parity.md)
- `open` [Complete-scene parity and broader screen/rendering ownership](2026-10-10-screen-center-string-assembly-parity.md)
- `measured` [`SCR_EraseCenterString` exact 252-call C/assembly/public parity across 12 x87 settings](2026-10-11-screen-erase-center-string-assembly-port.md)
- `measured` [Strict linked executable, startup and CWSDPMI provider audits pass with zero violations or exemptions](2026-10-11-screen-erase-center-string-assembly-port.md)
- `open` [Full-scene parity and remaining renderer ownership](2026-10-11-screen-erase-center-string-assembly-port.md)
- `measured` [`SCR_DrawNotifyString` -> i486 assembly port with 19 exact direct cases and i486 execution (2026-10-10)](2026-10-10-scr-drawnotifystring-assembly-port.md)
- `measured` [Strict project-object, linked/runtime, final-executable, startup and CWSDPMI i486 audits pass with zero violations or exemptions](2026-10-10-scr-drawnotifystring-assembly-port.md)
- `open` [Combined-profile/full-scene parity and remaining screen ownership](2026-10-10-scr-drawnotifystring-assembly-port.md)
- `measured` [`SCR_UpdateScreen` overlay dispatch passes eight exact branch cases and two-run Demo 1 framebuffer parity](2026-10-13-screen-overlays-assembly-port.md)
- `measured` [C and assembly profiles pass strict i486 object, executable, startup and provider audits](2026-10-13-screen-overlays-assembly-port.md)
- `measured` [`SCR_UpdateScreen` full orchestration passes fifteen direct cases, seven paired scenes and a cumulative strict i486 release smoke](2026-10-13-screen-update-assembly-port.md)
- `measured` [The refreshed production ownership scan counts console, menu, status-bar, video and cache dependencies](2026-10-13-screen-update-assembly-port.md)
- `open` [Called screen/menu/status-bar/video routines, indirect targets and full-renderer ownership remain](2026-10-13-screen-update-assembly-port.md)
- `measured` [`SCR_CheckDrawCenterString` passes 11 exact state/draw cases across 12 x87 settings and the strict i486 executable gate](2026-10-18-scr-check-draw-center-string-assembly-port.md)
- `measured` [`R_ParticleExplosion2` -> i486 assembly port (2026-10-09)](2026-10-09-particle-explosion2-assembly-port.md)
- `measured` [Particle pool semantics and ABI](2026-10-09-particle-explosion2-assembly-port.md)
- `measured` [Full-state fixture and i486 results](2026-10-09-particle-explosion2-assembly-port.md)
- `measured` [`R_ParticleExplosion` -> i486 assembly port (2026-10-09)](2026-10-09-particle-explosion-assembly-port.md)
- `measured` [Standard explosion particle pool semantics and ABI](2026-10-09-particle-explosion-assembly-port.md)
- `measured` [Full-state fixture and i486 validation](2026-10-09-particle-explosion-assembly-port.md)
- `measured` [`R_TransformPlane` assembly slice (2026-10-09)](2026-10-09-r-transformplane-assembly-port.md)
- `measured` [Semantics and focused fixture](2026-10-09-r-transformplane-assembly-port.md)
- `measured` [Focused validation and remaining scene coverage](2026-10-09-r-transformplane-assembly-port.md)
- `measured` [`R_PrintTimes` -> i486 assembly port (2026-10-09)](2026-10-09-print-times-assembly-port.md)
- `measured` [Time conversion, formatting, and ABI](2026-10-09-print-times-assembly-port.md)
- `measured` [Deterministic console fixture and i486 results](2026-10-09-print-times-assembly-port.md)
- `measured` [`R_LineGraph` -> `R_LineGraph_asm486` port](2026-10-09-line-graph-assembly-port.md)
- `measured` [Leaf behavior and ownership](2026-10-09-line-graph-assembly-port.md)
- `measured` [Selection and oracle](2026-10-09-line-graph-assembly-port.md)
- `measured` [Acceptance status](2026-10-09-line-graph-assembly-port.md)
- `measured` [Original dispatch path](2026-10-09-drawspans-dispatch-parity.md)
- `measured` [Span dispatch verification](2026-10-09-drawspans-dispatch-parity.md)
- `measured` [Reference parity](2026-10-09-drawspans-dispatch-parity.md)
- `open` [Scope boundary](2026-10-09-drawspans-dispatch-parity.md)
- `measured` [Per-frame fullbright cache check](2026-10-09-r-check-variables-assembly-port.md)
- `measured` [R_CheckVariables verification](2026-10-09-r-check-variables-assembly-port.md)
- `measured` [Parity and scope boundary](2026-10-09-r-check-variables-assembly-port.md)
- `measured` [Per-frame renderer setup](2026-10-09-r-setupframe-assembly-port.md)
- `measured` [Verification](2026-10-09-r-setupframe-assembly-port.md)
- `open` [Scope still open](2026-10-09-r-setupframe-assembly-port.md)
- `measured` [Candidate identity and strict ISA gate](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Exact entity-scene parity](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Ownership impact and remaining C paths](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Validation boundary](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Run the combined alias-control profile](2026-10-09-selectable-84-alias-control-checkpoint.md)
- `measured` [Candidate identity and strict machine-code gate](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Exact parity for the VESA scene](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Current ownership inventory and remaining work](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Host-side startup proof helper](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [Reproduction command](2026-10-09-selectable-83-vesa-checkpoint.md)
- `measured` [77-selector strict assembly profile acceptance (2026-10-09)](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [Complete i486 executable gate](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [Six-scene exact 77-selector parity](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [Remaining 77-selector ownership and scope](2026-10-09-selectable-77-assembly-profile-acceptance.md)
- `measured` [76-selector combined assembly profile acceptance (2026-10-09)](2026-10-09-selectable-assembly-profile-acceptance.md)
- `measured` [Strict i486 executable gate](2026-10-09-selectable-assembly-profile-acceptance.md)
- `measured` [Six-scene exact parity](2026-10-09-selectable-assembly-profile-acceptance.md)
- `measured` [Remaining ownership and scope](2026-10-09-selectable-assembly-profile-acceptance.md)
- `in progress` [Opt-in frustum transform candidate](2026-10-09-frustum-transform-assembly-port.md)
- `in progress` [Paired scene parity (visual-only diagnostic)](2026-10-09-frustum-transform-assembly-port.md)
- `in progress` [Frustum AABB-index setup extension (2026-10-09)](2026-10-09-frustum-transform-assembly-port.md)
- `measured` [Strict paired acceptance (2026-10-09)](2026-10-09-frustum-transform-assembly-port.md)
- `measured` [Optional submodel polygon driver](2026-10-09-zsubmodel-polygons-assembly-port.md)
- `measured` [`R_MarkLights` tree walk](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Direct fixture and i486 ISA audit](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Exact Demo 1 parity](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Extended paired scenes and transient console notifications](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `promoted` [Combined fixture, ISA gate, and i486 default](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [Benchmark text-data disassembly case](2026-10-07-bsp-dynamic-light-marking-assembly-port.md)
- `measured` [`R_PushDlights` slot loop](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Direct fixture and instruction audit](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Six-scene exact framebuffer parity](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Combined promoted dynamic-light paths](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `promoted` [Promotion](2026-10-07-bsp-dynamic-light-push-assembly-port.md)
- `measured` [Combined promoted sprite-draw paths](2026-10-07-sprite-draw-assembly-port.md)
- `promoted` [`R_GetSpriteframe` animated sprite-frame selection](2026-10-06-sprite-frame-assembly-port.md)
- `measured` [Twelve direct frame-selection cases and exact paired Demo 2 parity](2026-10-06-sprite-frame-assembly-port.md)
- `promoted` [`D_DrawSprite` sprite draw orchestration](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [Combined four-path, six-scene exact checksum and framebuffer parity](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [Three direct buffer fixtures, exact Demo 2 parity, and focused ISA audits](2026-10-07-sprite-draw-assembly-port.md)
- `promoted` [`R_SetupAndDrawSprite` world poster, clipping, projection, and dispatch](2026-10-07-sprite-setup-assembly-port.md)
- `measured` [Five direct fixtures, two-repeat exact Demo 2 parity, and focused ISA audits](2026-10-07-sprite-setup-assembly-port.md)
- `measured` [Renderer-port ISA correction (2026-10-06)](2026-10-04-renderer-assembler-port.md)

- `in progress` [`D_FillRect` is now an i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawZPoint` is now an i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [The active sky span pixel loop has a selectable i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [The sky scan span loop now has an i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawSkyScans8` is now a complete i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_WarpScreen` is now a selectable i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawSolidSurface` now has a selectable i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [The `Turbulent8` scan setup and interpolation now have a selectable i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_BuildLightMap` now has a selectable i486 assembly dispatcher](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_AddDynamicLights` orchestration and projection now have selectable i486 assembly](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_DlightContributes` now has a selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [The `D_CacheSurface` miss handoff now has i486 assembly paths](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_DrawSurface` now has a selectable i486 assembly entry point](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_CacheSurface` now has a full selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_TextureAnimation` now has a full selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_MipLevelForScale` now exports its public i486 assembly entry directly](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_SetSurfaceZGradients` now has a selectable i486 assembly entry](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_CalcGradients` and texture-axis caching now have an i486 assembly path](2026-10-04-renderer-assembler-port.md)
- `in progress` [`D_DrawSurfaces` now has a selectable i486 assembly dispatcher](2026-10-04-renderer-assembler-port.md)
- `in progress` [Next work](2026-10-04-renderer-assembler-port.md)
- `in progress` [`R_RecursiveWorldNode` now has a selectable assembly walk](2026-10-05-world-bsp-assembly-port.md)
- `in progress` [`R_DrawParticles` now has a selectable i486 assembly path](2026-10-06-particle-update-assembly-port.md)
- `measured` [Build, ISA, and render validation](2026-10-06-particle-update-assembly-port.md)
- `in progress` [Remaining particle closure](2026-10-06-particle-update-assembly-port.md)
- `measured` [`R_ClearParticles` free-list reset follow-up (2026-10-09)](2026-10-06-particle-update-assembly-port.md)
- `in progress` [`R_RotateSprite` beam translation](2026-10-06-sprite-clipping-assembly-port.md)
- `in progress` [`R_ClipSpriteFace` plane clipping](2026-10-06-sprite-clipping-assembly-port.md)
- `in progress` [`R_GetSpriteframe` animated frame selection](2026-10-06-sprite-frame-assembly-port.md)
- `in progress` [`D_SpriteCalculateGradients` perspective setup](2026-10-06-sprite-gradient-assembly-port.md)
- `in progress` [`D_SpriteScanLeftEdge` span generation](2026-10-06-sprite-scan-left-assembly-port.md)
- `in progress` [`D_SpriteScanRightEdge` span completion](2026-10-06-sprite-scan-right-assembly-port.md)
- `in progress` [`D_DrawSprite` orchestration](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [Paired render and linked-ISA validation](2026-10-07-sprite-draw-assembly-port.md)
- `measured` [`R_SetupAndDrawSprite` world poster, clipping, projection, and dispatch](2026-10-07-sprite-setup-assembly-port.md)
- `measured` [Instruction-set and paired-render validation](2026-10-07-sprite-setup-assembly-port.md)
- `in progress` [Remaining world-BSP closure](2026-10-05-world-bsp-assembly-port.md)
- `in progress` [`R_RenderWorld` now has a selectable i486 assembly entry](2026-10-05-render-world-assembly-port.md)
- `in progress` [Remaining active world-renderer closure](2026-10-05-render-world-assembly-port.md)
- `in progress` [`R_RenderFace` now has a selectable i486 assembly entry](2026-10-05-renderface-assembly-port.md)
- `in progress` [`R_EmitCachedEdge` now has a selectable i486 assembly entry](2026-10-05-renderface-assembly-port.md)
- `in progress` [Remaining face-renderer closure](2026-10-05-renderface-assembly-port.md)
- `in progress` [Remaining active renderer closure](2026-10-05-renderface-assembly-port.md)
- `in progress` [`R_RenderBmodelFace` now has a selectable i486 assembly entry](2026-10-05-bmodel-face-assembly-port.md)
- `in progress` [Remaining B-model renderer closure](2026-10-05-bmodel-face-assembly-port.md)
- `in progress` [`R_StoreEfrags` now has a selectable i486 assembly entry](2026-10-05-efrag-store-assembly-port.md)
- `in progress` [Remaining world-renderer closure](2026-10-05-efrag-store-assembly-port.md)
- `in progress` [`R_DrawSubmodelPolygons` now has a selectable i486 assembly entry](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [Remaining submodel-polygon closure](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [`R_EdgeDrawing` now has a selectable i486 assembly entry](2026-10-05-edge-drawing-assembly-port.md)
- `in progress` [Remaining edge-drawing closure](2026-10-05-edge-drawing-assembly-port.md)
- `promoted` [`surf8` flat axis: three measured wins bundled and **PROMOTED, 0.0620%** (2026-10-02)](2026-10-02-surf8-bundle-and-promotion.md)
- `closed` [The `surf8` horizontal-flat axis, screened (2026-10-02) — four candidates, two closed by price](2026-10-02-surf8-bundle-and-promotion.md)
- `promoted` [mip-1 flat-row index hoist (2026-10-02) — **0.0353% alone; promoted at 0.0620% as part of a bundle**](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [Drawn-face ratio (2026-09-29) — measured at 0.9585, which closes the per-face precompute family](2026-09-29-harness-and-cost-model.md)
- `promoted` [mip-1 horizontal-flat surface blocks (2026-10-01) — **PROMOTED, 0.0513%**](2026-10-01-attribution-corrections.md)
- `measured` [Horizontal-flat mip-0 surface blocks (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Pre-surface-block-loop control and PROFILE486 baseline (2026-09-28)](2026-09-29-alias-and-surface-block-experiments.md)

### surface-cache

- `measured` [`D_CacheSurface` hit predicate (2026-10-06)](2026-10-06-surface-cache-parity-fix.md)
- `promoted` [The 1800 KB surface-cache wall does not exist (2026-09-29) — root-caused, and the latent win is promoted](2026-09-30-harness-fidelity-and-sourcing.md)
- `rejected` [E4, the surface-cache eviction churn (2026-09-29) — premise falsified before it was built, 0 of 8,886 reb...](2026-09-29-harness-and-cost-model.md)

### texture-spans
- `promoted` [Fourteen-pixel turbulent span loop (2026-10-23) — **+0.000098 FPS (+0.00062793%)**, exact checksum parity](2026-10-23-turbulent-span-fourteen-loop-release-default.md)
- `promoted` [Twelve-pixel turbulent span loop (2026-10-23) — **+0.000754 FPS (+0.00483141%)**, exact checksum parity](2026-10-23-turbulent-span-twelve-loop-release-default.md)
- `promoted` [Four-pixel turbulent span loop (2026-10-23) — **+0.001221667 FPS (+0.00783054%)**, exact checksum parity](2026-10-23-turbulent-span-quad-loop.md)

- `measured` [The general surface-block path is **6.85% of frame at 0.77 cycles per instruction**, and one instruction ...](2026-10-03-region-pricing-sweep.md)
- `measured` [The span16 per-segment setup is 2.37% of frame and contains no x87 at all — **`texture-spans` is re-opened**](2026-10-02-edge-scan-and-texture-spans.md)
- `measured` [Four candidates the pool suggests, and why all four are dead](2026-10-02-edge-scan-and-texture-spans.md)
- `closed` [The unit-stride span premise is zero (2026-10-02) — `texture-spans` is closed, and the arithmetic says wh...](2026-10-02-surf8-bundle-and-promotion.md)
- `measured` [`d_mip_t16` as a constant table (2026-09-29) — landed; the promotion half was not attempted](2026-09-29-harness-and-cost-model.md)
- `measured` [Current texture-span follow-up (2026-09-29)](2026-09-29-alias-and-surface-block-experiments.md)
- `measured` [Texture-span address-update experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span row-cross experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span load-order experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)
- `measured` [Texture-span tail-store experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### world-bsp

- `measured` [`Selector-set frame performance and BSP call removal (2026-10-06)`](2026-10-06-renderer-selector-benchmarks.md)
- `in progress` [`R_RecursiveClipBPoly` now has a selectable i486 assembly entry](2026-10-05-bmodel-polygon-clip-assembly-port.md)
- `in progress` [`demo1` wall leak traced to the split fraction and fixed](2026-10-05-bmodel-polygon-clip-assembly-port.md)
- `in progress` [Edge-list maintenance now has explicit implementation choices](2026-10-05-edge-list-maintenance-assembly-port.md)
- `in progress` [Remaining active-edge maintenance closure](2026-10-05-edge-list-maintenance-assembly-port.md)
- `in progress` [`R_ScanEdges` now has a selectable i486 assembly entry](2026-10-05-scan-edges-assembly-port.md)
- `in progress` [Remaining edge-scan closure](2026-10-05-scan-edges-assembly-port.md)
- `in progress` [`R_EdgeDrawing` now has a selectable i486 assembly entry](2026-10-05-edge-drawing-assembly-port.md)
- `in progress` [Remaining edge-drawing closure](2026-10-05-edge-drawing-assembly-port.md)
- `in progress` [`R_DrawSubmodelPolygons` now has a selectable i486 assembly entry](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [Remaining submodel-polygon closure](2026-10-05-submodel-polygons-assembly-port.md)
- `in progress` [`R_StoreEfrags` now has a selectable i486 assembly entry](2026-10-05-efrag-store-assembly-port.md)
- `in progress` [`R_RenderWorld` now has a selectable i486 assembly entry](2026-10-05-render-world-assembly-port.md)
- `in progress` [Remaining active world-renderer closure](2026-10-05-render-world-assembly-port.md)
- `in progress` [`R_RecursiveWorldNode` now has a selectable assembly walk](2026-10-05-world-bsp-assembly-port.md)
- `measured` [The bmodel frustum `FIXME` (2026-09-29) — premise measured, ceiling is two orders of magnitude short, do ...](2026-09-29-harness-and-cost-model.md)
- `measured` [`world-bsp` decomposed (2026-10-01) — it was never the BSP walk; 85% of it is per-face edge setup](2026-10-01-attribution-corrections.md)
- `measured` [World-BSP frame-count cache experiment (2026-09-28)](2026-09-28-span-micro-experiments.md)

### z-spans

- `promoted` [`D_DrawZSpans` second-step scheduling within SHLD/ROR (2026-10-24) — **+0.000007000 FPS (+0.00004423%)**, exact checksum parity](2026-10-24-zspan-nonnegative-step-between-shld-ror-promoted.md)
- `promoted` [`D_DrawZSpans` positive-gradient cutoff lowered to 21 pixels (2026-10-24) — **+0.000339480 FPS (+0.00214342%)**, exact checksum parity](2026-10-24-zspan-positive-cutoff21-promoted.md)
- `measured` [`D_DrawZSpans` -> exact i486 assembly parity (2026-10-10)](2026-10-10-d-drawzspans-assembly-parity.md)
- `measured` [117 exact C/assembly guarded depth-buffer cases, including negative background depth](2026-10-10-d-drawzspans-assembly-parity.md)
- `measured` [Complete linked i486 audit with zero violations or exemptions](2026-10-10-d-drawzspans-assembly-parity.md)
- `measured` [`z-spans` is the last unpriced region above 2%: **42,031,372 pixels, 3 instructions each, at 1.24 cycles ...](2026-10-03-region-pricing-sweep.md)
- `rejected` [Precomputed `izistep` for the Z-span prologue (2026-09-29) — rejected, and the estimate was wrong in the ...](2026-09-29-harness-and-cost-model.md)
- `rejected` [Z-span x87 prologue (2026-09-29) — measured, and the idea does not survive](2026-09-29-harness-and-cost-model.md)

## Sourced from `BUILD-DOS.md`

These three files were results sitting inside the operational build reference. Each
section below moved verbatim.

### [2026-09-29-offline-precomputation-pass.md](2026-09-29-offline-precomputation-pass.md)

- `Offline precomputation pass (2026-09-29) — one rejection, one cleanup, one closure`
- `Latest PROFILE486 and texture-span STOSW experiment (2026-09-29)`

### [timedemo-baseline-history.md](timedemo-baseline-history.md)

- `Lightmap style accumulation`
- `VGA full-frame copy experiment`
- `Surface-cache capacity and churn`
- `Surface-cache header locality experiment`
- `Lazy viewspantable rebuild`
- `Measured texture-span change`

### [microbenchmark-results.md](microbenchmark-results.md)

- `Memory helper experiment result`
- `Runtime memory-helper result`
- `Texture-axis cache probe result`
- `Surface-cache predicate result`
- `Mip-level selector result`
- `Turbulent-span inner-loop result`
- `Alias-project projection result`
- `Texture-animation frame-selection result`
- `Lightmap normalization result`
- `BSP plane-dot result`
- `BSP frustum-clipping result`
- `BSP frustum-clipping unrolled assembly follow-up (2026-10-16)`
- `Alias bounding-box projection result`
- `Clipped alias vertex transform result`
- `Rejected negative-gradient Z-span unroll`
- [Alias transform indexed integer-coordinate loads (2026-10-23)](2026-10-23-alias-transform-integer-coordinate-table-promoted.md)
- [Alias transform 16-bit coordinate table (2026-10-23)](2026-10-23-alias-transform-u16-coordinate-table-promoted.md)
- [Alias transform early normal-index scale (2026-10-23)](2026-10-23-alias-transform-normal-index-hoist-promoted.md)
