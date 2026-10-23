/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
//
// d_scana.s
// x86 assembly-language turbulent texture mapping code
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "asm_draw.h"
#include "d_ifacea.h"

#if id386

	.data

	.text

//----------------------------------------------------------------------
// turbulent texture mapping code
//----------------------------------------------------------------------

.macro TURBULENT8_PIXEL
	movl	%ecx,%eax
	movl	%esi,%edx
	sarl	$16,%eax
	sarl	$16,%edx
	andl	$(CYCLE-1),%eax
	andl	$(CYCLE-1),%edx
	movl	(%ebp,%eax,4),%eax
	movl	(%ebp,%edx,4),%edx
	addl	%esi,%eax
	sarl	$16,%eax
	addl	%ecx,%edx
	sarl	$16,%edx
	andl	$(TURB_TEX_SIZE-1),%eax
	andl	$(TURB_TEX_SIZE-1),%edx
	shll	$6,%edx
	addl	%eax,%edx
	addl	C(r_turb_sstep),%esi
	addl	C(r_turb_tstep),%ecx
	movl	C(r_turb_pbase),%eax
#ifdef ASM486_TURBULENT_STOSB
	movb	(%eax,%edx,1),%al
	stosb
#else
	incl	%edi
	movb	(%eax,%edx,1),%dl
	movb	%dl,-1(%edi)
#endif
.endm

	.p2align 4,,15
.globl C(D_DrawTurbulent8Span_asm486)
C(D_DrawTurbulent8Span_asm486):
	pushl	%ebp				// preserve caller's stack frame pointer
	pushl	%esi				// preserve register variables
	pushl	%edi
	pushl	%ebx

	movl	C(r_turb_s),%esi
	movl	C(r_turb_t),%ecx
	movl	C(r_turb_pdest),%edi
	movl	C(r_turb_spancount),%ebx
	movl	C(r_turb_turb),%ebp	// table base is invariant for this span
	cld

#ifdef ASM486_TURBULENT_TWELVE_LOOP
	subl	$12,%ebx
	jc	.Lturbulent_span_twelve_short
.Lturbulent_span_twelve_loop:
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	subl	$12,%ebx
	jnc	.Lturbulent_span_twelve_loop
	addl	$12,%ebx
	jmp	.Lturbulent_span_twelve_tail
.Lturbulent_span_twelve_short:
	addl	$12,%ebx
.Lturbulent_span_twelve_tail:
	testl	$8,%ebx
	jz	.Lturbulent_span_twelve_four_tail
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
.Lturbulent_span_twelve_four_tail:
	testl	$4,%ebx
	jz	.Lturbulent_span_twelve_two_tail
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
.Lturbulent_span_twelve_two_tail:
	testl	$2,%ebx
	jz	.Lturbulent_span_twelve_one_tail
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
.Lturbulent_span_twelve_one_tail:
	testl	$1,%ebx
	jz	.Lturbulent_span_done
	TURBULENT8_PIXEL
	jmp	.Lturbulent_span_done
#elif defined(ASM486_TURBULENT_OCTA_LOOP)
	cmpl	$8,%ebx
	jl	.Lturbulent_span_octa_tail
	shrl	$3,%ebx
.Lturbulent_span_octa_loop:
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	decl	%ebx
	jnz	.Lturbulent_span_octa_loop
.Lturbulent_span_octa_tail:
	movl	C(r_turb_spancount),%ebx
	andl	$7,%ebx
	testl	$4,%ebx
	jz	.Lturbulent_span_octa_two_tail
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
.Lturbulent_span_octa_two_tail:
	testl	$2,%ebx
	jz	.Lturbulent_span_octa_one_tail
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
.Lturbulent_span_octa_one_tail:
	testl	$1,%ebx
	jz	.Lturbulent_span_done
	TURBULENT8_PIXEL
	jmp	.Lturbulent_span_done
#elif defined(ASM486_TURBULENT_QUAD_LOOP)
	cmpl	$2,%ebx
	jl	.Lturbulent_span_single_pixel
	cmpl	$4,%ebx
	jl	.Lturbulent_span_quad_tail
	shrl	$2,%ebx
.Lturbulent_span_quad_loop:
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	decl	%ebx
	jnz	.Lturbulent_span_quad_loop
.Lturbulent_span_quad_tail:
	movl	C(r_turb_spancount),%ebx
	andl	$3,%ebx
	testl	$2,%ebx
	jz	.Lturbulent_span_quad_odd_tail
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
.Lturbulent_span_quad_odd_tail:
	testl	$1,%ebx
	jz	.Lturbulent_span_done
	TURBULENT8_PIXEL
	jmp	.Lturbulent_span_done

.Lturbulent_span_single_pixel:
	TURBULENT8_PIXEL
#elif defined(ASM486_TURBULENT_PAIR_LOOP)
	cmpl	$2,%ebx
	jl	.Lturbulent_span_single_pixel
	shrl	$1,%ebx
.Lturbulent_span_pair_loop:
	TURBULENT8_PIXEL
	TURBULENT8_PIXEL
	decl	%ebx
	jnz	.Lturbulent_span_pair_loop
	testl	$1,C(r_turb_spancount)
	jz	.Lturbulent_span_done
	TURBULENT8_PIXEL
	jmp	.Lturbulent_span_done

.Lturbulent_span_single_pixel:
	TURBULENT8_PIXEL
#else
.Lturbulent_span_single_loop:
	TURBULENT8_PIXEL
	decl	%ebx
	jg	.Lturbulent_span_single_loop
#endif

.Lturbulent_span_done:

	movl	%edi,C(r_turb_pdest)

	popl	%ebx				// restore register variables
	popl	%edi
	popl	%esi
	popl	%ebp				// restore caller's stack frame pointer
	ret

#endif	// id386
