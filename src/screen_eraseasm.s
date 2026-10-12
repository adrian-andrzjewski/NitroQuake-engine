// SCR_EraseCenterString from screen.c, expressed as auditable i486 + 387 code.
//
// 32-bit DJGPP cdecl, no arguments or return value. The active path preserves
// the original unsigned vid.height * 0.35 conversion and sets only RC=chop
// around FISTP, because a C double-to-int conversion truncates independently
// of the caller's rounding mode. The full x87 control word is restored.
// Original behavior: screen.c:SCR_EraseCenterString.
#include "asm_i386.h"
#include "asm_screenerase.h"

#if defined(ASM486_SCREEN_ERASE_CENTER_STRING)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(SCR_EraseCenterString_asm486)
.globl C(SCR_EraseCenterString)
C(SCR_EraseCenterString):
C(SCR_EraseCenterString_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$24,%esp
// Locals: unsigned height as qword -24..-17, caller CW -10,
// truncate CW -12, converted Y -16.
	// The post-increment comparison uses the old count and is signed, just as
	// the C int expression. Equality remains on the active path.
	movl	C(scr_erase_center),%eax
	incl	C(scr_erase_center)
	cmpl	C(vid)+se_vid_numpages_offset,%eax
	jg	.Lscreen_erase_done_early

	cmpl	$4,C(scr_center_lines)
	jg	.Lscreen_erase_y_48

// vid.height is unsigned. Match GCC's reference lowering by widening it to
// an unsigned qword before FILD; adding 2^32 after a signed FILD would round
// differently when the caller selects 24-bit x87 precision.
	movl	C(vid)+se_vid_height_offset,%eax
	movl	%eax,-24(%ebp)
	movl	$0,-20(%ebp)
	fildq	-24(%ebp)
	fmull	.Lscreen_erase_point_35

// C's implicit double-to-int conversion truncates toward zero. Do not let
// the caller's RC bits change this one conversion; preserve PC and masks.
	fnstcw	-10(%ebp)
	movw	-10(%ebp),%ax
	orw	$0x0c00,%ax
	movw	%ax,-12(%ebp)
	fldcw	-12(%ebp)
	fistpl	-16(%ebp)
	fldcw	-10(%ebp)
	movl	-16(%ebp),%eax
	jmp	.Lscreen_erase_tile_clear

.Lscreen_erase_y_48:
	movl	$48,%eax
.Lscreen_erase_tile_clear:
	movl	$1,C(scr_copytop)
	movl	C(scr_erase_lines),%ecx
	sall	$3,%ecx
	pushl	%ecx
	pushl	C(vid)+20 // width
	pushl	%eax      // Y
	pushl	$0         // X
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_erase_fixture_active)
	je	.Lscreen_erase_real_tile_clear
	call	C(Bench486ScreenEraseTileClear)
	jmp	.Lscreen_erase_tile_clear_done
.Lscreen_erase_real_tile_clear:
	call	C(Draw_TileClear)
.Lscreen_erase_tile_clear_done:
#else
	call	C(Draw_TileClear)
#endif
	addl	$16,%esp
	leave
	ret

.Lscreen_erase_done_early:
	movl	$0,C(scr_erase_lines)
	leave
	ret

.section .rodata
.align 8
.Lscreen_erase_point_35:
	.double 0.35
#endif
