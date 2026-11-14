// SCR_DrawNet from screen.c. Preserve the source order and the compiler's
// x87 comparison sequence so finite values and unordered values take the
// same branches as the current i486 C build.
#include "asm_i386.h"
#include "client/asm_screennet.h"

#if defined(ASM486_SCREEN_NET)
.arch i486
.arch .387
.code32

.section .rodata
.p2align 3
.Lsn_stale_threshold:
	.double 0.3

.text
.p2align 4,,15
.globl C(SCR_DrawNet_asm486)
C(SCR_DrawNet_asm486):
	pushl	%ebp
	movl	%esp,%ebp

	// This matches GCC's current C sequence: realtime is binary64, the
	// message timestamp is binary32, and x87 compares their binary64 result.
	fldl	C(realtime)
	fsubs	C(cl)+SN_CL_LAST_RECEIVED_MESSAGE
	fcompl	.Lsn_stale_threshold
	fnstsw	%ax
	// The reference tests C0 only. Keep that emitted-C behavior for unordered
	// comparisons as well as ordinary values.
	testb	$0x01,%ah
	jnz	.Lsn_done

	cmpl	$0,C(cls)+SN_CLS_DEMOPLAYBACK
	jne	.Lsn_done

	// A stale live connection draws the net icon at viewport x + 64.
	movl	C(scr_vrect)+SN_VRECT_X,%eax
	addl	$64,%eax
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_net_fixture_active)
	je	.Lsn_draw_pic
	pushl	C(scr_net)
	pushl	C(scr_vrect)+SN_VRECT_Y
	pushl	%eax
	call	C(Bench486ScreenNetRecordDrawPic)
	addl	$12,%esp
	jmp	.Lsn_done
.Lsn_draw_pic:
#endif
	pushl	C(scr_net)
	pushl	C(scr_vrect)+SN_VRECT_Y
	pushl	%eax
	call	C(Draw_Pic)
	addl	$12,%esp

.Lsn_done:
	leave
	ret
#endif
