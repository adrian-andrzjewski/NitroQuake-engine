// SCR_UpdateScreen overlay decision block, split out without changing branch
// order or the order of visible subsystem calls.
#include "asm_i386.h"
#include "asm_menutext.h"
#include "asm_screenoverlays.h"

#if defined(ASM486_SCREEN_OVERLAYS)
.arch i486
.arch .387
.code32

.macro SCREEN_OVERLAY_CALL event, target
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_overlays_fixture_active)
	je	.Lso_real_\@
	pushl	$\event
	call	C(Bench486ScreenOverlaysRecordCall)
	addl	$4,%esp
	jmp	.Lso_done_\@
.Lso_real_\@:
	call	\target
.Lso_done_\@:
#else
	call	\target
#endif
.endm

.text
.p2align 2
.globl C(M_DrawCharacter)
C(M_DrawCharacter):
	pushl	%ebx
	movl	8(%esp),%eax		/* cx */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%ebx
	subl	$320,%ebx
	shrl	$1,%ebx
	addl	%ebx,%eax
	movl	12(%esp),%ecx		/* line */
	movl	16(%esp),%edx		/* character */
	pushl	%edx
	pushl	%ecx
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486MenuTextDrawCharacter)
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	popl	%ebx
	ret

.p2align 2
.globl C(M_Print)
C(M_Print):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* cx */
	movl	20(%esp),%esi		/* cy */
	movl	24(%esp),%edi		/* str */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%eax
	subl	$320,%eax
	shrl	$1,%eax
	addl	%eax,%ebx			/* center once for the whole string */

.Lm_print_loop:
	movsbl	(%edi),%eax
	testl	%eax,%eax
	je	.Lm_print_done
	addl	$128,%eax
	pushl	%eax
	pushl	%esi
	pushl	%ebx
#ifdef BENCH486
	call	C(Bench486MenuTextDrawCharacter)
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	addl	$8,%ebx
	incl	%edi
	jmp	.Lm_print_loop

.Lm_print_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(M_PrintWhite)
C(M_PrintWhite):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* cx */
	movl	20(%esp),%esi		/* cy */
	movl	24(%esp),%edi		/* str */
	movl	C(vid)+MT_VID_WIDTH_OFFSET,%eax
	subl	$320,%eax
	shrl	$1,%eax
	addl	%eax,%ebx			/* center once for the whole string */

.Lm_print_white_loop:
	movsbl	(%edi),%eax
	testl	%eax,%eax
	je	.Lm_print_white_done
	pushl	%eax
	pushl	%esi
	pushl	%ebx
#ifdef BENCH486
	call	C(Bench486MenuTextDrawCharacter)
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	addl	$8,%ebx
	incl	%edi
	jmp	.Lm_print_white_loop

.Lm_print_white_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

/* Pause plaque: preserve the C float truth test, pause gate and unsigned placement. */
.p2align 2
.globl C(SCR_DrawPause)
.globl C(SCR_DrawPause_asm486)
C(SCR_DrawPause):
C(SCR_DrawPause_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$12,%esp
	/* Match the C build's x87 C3 test, including its unordered-value branch. */
	fldz
	fcomps	C(scr_showpause)+SO_CVAR_VALUE
	fnstsw	%ax
	testb	$0x40,%ah
	jne	.Lso_pause_done
	cmpl	$0,C(cl)+SO_CLIENT_PAUSED
	je	.Lso_pause_done
	subl	$12,%esp
	pushl	$.Lso_pause_path
#ifdef BENCH486
	call	C(Bench486ScreenOverlayCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
	movl	%eax,%ebx
	movl	C(vid)+SO_VID_WIDTH,%eax
	subl	SO_QPIC_WIDTH(%ebx),%eax
	shrl	$1,%eax
	movl	C(vid)+SO_VID_HEIGHT,%edx
	subl	$48,%edx
	subl	SO_QPIC_HEIGHT(%ebx),%edx
	shrl	$1,%edx
	subl	$12,%esp
	pushl	%ebx
	pushl	%edx
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486ScreenOverlayDrawPic)
#else
	call	C(Draw_Pic)
#endif
	addl	$24,%esp
.Lso_pause_done:
	leal	-4(%ebp),%esp
	popl	%ebx
	popl	%ebp
	ret

/* Loading plaque: a single flag gate followed by the same unsigned placement. */
.p2align 2
.globl C(SCR_DrawLoading)
.globl C(SCR_DrawLoading_asm486)
C(SCR_DrawLoading):
C(SCR_DrawLoading_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$12,%esp
	cmpl	$0,C(scr_drawloading)
	je	.Lso_loading_done
	subl	$12,%esp
	pushl	$.Lso_loading_path
#ifdef BENCH486
	call	C(Bench486ScreenOverlayCachePic)
#else
	call	C(Draw_CachePic)
#endif
	addl	$16,%esp
	movl	%eax,%ebx
	movl	C(vid)+SO_VID_WIDTH,%eax
	subl	SO_QPIC_WIDTH(%ebx),%eax
	shrl	$1,%eax
	movl	C(vid)+SO_VID_HEIGHT,%edx
	subl	$48,%edx
	subl	SO_QPIC_HEIGHT(%ebx),%edx
	shrl	$1,%edx
	subl	$12,%esp
	pushl	%ebx
	pushl	%edx
	pushl	%eax
#ifdef BENCH486
	call	C(Bench486ScreenOverlayDrawPic)
#else
	call	C(Draw_Pic)
#endif
	addl	$24,%esp
.Lso_loading_done:
	leal	-4(%ebp),%esp
	popl	%ebx
	popl	%ebp
	ret

.p2align 4,,15
.globl C(SCR_DrawScreenOverlays_asm486)
C(SCR_DrawScreenOverlays_asm486):
	pushl	%ebp
	movl	%esp,%ebp

	cmpl	$0,C(scr_drawdialog)
	jne	.Lso_dialog
	cmpl	$0,C(scr_drawloading)
	jne	.Lso_loading

	cmpl	$1,C(cl)+SO_CLIENT_INTERMISSION
	jne	.Lso_check_intermission_two
	cmpl	$SO_KEY_GAME,C(key_dest)
	jne	.Lso_normal
	SCREEN_OVERLAY_CALL 5,_Sbar_IntermissionOverlay
	jmp	.Lso_done

.Lso_check_intermission_two:
	cmpl	$2,C(cl)+SO_CLIENT_INTERMISSION
	jne	.Lso_check_intermission_three
	cmpl	$SO_KEY_GAME,C(key_dest)
	jne	.Lso_normal
	SCREEN_OVERLAY_CALL 6,_Sbar_FinaleOverlay
	SCREEN_OVERLAY_CALL 7,_SCR_CheckDrawCenterString
	jmp	.Lso_done

.Lso_check_intermission_three:
	cmpl	$3,C(cl)+SO_CLIENT_INTERMISSION
	jne	.Lso_normal
	cmpl	$SO_KEY_GAME,C(key_dest)
	jne	.Lso_normal
	SCREEN_OVERLAY_CALL 7,_SCR_CheckDrawCenterString
	jmp	.Lso_done

.Lso_dialog:
	SCREEN_OVERLAY_CALL 1,_Sbar_Draw
	SCREEN_OVERLAY_CALL 2,_Draw_FadeScreen
	SCREEN_OVERLAY_CALL 3,_SCR_DrawNotifyString
	movl	$1,C(scr_copyeverything)
	jmp	.Lso_done

.Lso_loading:
	SCREEN_OVERLAY_CALL 4,_SCR_DrawLoading
	SCREEN_OVERLAY_CALL 1,_Sbar_Draw
	jmp	.Lso_done

.Lso_normal:
#if defined(ASM486_SCREEN_DRAW_RAM)
	SCREEN_OVERLAY_CALL 8,_SCR_DrawRam_asm486
#else
	SCREEN_OVERLAY_CALL 8,_SCR_DrawRam
#endif
#if defined(ASM486_SCREEN_NET)
	SCREEN_OVERLAY_CALL 9,_SCR_DrawNet_asm486
#else
	SCREEN_OVERLAY_CALL 9,_SCR_DrawNet
#endif
#if defined(ASM486_SCREEN_TURTLE)
	SCREEN_OVERLAY_CALL 10,_SCR_DrawTurtle_asm486
#else
	SCREEN_OVERLAY_CALL 10,_SCR_DrawTurtle
#endif
	SCREEN_OVERLAY_CALL 11,_SCR_DrawPause
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,12(%ebp)
	je	.Lso_no_trace_before_center
	pushl	$0
	pushl	$0
	pushl	8(%ebp)
	pushl	$9
	call	C(Bench486ScreenCenterTraceGlyph)
	addl	$16,%esp
.Lso_no_trace_before_center:
#endif
	SCREEN_OVERLAY_CALL 7,_SCR_CheckDrawCenterString
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,12(%ebp)
	je	.Lso_no_trace_after_center
	pushl	$0
	pushl	$0
	pushl	8(%ebp)
	pushl	$10
	call	C(Bench486ScreenCenterTraceGlyph)
	addl	$16,%esp
.Lso_no_trace_after_center:
#endif
	SCREEN_OVERLAY_CALL 1,_Sbar_Draw
	SCREEN_OVERLAY_CALL 12,_SCR_DrawConsole
	SCREEN_OVERLAY_CALL 13,_M_Draw
.Lso_done:
	leave
	ret

// Per-frame console selection and state update from SCR_DrawConsole.
.p2align 4,,15
.globl C(SCR_DrawConsole)
C(SCR_DrawConsole):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$12,%esp
	movl	C(scr_con_current),%eax
	andl	$0x7fffffff,%eax
	je	.Lscr_draw_console_notify

	// C float-to-int conversion truncates independently of the active x87 mode.
	fnstcw	-6(%ebp)
	movzwl	-6(%ebp),%eax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax
	movw	%ax,-8(%ebp)
	fldcw	-8(%ebp)
	flds	C(scr_con_current)
	fistpl	-16(%ebp)
	fldcw	-6(%ebp)

	movl	$1,C(scr_copyeverything)
	pushl	$1
	pushl	-16(%ebp)
#ifdef BENCH486
	call	C(Bench486ScreenConsoleDrawCall)
#else
	call	C(Con_DrawConsole)
#endif
	addl	$8,%esp
	movl	$0,C(clearconsole)
	jmp	.Lscr_draw_console_done

.Lscr_draw_console_notify:
	movl	C(key_dest),%ebx
	cmpl	$SO_KEY_GAME,%ebx
	je	.Lscr_draw_console_notify_call
	cmpl	$SO_KEY_MESSAGE,%ebx
	jne	.Lscr_draw_console_done
.Lscr_draw_console_notify_call:
#ifdef BENCH486
	call	C(Bench486ScreenNotifyDrawCall)
#else
	call	C(Con_DrawNotify)
#endif

.Lscr_draw_console_done:
	addl	$12,%esp
	popl	%ebx
	leave
	ret

.section .rodata
.p2align 2
.Lso_pause_path:
	.asciz	"gfx/pause.lmp"
.Lso_loading_path:
	.asciz	"gfx/loading.lmp"

#endif
