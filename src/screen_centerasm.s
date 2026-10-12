// SCR_DrawCenterString from screen.c, expressed as auditable i486 assembly.
//
// 32-bit DJGPP cdecl, no arguments or return value. This follows the original
// 40-character line scan, unsigned horizontal centering, signed-char glyph
// argument, intermission print budget, line skipping, and x87 truncation.
// Original behavior: screen.c:SCR_DrawCenterString.
#include "asm_i386.h"
#include "asm_screencenter.h"

#if defined(ASM486_SCREEN_CENTER_STRING)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(SCR_DrawCenterString_asm486)
#ifdef ASM486_SCREEN_CENTER_STRING
.globl C(SCR_DrawCenterString)
C(SCR_DrawCenterString):
#endif
C(SCR_DrawCenterString_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$20,%esp
// Locals: saved CW -14, truncate CW -16, y -20, line length -24,
//         remaining print budget -28.
	movl	$0,C(scr_erase_center)

// The original C expression is evaluated as float arithmetic, then converted
// to int with truncation toward zero. FISTP uses the caller's RC, so select
// truncate only around the conversion and restore the full control word.
	cmpl	$0,C(cl)+sc_client_intermission_offset
	je	.Lscreen_center_unlimited
	fldl	C(cl)+sc_client_time_offset
	fsubs	C(scr_centertime_start)
	fmuls	C(scr_printspeed)+sc_cvar_value_offset
	fnstcw	-14(%ebp)
	movw	-14(%ebp),%ax
	orw	$0x0c00,%ax
	movw	%ax,-16(%ebp)
	fldcw	-16(%ebp)
	fistpl	-28(%ebp)
	fldcw	-14(%ebp)
	jmp	.Lscreen_center_budget_ready
.Lscreen_center_unlimited:
	movl	$9999,-28(%ebp)
.Lscreen_center_budget_ready:
	movl	$C(scr_centerstring),%ebx

	cmpl	$4,C(scr_center_lines)
	jg	.Lscreen_center_y_48
	movl	C(vid)+sc_vid_height_offset,%eax
	fildl	C(vid)+sc_vid_height_offset
	testl	%eax,%eax
	jns	.Lscreen_center_height_unsigned
	fnstcw	-14(%ebp)
	movw	-14(%ebp),%ax
	orw	$0x0300,%ax
	movw	%ax,-16(%ebp)
	fldcw	-16(%ebp)
	faddl	.Lscreen_center_two_32
	fldcw	-14(%ebp)
.Lscreen_center_height_unsigned:
	fmull	.Lscreen_center_point_35
	fnstcw	-14(%ebp)
	movw	-14(%ebp),%ax
	orw	$0x0c00,%ax
	movw	%ax,-16(%ebp)
	fldcw	-16(%ebp)
	fistpl	-20(%ebp)
	fldcw	-14(%ebp)
	jmp	.Lscreen_center_line
.Lscreen_center_y_48:
	movl	$48,-20(%ebp)

.Lscreen_center_line:
	xorl	%esi,%esi
.Lscreen_center_scan:
	cmpl	$40,%esi
	jge	.Lscreen_center_scan_done
	movb	(%ebx,%esi),%al
	testb	%al,%al
	je	.Lscreen_center_scan_done
	cmpb	$10,%al
	je	.Lscreen_center_scan_done
	incl	%esi
	jmp	.Lscreen_center_scan

.Lscreen_center_scan_done:
	movl	%esi,-24(%ebp)
	// vid.width is unsigned; subtraction and division retain modulo-2^32 rules.
	movl	C(vid)+sc_vid_width_offset,%edi
	leal	(,%esi,8),%eax
	subl	%eax,%edi
	shrl	$1,%edi
	xorl	%esi,%esi

.Lscreen_center_draw:
	cmpl	-24(%ebp),%esi
	jge	.Lscreen_center_draw_done
	movsbl	(%ebx,%esi),%eax
	pushl	%eax
	pushl	-20(%ebp)
	pushl	%edi
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_center_fixture_active)
	je	.Lscreen_center_real_character
	call	C(Bench486ScreenCenterStringCharacter)
	jmp	.Lscreen_center_character_call_done
.Lscreen_center_real_character:
	call	C(Draw_Character)
.Lscreen_center_character_call_done:
#else
	call	C(Draw_Character)
#endif
	addl	$12,%esp
	addl	$8,%edi
	movl	-28(%ebp),%eax
	decl	-28(%ebp)
	testl	%eax,%eax
	je	.Lscreen_center_return
	incl	%esi
	jmp	.Lscreen_center_draw

.Lscreen_center_draw_done:
	addl	$8,-20(%ebp)
.Lscreen_center_skip:
	movb	(%ebx),%al
	testb	%al,%al
	je	.Lscreen_center_return
	cmpb	$10,%al
	je	.Lscreen_center_newline
	incl	%ebx
	jmp	.Lscreen_center_skip
.Lscreen_center_newline:
	incl	%ebx
	jmp	.Lscreen_center_line

.Lscreen_center_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.section .rodata
.align 8
.Lscreen_center_point_35:
	.double 0.35
.Lscreen_center_two_32:
	.double 4294967296.0
#endif
