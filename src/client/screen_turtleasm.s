// SCR_DrawTurtle from screen.c. The x87 comparisons mirror the current
// i486 C object, including its condition-code tests for unordered values.
#include "asm_i386.h"
#include "client/asm_screenturtle.h"

#if defined(ASM486_SCREEN_TURTLE)
.arch i486
.arch .387
.code32

.data
.p2align 2
.globl C(scr_turtle_count_asm486)
C(scr_turtle_count_asm486):
	.long 0

.section .rodata
.p2align 3
.Lst_turtle_frame_threshold:
	.double 0.1

.text
.p2align 4,,15
.globl C(SCR_DrawTurtle_asm486)
C(SCR_DrawTurtle_asm486):
	// GCC emits FLDZ/FCOMPS and tests C3 for `!scr_showturtle.value`.
	fldz
	fcomps	C(scr_showturtle)+ST_CVAR_VALUE
	fnstsw	%ax
	testb	$0x40,%ah
	jnz	.Lst_done

	// Compare 0.1 to host_frametime and test C0/C2/C3 as in the C object.
	fldl	.Lst_turtle_frame_threshold
	fcompl	C(host_frametime)
	fnstsw	%ax
	testb	$0x45,%ah
	je	.Lst_reset_count

	incl	C(scr_turtle_count_asm486)
	cmpl	$2,C(scr_turtle_count_asm486)
	jle	.Lst_done

	// The turtle picture uses the viewport origin without additional offsets.
	movl	C(scr_vrect)+ST_VRECT_X,%eax
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_turtle_fixture_active)
	je	.Lst_draw_pic
	pushl	C(scr_turtle)
	pushl	C(scr_vrect)+ST_VRECT_Y
	pushl	%eax
	call	C(Bench486ScreenTurtleRecordDrawPic)
	addl	$12,%esp
	jmp	.Lst_done
.Lst_draw_pic:
#endif
	pushl	C(scr_turtle)
	pushl	C(scr_vrect)+ST_VRECT_Y
	pushl	%eax
	call	C(Draw_Pic)
	addl	$12,%esp
	jmp	.Lst_done

.Lst_reset_count:
	movl	$0,C(scr_turtle_count_asm486)
.Lst_done:
	ret
#endif
