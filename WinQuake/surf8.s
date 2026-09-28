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
// surf8.s
// x86 assembly-language 8 bpp surface block drawing code.
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "asm_draw.h"

#if	id386

	.data

sb_v:		.long	0

	.text

	.p2align 4,,15
.globl C(R_Surf8Start)
C(R_Surf8Start):

//----------------------------------------------------------------------
// Surface block drawer for mip level 0
//----------------------------------------------------------------------

	.p2align 4,,15
.globl C(R_DrawSurfaceBlock8_mip0)
C(R_DrawSurfaceBlock8_mip0):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

//		for (v=0 ; v<numvblocks ; v++)
//		{
	movl	C(r_lightptr),%ebx
	movl	C(r_numvblocks),%eax

	movl	%eax,sb_v
	movl	C(prowdestbase),%edi

	movl	C(pbasesource),%esi

Lv_loop_mip0:

//			lightleft = lightptr[0];
//			lightright = lightptr[1];
//			lightdelta = (lightleft - lightright) & 0xFFFFF;
	movl	(%ebx),%eax			// lightleft
	movl	4(%ebx),%edx		// lightright

	movl	%eax,%ebp
	movl	C(r_lightwidth),%ecx

	movl	%edx,C(lightright)
	subl	%edx,%ebp

	andl	$0xFFFFF,%ebp
	leal	(%ebx,%ecx,4),%ebx

//			lightptr += lightwidth;
	movl	%ebx,C(r_lightptr)

//			lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//			lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//			lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//					0xF0000000;
	movl	4(%ebx),%ecx	// lightptr[1]
	movl	(%ebx),%ebx		// lightptr[0]

	subl	%eax,%ebx
	subl	%edx,%ecx

	sarl	$4,%ecx
	orl		$0xF0000000,%ebp

	sarl	$4,%ebx
	movl	%ecx,C(lightrightstep)

	subl	%ecx,%ebx
	andl	$0xFFFFF,%ebx

	orl		$0xF0000000,%ebx
	subl	%ecx,%ecx	// high word must be 0 in loop for addressing

	movl	%ebx,C(lightdeltastep)
	subl	%ebx,%ebx	// high word must be 0 in loop for addressing
#if defined(ASM486_SURF8_MIP0_ROWS4) || defined(ASM486_SURF8_MIP0_ROWS8) || defined(ASM486_SURF8_MIP0_ROWS16)
.macro SURF8_MIP0_ROW suffix
	movl	%ebp,C(lightdelta)
	movb	14(%esi),%cl

	sarl	$4,%ebp
	movb	%dh,%bh

	movb	15(%esi),%bl
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_0:
	movb	13(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_1:
	movb	12(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_2:

	movb	11(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_3:

	movb	10(%esi),%cl
	movl	%eax,12(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_4:
	movb	9(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_5:
	movb	8(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_6:

	movb	7(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_7:

	movb	6(%esi),%cl
	movl	%eax,8(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_8:
	movb	5(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_9:
	movb	4(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_10:

	movb	3(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_11:

	movb	2(%esi),%cl
	movl	%eax,4(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_12:
	movb	1(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_13:
	movb	(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	movb	0x12345678(%ebx),%ah
.LLBPatch\suffix\()_14:
	movl	C(lightright),%edx

	movb	0x12345678(%ecx),%al
.LLBPatch\suffix\()_15:
	movl	C(lightdelta),%ebp

	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi

	addl	C(lightrightstep),%edx
	addl	C(lightdeltastep),%ebp
	movl	%edx,C(lightright)
.endm

#ifdef ASM486_SURF8_MIP0_ROWS16
Lblockloop8_mip0_rows16:
#elif defined(ASM486_SURF8_MIP0_ROWS8)
Lblockloop8_mip0_rows8:
#else
Lblockloop8_mip0_rows4:
#endif
	SURF8_MIP0_ROW a
	SURF8_MIP0_ROW b
	SURF8_MIP0_ROW c
	SURF8_MIP0_ROW d
#ifdef ASM486_SURF8_MIP0_ROWS16
	SURF8_MIP0_ROW e
	SURF8_MIP0_ROW f
	SURF8_MIP0_ROW g
	SURF8_MIP0_ROW h
	SURF8_MIP0_ROW i
	SURF8_MIP0_ROW j
	SURF8_MIP0_ROW k
	SURF8_MIP0_ROW l
	SURF8_MIP0_ROW m
	SURF8_MIP0_ROW n
	SURF8_MIP0_ROW o
	SURF8_MIP0_ROW p
	jc		Lblockloop8_mip0_rows16
#elif defined(ASM486_SURF8_MIP0_ROWS8)
	SURF8_MIP0_ROW e
	SURF8_MIP0_ROW f
	SURF8_MIP0_ROW g
	SURF8_MIP0_ROW h
	jc		Lblockloop8_mip0_rows8
#else
	jc		Lblockloop8_mip0_rows4
#endif
#else
Lblockloop8_mip0:
	movl	%ebp,C(lightdelta)
	movb	14(%esi),%cl

	sarl	$4,%ebp
	movb	%dh,%bh

	movb	15(%esi),%bl
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch0:
	movb	13(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch1:
	movb	12(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
LBPatch2:

	movb	11(%esi),%bl
	movb	0x12345678(%ecx),%al
LBPatch3:

	movb	10(%esi),%cl
	movl	%eax,12(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch4:
	movb	9(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch5:
	movb	8(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
LBPatch6:

	movb	7(%esi),%bl
	movb	0x12345678(%ecx),%al
LBPatch7:

	movb	6(%esi),%cl
	movl	%eax,8(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch8:
	movb	5(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch9:
	movb	4(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
LBPatch10:

	movb	3(%esi),%bl
	movb	0x12345678(%ecx),%al
LBPatch11:

	movb	2(%esi),%cl
	movl	%eax,4(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch12:
	movb	1(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch13:
	movb	(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	movb	0x12345678(%ebx),%ah
LBPatch14:
	movl	C(lightright),%edx

	movb	0x12345678(%ecx),%al
LBPatch15:
	movl	C(lightdelta),%ebp

	movl	%eax,(%edi)

	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi

	addl	C(lightrightstep),%edx
	addl	C(lightdeltastep),%ebp

	movl	%edx,C(lightright)
	jc		Lblockloop8_mip0
#endif

//			if (pbasesource >= r_sourcemax)
//				pbasesource -= stepback;

	cmpl	C(r_sourcemax),%esi
	jb		LSkip_mip0
	subl	C(r_stepback),%esi
LSkip_mip0:

	movl	C(r_lightptr),%ebx
	decl	sb_v

	jnz		Lv_loop_mip0

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret


//----------------------------------------------------------------------
// Surface block drawer for mip level 1
//----------------------------------------------------------------------

	.p2align 4,,15
.globl C(R_DrawSurfaceBlock8_mip1)
C(R_DrawSurfaceBlock8_mip1):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

//		for (v=0 ; v<numvblocks ; v++)
//		{
	movl	C(r_lightptr),%ebx
	movl	C(r_numvblocks),%eax

	movl	%eax,sb_v
	movl	C(prowdestbase),%edi

	movl	C(pbasesource),%esi

Lv_loop_mip1:

//			lightleft = lightptr[0];
//			lightright = lightptr[1];
//			lightdelta = (lightleft - lightright) & 0xFFFFF;
	movl	(%ebx),%eax			// lightleft
	movl	4(%ebx),%edx		// lightright

	movl	%eax,%ebp
	movl	C(r_lightwidth),%ecx

	movl	%edx,C(lightright)
	subl	%edx,%ebp

	andl	$0xFFFFF,%ebp
	leal	(%ebx,%ecx,4),%ebx

//			lightptr += lightwidth;
	movl	%ebx,C(r_lightptr)

//			lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//			lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//			lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//					0xF0000000;
	movl	4(%ebx),%ecx	// lightptr[1]
	movl	(%ebx),%ebx		// lightptr[0]

	subl	%eax,%ebx
	subl	%edx,%ecx

	sarl	$3,%ecx
	orl		$0x70000000,%ebp

	sarl	$3,%ebx
	movl	%ecx,C(lightrightstep)

	subl	%ecx,%ebx
	andl	$0xFFFFF,%ebx

	orl		$0xF0000000,%ebx
	subl	%ecx,%ecx	// high word must be 0 in loop for addressing

	movl	%ebx,C(lightdeltastep)
	subl	%ebx,%ebx	// high word must be 0 in loop for addressing

#ifdef ASM486_SURF8_MIP1_ROWS8
.macro SURF8_MIP1_ROW suffix
	movl	%ebp,C(lightdelta)
	movb	6(%esi),%cl

	sarl	$3,%ebp
	movb	%dh,%bh

	movb	7(%esi),%bl
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatchm1\suffix\()_0:
	movb	5(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatchm1\suffix\()_1:
	movb	4(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
.LLBPatchm1\suffix\()_2:

	movb	3(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1\suffix\()_3:

	movb	2(%esi),%cl
	movl	%eax,4(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatchm1\suffix\()_4:
	movb	1(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatchm1\suffix\()_5:
	movb	(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	movb	0x12345678(%ebx),%ah
.LLBPatchm1\suffix\()_6:
	movl	C(lightright),%edx

	movb	0x12345678(%ecx),%al
.LLBPatchm1\suffix\()_7:
	movl	C(lightdelta),%ebp

	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	addl	C(lightrightstep),%edx
	addl	C(lightdeltastep),%ebp
	movl	%edx,C(lightright)
.endm

Lblockloop8_mip1_rows8:
	SURF8_MIP1_ROW a
	SURF8_MIP1_ROW b
	SURF8_MIP1_ROW c
	SURF8_MIP1_ROW d
	SURF8_MIP1_ROW e
	SURF8_MIP1_ROW f
	SURF8_MIP1_ROW g
	SURF8_MIP1_ROW h
	jc		Lblockloop8_mip1_rows8
#else
Lblockloop8_mip1:
	movl	%ebp,C(lightdelta)
	movb	6(%esi),%cl

	sarl	$3,%ebp
	movb	%dh,%bh

	movb	7(%esi),%bl
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch22:
	movb	5(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch23:
	movb	4(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	addl	%ebp,%edx
	movb	0x12345678(%ebx),%ah
LBPatch24:

	movb	3(%esi),%bl
	movb	0x12345678(%ecx),%al
LBPatch25:

	movb	2(%esi),%cl
	movl	%eax,4(%edi)

	movb	%dh,%bh
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch26:
	movb	1(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch27:
	movb	(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	movb	0x12345678(%ebx),%ah
LBPatch28:
	movl	C(lightright),%edx

	movb	0x12345678(%ecx),%al
LBPatch29:
	movl	C(lightdelta),%ebp

	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	addl	C(lightrightstep),%edx
	addl	C(lightdeltastep),%ebp
	movl	%edx,C(lightright)

	jc		Lblockloop8_mip1
#endif

//			if (pbasesource >= r_sourcemax)
//				pbasesource -= stepback;

	cmpl	C(r_sourcemax),%esi
	jb		LSkip_mip1
	subl	C(r_stepback),%esi
LSkip_mip1:

	movl	C(r_lightptr),%ebx
	decl	sb_v

	jnz		Lv_loop_mip1

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret


//----------------------------------------------------------------------
// Surface block drawer for mip level 2
//----------------------------------------------------------------------

	.p2align 4,,15
.globl C(R_DrawSurfaceBlock8_mip2)
C(R_DrawSurfaceBlock8_mip2):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

//		for (v=0 ; v<numvblocks ; v++)
//		{
	movl	C(r_lightptr),%ebx
	movl	C(r_numvblocks),%eax

	movl	%eax,sb_v
	movl	C(prowdestbase),%edi

	movl	C(pbasesource),%esi

Lv_loop_mip2:

//			lightleft = lightptr[0];
//			lightright = lightptr[1];
//			lightdelta = (lightleft - lightright) & 0xFFFFF;
	movl	(%ebx),%eax			// lightleft
	movl	4(%ebx),%edx		// lightright

	movl	%eax,%ebp
	movl	C(r_lightwidth),%ecx

	movl	%edx,C(lightright)
	subl	%edx,%ebp

	andl	$0xFFFFF,%ebp
	leal	(%ebx,%ecx,4),%ebx

//			lightptr += lightwidth;
	movl	%ebx,C(r_lightptr)

//			lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//			lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//			lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//					0xF0000000;
	movl	4(%ebx),%ecx	// lightptr[1]
	movl	(%ebx),%ebx		// lightptr[0]

	subl	%eax,%ebx
	subl	%edx,%ecx

	sarl	$2,%ecx
	orl		$0x30000000,%ebp

	sarl	$2,%ebx
	movl	%ecx,C(lightrightstep)

	subl	%ecx,%ebx

	andl	$0xFFFFF,%ebx

	orl		$0xF0000000,%ebx
	subl	%ecx,%ecx	// high word must be 0 in loop for addressing

	movl	%ebx,C(lightdeltastep)
	subl	%ebx,%ebx	// high word must be 0 in loop for addressing

Lblockloop8_mip2:
	movl	%ebp,C(lightdelta)
	movb	2(%esi),%cl

	sarl	$2,%ebp
	movb	%dh,%bh

	movb	3(%esi),%bl
	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
LBPatch18:
	movb	1(%esi),%bl

	movb	0x12345678(%ecx),%al
LBPatch19:
	movb	(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	movb	0x12345678(%ebx),%ah
LBPatch20:
	movl	C(lightright),%edx

	movb	0x12345678(%ecx),%al
LBPatch21:
	movl	C(lightdelta),%ebp

	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	addl	C(lightrightstep),%edx
	addl	C(lightdeltastep),%ebp
	movl	%edx,C(lightright)

	jc		Lblockloop8_mip2

//			if (pbasesource >= r_sourcemax)
//				pbasesource -= stepback;

	cmpl	C(r_sourcemax),%esi
	jb		LSkip_mip2
	subl	C(r_stepback),%esi
LSkip_mip2:

	movl	C(r_lightptr),%ebx
	decl	sb_v

	jnz		Lv_loop_mip2

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret


//----------------------------------------------------------------------
// Surface block drawer for mip level 3
//----------------------------------------------------------------------

	.p2align 4,,15
.globl C(R_DrawSurfaceBlock8_mip3)
C(R_DrawSurfaceBlock8_mip3):
	pushl	%ebp				// preserve caller's stack frame
	pushl	%edi
	pushl	%esi				// preserve register variables
	pushl	%ebx

//		for (v=0 ; v<numvblocks ; v++)
//		{
	movl	C(r_lightptr),%ebx
	movl	C(r_numvblocks),%eax

	movl	%eax,sb_v
	movl	C(prowdestbase),%edi

	movl	C(pbasesource),%esi

Lv_loop_mip3:

//			lightleft = lightptr[0];
//			lightright = lightptr[1];
//			lightdelta = (lightleft - lightright) & 0xFFFFF;
	movl	(%ebx),%eax			// lightleft
	movl	4(%ebx),%edx		// lightright

	movl	%eax,%ebp
	movl	C(r_lightwidth),%ecx

	movl	%edx,C(lightright)
	subl	%edx,%ebp

	andl	$0xFFFFF,%ebp
	leal	(%ebx,%ecx,4),%ebx

	movl	%ebp,C(lightdelta)
//			lightptr += lightwidth;
	movl	%ebx,C(r_lightptr)

//			lightleftstep = (lightptr[0] - lightleft) >> blockdivshift;
//			lightrightstep = (lightptr[1] - lightright) >> blockdivshift;
//			lightdeltastep = ((lightleftstep - lightrightstep) & 0xFFFFF) |
//					0xF0000000;
	movl	4(%ebx),%ecx	// lightptr[1]
	movl	(%ebx),%ebx		// lightptr[0]

	subl	%eax,%ebx
	subl	%edx,%ecx

	sarl	$1,%ecx

	sarl	$1,%ebx
	movl	%ecx,C(lightrightstep)

	subl	%ecx,%ebx
	andl	$0xFFFFF,%ebx

	sarl	$1,%ebp
	orl		$0xF0000000,%ebx

	movl	%ebx,C(lightdeltastep)
	subl	%ebx,%ebx	// high word must be 0 in loop for addressing

	movb	1(%esi),%bl
	subl	%ecx,%ecx	// high word must be 0 in loop for addressing

	movb	%dh,%bh
	movb	(%esi),%cl

	addl	%ebp,%edx
	movb	%dh,%ch

	movb	0x12345678(%ebx),%al
LBPatch16:
	movl	C(lightright),%edx

	movb	%al,1(%edi)
	movb	0x12345678(%ecx),%al
LBPatch17:

	movb	%al,(%edi)
	movl	C(sourcetstep),%eax

	addl	%eax,%esi
	movl	C(surfrowbytes),%eax

	addl	%eax,%edi
	movl	C(lightdeltastep),%eax

	movl	C(lightdelta),%ebp
	movb	(%esi),%cl

	addl	%eax,%ebp
	movl	C(lightrightstep),%eax

	sarl	$1,%ebp
	addl	%eax,%edx

	movb	%dh,%bh
	movb	1(%esi),%bl

	addl	%ebp,%edx
	movb	%dh,%ch

	movb	0x12345678(%ebx),%al
LBPatch30:
	movl	C(sourcetstep),%edx

	movb	%al,1(%edi)
	movb	0x12345678(%ecx),%al
LBPatch31:

	movb	%al,(%edi)
	movl	C(surfrowbytes),%ebp

	addl	%edx,%esi
	addl	%ebp,%edi

//			if (pbasesource >= r_sourcemax)
//				pbasesource -= stepback;

	cmpl	C(r_sourcemax),%esi
	jb		LSkip_mip3
	subl	C(r_stepback),%esi
LSkip_mip3:

	movl	C(r_lightptr),%ebx
	decl	sb_v

	jnz		Lv_loop_mip3

	popl	%ebx				// restore register variables
	popl	%esi
	popl	%edi
	popl	%ebp				// restore the caller's stack frame
	ret


.globl C(R_Surf8End)
C(R_Surf8End):

//----------------------------------------------------------------------
// Code patching routines
//----------------------------------------------------------------------
	.data

	.p2align 4,,15
LPatchTable8:
#if defined(ASM486_SURF8_MIP0_ROWS4) || defined(ASM486_SURF8_MIP0_ROWS8) || defined(ASM486_SURF8_MIP0_ROWS16)
	.long .LLBPatcha_0-4
	.long .LLBPatcha_1-4
	.long .LLBPatcha_2-4
	.long .LLBPatcha_3-4
	.long .LLBPatcha_4-4
	.long .LLBPatcha_5-4
	.long .LLBPatcha_6-4
	.long .LLBPatcha_7-4
	.long .LLBPatcha_8-4
	.long .LLBPatcha_9-4
	.long .LLBPatcha_10-4
	.long .LLBPatcha_11-4
	.long .LLBPatcha_12-4
	.long .LLBPatcha_13-4
	.long .LLBPatcha_14-4
	.long .LLBPatcha_15-4
	.long .LLBPatchb_0-4
	.long .LLBPatchb_1-4
	.long .LLBPatchb_2-4
	.long .LLBPatchb_3-4
	.long .LLBPatchb_4-4
	.long .LLBPatchb_5-4
	.long .LLBPatchb_6-4
	.long .LLBPatchb_7-4
	.long .LLBPatchb_8-4
	.long .LLBPatchb_9-4
	.long .LLBPatchb_10-4
	.long .LLBPatchb_11-4
	.long .LLBPatchb_12-4
	.long .LLBPatchb_13-4
	.long .LLBPatchb_14-4
	.long .LLBPatchb_15-4
	.long .LLBPatchc_0-4
	.long .LLBPatchc_1-4
	.long .LLBPatchc_2-4
	.long .LLBPatchc_3-4
	.long .LLBPatchc_4-4
	.long .LLBPatchc_5-4
	.long .LLBPatchc_6-4
	.long .LLBPatchc_7-4
	.long .LLBPatchc_8-4
	.long .LLBPatchc_9-4
	.long .LLBPatchc_10-4
	.long .LLBPatchc_11-4
	.long .LLBPatchc_12-4
	.long .LLBPatchc_13-4
	.long .LLBPatchc_14-4
	.long .LLBPatchc_15-4
	.long .LLBPatchd_0-4
	.long .LLBPatchd_1-4
	.long .LLBPatchd_2-4
	.long .LLBPatchd_3-4
	.long .LLBPatchd_4-4
	.long .LLBPatchd_5-4
	.long .LLBPatchd_6-4
	.long .LLBPatchd_7-4
	.long .LLBPatchd_8-4
	.long .LLBPatchd_9-4
	.long .LLBPatchd_10-4
	.long .LLBPatchd_11-4
	.long .LLBPatchd_12-4
	.long .LLBPatchd_13-4
	.long .LLBPatchd_14-4
	.long .LLBPatchd_15-4
#if defined(ASM486_SURF8_MIP0_ROWS8) || defined(ASM486_SURF8_MIP0_ROWS16)
	.long .LLBPatche_0-4
	.long .LLBPatche_1-4
	.long .LLBPatche_2-4
	.long .LLBPatche_3-4
	.long .LLBPatche_4-4
	.long .LLBPatche_5-4
	.long .LLBPatche_6-4
	.long .LLBPatche_7-4
	.long .LLBPatche_8-4
	.long .LLBPatche_9-4
	.long .LLBPatche_10-4
	.long .LLBPatche_11-4
	.long .LLBPatche_12-4
	.long .LLBPatche_13-4
	.long .LLBPatche_14-4
	.long .LLBPatche_15-4
	.long .LLBPatchf_0-4
	.long .LLBPatchf_1-4
	.long .LLBPatchf_2-4
	.long .LLBPatchf_3-4
	.long .LLBPatchf_4-4
	.long .LLBPatchf_5-4
	.long .LLBPatchf_6-4
	.long .LLBPatchf_7-4
	.long .LLBPatchf_8-4
	.long .LLBPatchf_9-4
	.long .LLBPatchf_10-4
	.long .LLBPatchf_11-4
	.long .LLBPatchf_12-4
	.long .LLBPatchf_13-4
	.long .LLBPatchf_14-4
	.long .LLBPatchf_15-4
	.long .LLBPatchg_0-4
	.long .LLBPatchg_1-4
	.long .LLBPatchg_2-4
	.long .LLBPatchg_3-4
	.long .LLBPatchg_4-4
	.long .LLBPatchg_5-4
	.long .LLBPatchg_6-4
	.long .LLBPatchg_7-4
	.long .LLBPatchg_8-4
	.long .LLBPatchg_9-4
	.long .LLBPatchg_10-4
	.long .LLBPatchg_11-4
	.long .LLBPatchg_12-4
	.long .LLBPatchg_13-4
	.long .LLBPatchg_14-4
	.long .LLBPatchg_15-4
	.long .LLBPatchh_0-4
	.long .LLBPatchh_1-4
	.long .LLBPatchh_2-4
	.long .LLBPatchh_3-4
	.long .LLBPatchh_4-4
	.long .LLBPatchh_5-4
	.long .LLBPatchh_6-4
	.long .LLBPatchh_7-4
	.long .LLBPatchh_8-4
	.long .LLBPatchh_9-4
	.long .LLBPatchh_10-4
	.long .LLBPatchh_11-4
	.long .LLBPatchh_12-4
	.long .LLBPatchh_13-4
	.long .LLBPatchh_14-4
	.long .LLBPatchh_15-4
#endif
#ifdef ASM486_SURF8_MIP0_ROWS16
.macro SURF8_PATCH_ROW suffix
	.long .LLBPatch\suffix\()_0-4
	.long .LLBPatch\suffix\()_1-4
	.long .LLBPatch\suffix\()_2-4
	.long .LLBPatch\suffix\()_3-4
	.long .LLBPatch\suffix\()_4-4
	.long .LLBPatch\suffix\()_5-4
	.long .LLBPatch\suffix\()_6-4
	.long .LLBPatch\suffix\()_7-4
	.long .LLBPatch\suffix\()_8-4
	.long .LLBPatch\suffix\()_9-4
	.long .LLBPatch\suffix\()_10-4
	.long .LLBPatch\suffix\()_11-4
	.long .LLBPatch\suffix\()_12-4
	.long .LLBPatch\suffix\()_13-4
	.long .LLBPatch\suffix\()_14-4
	.long .LLBPatch\suffix\()_15-4
.endm
SURF8_PATCH_ROW i
SURF8_PATCH_ROW j
SURF8_PATCH_ROW k
SURF8_PATCH_ROW l
SURF8_PATCH_ROW m
SURF8_PATCH_ROW n
SURF8_PATCH_ROW o
SURF8_PATCH_ROW p
#endif
#else
	.long	LBPatch0-4
	.long	LBPatch1-4
	.long	LBPatch2-4
	.long	LBPatch3-4
	.long	LBPatch4-4
	.long	LBPatch5-4
	.long	LBPatch6-4
	.long	LBPatch7-4
	.long	LBPatch8-4
	.long	LBPatch9-4
	.long	LBPatch10-4
	.long	LBPatch11-4
	.long	LBPatch12-4
	.long	LBPatch13-4
	.long	LBPatch14-4
	.long	LBPatch15-4
#endif
	.long	LBPatch16-4
	.long	LBPatch17-4
	.long	LBPatch18-4
	.long	LBPatch19-4
	.long	LBPatch20-4
	.long	LBPatch21-4
#ifdef ASM486_SURF8_MIP1_ROWS8
	.long .LLBPatchm1a_0-4
	.long .LLBPatchm1a_1-4
	.long .LLBPatchm1a_2-4
	.long .LLBPatchm1a_3-4
	.long .LLBPatchm1a_4-4
	.long .LLBPatchm1a_5-4
	.long .LLBPatchm1a_6-4
	.long .LLBPatchm1a_7-4
	.long .LLBPatchm1b_0-4
	.long .LLBPatchm1b_1-4
	.long .LLBPatchm1b_2-4
	.long .LLBPatchm1b_3-4
	.long .LLBPatchm1b_4-4
	.long .LLBPatchm1b_5-4
	.long .LLBPatchm1b_6-4
	.long .LLBPatchm1b_7-4
	.long .LLBPatchm1c_0-4
	.long .LLBPatchm1c_1-4
	.long .LLBPatchm1c_2-4
	.long .LLBPatchm1c_3-4
	.long .LLBPatchm1c_4-4
	.long .LLBPatchm1c_5-4
	.long .LLBPatchm1c_6-4
	.long .LLBPatchm1c_7-4
	.long .LLBPatchm1d_0-4
	.long .LLBPatchm1d_1-4
	.long .LLBPatchm1d_2-4
	.long .LLBPatchm1d_3-4
	.long .LLBPatchm1d_4-4
	.long .LLBPatchm1d_5-4
	.long .LLBPatchm1d_6-4
	.long .LLBPatchm1d_7-4
	.long .LLBPatchm1e_0-4
	.long .LLBPatchm1e_1-4
	.long .LLBPatchm1e_2-4
	.long .LLBPatchm1e_3-4
	.long .LLBPatchm1e_4-4
	.long .LLBPatchm1e_5-4
	.long .LLBPatchm1e_6-4
	.long .LLBPatchm1e_7-4
	.long .LLBPatchm1f_0-4
	.long .LLBPatchm1f_1-4
	.long .LLBPatchm1f_2-4
	.long .LLBPatchm1f_3-4
	.long .LLBPatchm1f_4-4
	.long .LLBPatchm1f_5-4
	.long .LLBPatchm1f_6-4
	.long .LLBPatchm1f_7-4
	.long .LLBPatchm1g_0-4
	.long .LLBPatchm1g_1-4
	.long .LLBPatchm1g_2-4
	.long .LLBPatchm1g_3-4
	.long .LLBPatchm1g_4-4
	.long .LLBPatchm1g_5-4
	.long .LLBPatchm1g_6-4
	.long .LLBPatchm1g_7-4
	.long .LLBPatchm1h_0-4
	.long .LLBPatchm1h_1-4
	.long .LLBPatchm1h_2-4
	.long .LLBPatchm1h_3-4
	.long .LLBPatchm1h_4-4
	.long .LLBPatchm1h_5-4
	.long .LLBPatchm1h_6-4
	.long .LLBPatchm1h_7-4
#else
	.long	LBPatch22-4
	.long	LBPatch23-4
	.long	LBPatch24-4
	.long	LBPatch25-4
	.long	LBPatch26-4
	.long	LBPatch27-4
	.long	LBPatch28-4
	.long	LBPatch29-4
#endif
	.long	LBPatch30-4
	.long	LBPatch31-4

	.text

	.p2align 4,,15
.globl C(R_Surf8Patch)
C(R_Surf8Patch):
	pushl	%ebx

	movl	C(colormap),%eax
	movl	$LPatchTable8,%ebx
#if defined(ASM486_SURF8_MIP0_ROWS16) && defined(ASM486_SURF8_MIP1_ROWS8)
	movl	$328,%ecx
#elif defined(ASM486_SURF8_MIP0_ROWS16)
	movl	$272,%ecx
#elif defined(ASM486_SURF8_MIP0_ROWS8) && defined(ASM486_SURF8_MIP1_ROWS8)
	movl	$200,%ecx
#elif defined(ASM486_SURF8_MIP0_ROWS8)
	movl	$144,%ecx
#elif defined(ASM486_SURF8_MIP0_ROWS4) && defined(ASM486_SURF8_MIP1_ROWS8)
	movl	$136,%ecx
#elif defined(ASM486_SURF8_MIP0_ROWS4)
	movl	$80,%ecx
#elif defined(ASM486_SURF8_MIP1_ROWS8)
	movl	$88,%ecx
#else
	movl	$32,%ecx
#endif
LPatchLoop8:
	movl	(%ebx),%edx
	addl	$4,%ebx
	movl	%eax,(%edx)
	decl	%ecx
	jnz		LPatchLoop8

	popl	%ebx

	ret

#endif	// id386
