/*
 * Assembly equivalent of src/renderer/r_misc.c:R_PrintAliasStats.
 *
 * Preserve the original cdecl call exactly: pass r_amodels_drawn as the
 * integer vararg and the same format string to Con_Printf. The console owns
 * formatting, logging, text-buffer updates, and screen policy. This leaf uses
 * only baseline 486 integer instructions, preserves EBX/ESI/EDI/EBP, leaves
 * the x87 state unchanged, and restores its two stack arguments after the call.
 */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"

.arch i486
.arch .387
.code32

#ifdef ASM486_ALIAS_STATS
.extern C(r_amodels_drawn)
.extern C(Con_Printf)

.section .rodata
.Lalias_stats_format:
	.asciz "%3i polygon model drawn\n"

.text
.p2align 2
.globl C(R_PrintAliasStats)
.globl C(R_PrintAliasStats_asm486)
C(R_PrintAliasStats):
C(R_PrintAliasStats_asm486):
	pushl	C(r_amodels_drawn)
	pushl	$.Lalias_stats_format
	call	C(Con_Printf)
	addl	$8,%esp
	ret
#endif /* ASM486_ALIAS_STATS */
