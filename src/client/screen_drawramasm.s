// SCR_DrawRam from screen.c, translated without changing the indicator rule.
// Quake uses IEEE binary32 cvars. Clearing the sign bit and testing the
// remaining bits is exactly C's !float truth test: both signed zeros are false,
// while every finite nonzero value, infinity, and NaN is true. This also avoids
// changing the caller's x87 state.
#include "asm_i386.h"
#include "client/asm_screendrawram.h"

#if defined(ASM486_SCREEN_DRAW_RAM)
.arch i486
.code32

.text
.p2align 4,,15
.globl C(SCR_DrawRam_asm486)
C(SCR_DrawRam_asm486):
	pushl	%ebp
	movl	%esp,%ebp

	// The original C routine returns if showram is zero, then if the surface
	// cache is not thrashing. Do not read the viewport or image on either path.
	movl	C(scr_showram)+SDR_CVAR_VALUE,%eax
	andl	$0x7fffffff,%eax
	jz	.Lsdr_done
	cmpl	$0,C(r_cache_thrash)
	je	.Lsdr_done

	// Draw the RAM icon 32 pixels right of the current viewport origin.
	movl	C(scr_vrect)+SDR_VRECT_X,%eax
	addl	$32,%eax
	pushl	C(scr_ram)
	pushl	C(scr_vrect)+SDR_VRECT_Y
	pushl	%eax
	call	C(Draw_Pic)
	addl	$12,%esp

.Lsdr_done:
	leave
	ret
#endif
