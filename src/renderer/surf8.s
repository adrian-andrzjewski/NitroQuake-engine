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
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
//
// surf8.s
// x86 assembly-language 8 bpp surface block drawing code.
//

#include "asm_i386.h"
#include "quakeasm.h"
#include "renderer/asm_draw.h"

#if	id386

	.data

sb_v:		.long	0

#ifdef PROFILE486
	// sb_flat_dh holds the light byte as of the current mip-1 horizontal-flat
	// row's head; the row end compares against it.  See the macro comment.
	.extern	bench486_profile_frame_active
	.extern	bench486_surf8_flat_rows
	.extern	bench486_surf8_flat_dh_moved
sb_flat_dh:
	.byte	0
#endif

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
#ifdef ASM486_SURF8_MIP0_HORIZONTAL_FLAT
	// A flat top edge and matching left/right vertical steps keep each
	// scanline at one light level. Draw those rows without horizontal
	// light interpolation.
	cmpl	%edx,%eax
	jne	LSurfaceBlockMip0NotHorizontalFlat
	cmpl	%ecx,%ebx
	jne	LSurfaceBlockMip0NotHorizontalFlat
	testl	%ecx,%ecx
	jnz	LSurfaceBlockMip0NotFullyFlat
	xorl	%ebx,%ebx
	xorl	%ecx,%ecx
	jmp	LSurf8Mip0FullyFlat
LSurfaceBlockMip0NotFullyFlat:
	movl	%ecx,%ebp
	xorl	%ebx,%ebx
	xorl	%ecx,%ecx
	jmp	LSurf8Mip0HorizontalFlat
LSurfaceBlockMip0NotHorizontalFlat:
#endif

	subl	%ecx,%ebx
	andl	$0xFFFFF,%ebx

	orl		$0xF0000000,%ebx
	subl	%ecx,%ecx	// high word must be 0 in loop for addressing

	movl	%ebx,C(lightdeltastep)
	subl	%ebx,%ebx	// high word must be 0 in loop for addressing
#if defined(ASM486_SURF8_MIP0_ROWS4) || defined(ASM486_SURF8_MIP0_ROWS8) || defined(ASM486_SURF8_MIP0_ROWS16)
.macro SURF8_MIP0_ROW suffix
	pushl	%ebp
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
	popl	%ebp

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

LSurfaceBlockMip0Done:
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

#ifdef ASM486_SURF8_MIP0_HORIZONTAL_FLAT
.macro SURF8_MIP0_HORIZONTAL_FLAT_ROW suffix
	movb	%dh,%bh
	movb	%dh,%ch
	movb	15(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_0:
	movb	14(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_1:
	rorl	$16,%eax
	movb	13(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_2:
	movb	12(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_3:
	movl	%eax,12(%edi)
	movb	11(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_4:
	movb	10(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_5:
	rorl	$16,%eax
	movb	9(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_6:
	movb	8(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_7:
	movl	%eax,8(%edi)
	movb	7(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_8:
	movb	6(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_9:
	rorl	$16,%eax
	movb	5(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_10:
	movb	4(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_11:
	movl	%eax,4(%edi)
	movb	3(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_12:
	movb	2(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_13:
	rorl	$16,%eax
	movb	1(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflat\suffix\()_14:
	movb	(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflat\suffix\()_15:
	movl	%eax,(%edi)
.endm

.macro SURF8_MIP0_FULLY_FLAT_ROW suffix
	movb	15(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_0:
	movb	14(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_1:
	rorl	$16,%eax
	movb	13(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_2:
	movb	12(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_3:
	movl	%eax,12(%edi)
	movb	11(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_4:
	movb	10(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_5:
	rorl	$16,%eax
	movb	9(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_6:
	movb	8(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_7:
	movl	%eax,8(%edi)
	movb	7(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_8:
	movb	6(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_9:
	rorl	$16,%eax
	movb	5(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_10:
	movb	4(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_11:
	movl	%eax,4(%edi)
	movb	3(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_12:
	movb	2(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_13:
	rorl	$16,%eax
	movb	1(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchflatf\suffix\()_14:
	movb	(%esi),%cl
	movb	0x12345678(%ecx),%al
.LLBPatchflatf\suffix\()_15:
	movl	%eax,(%edi)
.endm

	.p2align 4,,15
LSurf8Mip0HorizontalFlat:
	SURF8_MIP0_HORIZONTAL_FLAT_ROW A
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW B
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW C
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW D
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW E
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW F
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW G
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW H
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW I
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW J
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW K
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW L
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW M
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW N
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW O
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_HORIZONTAL_FLAT_ROW P
	addl	%ebp,%edx
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	jmp	LSurfaceBlockMip0Done

	.p2align 4,,15
LSurf8Mip0FullyFlat:
	movb	%dh,%bh
	movb	%dh,%ch
	// Sixteen distinct row bodies preserve independent patch sites.
	SURF8_MIP0_FULLY_FLAT_ROW a
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW b
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW c
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW d
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW e
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW f
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW g
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW h
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW i
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW j
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW k
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW l
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW m
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW n
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW o
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	SURF8_MIP0_FULLY_FLAT_ROW p
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	jmp	LSurfaceBlockMip0Done
#endif


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

#ifdef ASM486_SURF8_MIP1_HORIZONTAL_FLAT
	// The mip-0 specialization, applied to the mip-1 block loop. This test has
	// to sit here, before the two `subl %reg,%reg' below clear %ecx and %ebx
	// for loop addressing: it needs the real lightleftstep/lightrightstep
	// pair. A flat top edge with matching left/right vertical steps means
	// every scanline of the block sits at one light level, so the per-texel
	// horizontal light updates are pure waste. Column order, byte packing and
	// the colormap lookups are identical to the general row; only the two
	// `addl %ebp,%edx' per texel go.
	cmpl	%edx,%eax
	jne	LSurfaceBlockMip1NotHorizontalFlat
	cmpl	%ecx,%ebx
	jne	LSurfaceBlockMip1NotHorizontalFlat
#ifdef ASM486_SURF8_MIP1_INDEX_HOIST
	// All four corners equal makes lightrightstep zero, so %edx never moves
	// and %dh is the same for all eight rows: form the index registers once
	// for the whole block and drop the eight no-op light steps.  Tested first
	// because 11,327 of the 14,837 flat blocks are fully flat, and the test
	// costs two instructions per block *column* (4,901 calls per run), not per
	// row, so the miss is free.
	//
	// This test MUST come before the `xorl %reg,%reg' below, which clears
	// %ecx for loop addressing: after it, `cmpl $0,%ecx' is always true, every
	// flat block takes the fully-flat body, and the framebuffer comes out as
	// checksum 3165952421.  This is the same failure as hoisting the index
	// bytes to block granularity, and the same checksum.
	cmpl	$0,%ecx
	jne	LSurfaceBlockMip1NotFullyFlat
	xorl	%ebx,%ebx		// colormap indexes start at zero
	xorl	%ecx,%ecx
	jmp	LSurf8Mip1FullyFlat
LSurfaceBlockMip1NotFullyFlat:
#endif
	movl	%ecx,%ebp		// constant per-row vertical step
	xorl	%ebx,%ebx		// colormap indexes start at zero
	xorl	%ecx,%ecx
	jmp	LSurf8Mip1HorizontalFlat
LSurfaceBlockMip1NotHorizontalFlat:
#endif

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
// Eight rows above are the full mip-1 block; the 0x7/0xF counter ends without carry.
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

#ifdef ASM486_SURF8_MIP1_HORIZONTAL_FLAT
LSurfaceBlockMip1Done:
	movl	%edx,C(lightright)
#endif

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

#ifdef ASM486_SURF8_MIP1_HORIZONTAL_FLAT
// ASM486_SURF8_MIP1_INDEX_HOIST replaces the four `movb %dh,%bh' / `movb %dh,%ch'
// pairs in the flat row with one pair at the top of the row.  Six instructions
// per row, 0.0353% of frame, measured.
//
// It must be per ROW, not per unrolled block.  The row's own trailing
// `addl %ebp,%edx' advances the light to the next scanline, so %dh is invariant
// across a row's eight texels and varies *between* the block's eight rows.  A
// head at the top of the unrolled block gives rows b..h row a's light byte and
// renders checksum 3165952421.  The premise is measured rather than assumed:
// bench486_surf8_flat_dh_moved reads 0 of 118,712 rows.
//
// `control' is the original body, kept for a matched A/B.
#ifdef ASM486_SURF8_MIP1_INDEX_HOIST
#define SURF8_MIP1_FLAT_INDEX_HIGH
#define SURF8_MIP1_FLAT_INDEX_LOW
#else
#define SURF8_MIP1_FLAT_INDEX_HIGH movb	%dh,%bh
#define SURF8_MIP1_FLAT_INDEX_LOW	 movb	%dh,%ch
#endif

// Flat-row body for the mip-1 block: the general SURF8_MIP1_ROW with every
// per-texel light update removed. %edx already holds this row's light and
// %ebp the constant per-row step, so eight texels need one `addl %ebp,%edx'
// afterwards instead of two adds per texel. Source byte order, the %eax
// packing, the rorl $16 word swap and both colormap lookups per texel are
// byte-for-byte the general path, so the rendered output is identical.
//
// The four `movb %dh,%bh' / `movb %dh,%ch' pairs below are NOT redundant, and
// they were measured rather than argued.  %dh is invariant across a row's eight
// texels (bench486_surf8_flat_dh_moved reads 0 of 118,712 rows), so hoisting
// them to the top of the row is valid -- and worth 6 instructions per row,
// 0.0353% of frame, which is real but under the 0.05% gate.  Hoisting them to
// the top of the *unrolled block* instead is wrong: each row's trailing
// `addl %ebp,%edx' moves the light to the next scanline, so rows b..h would all
// use row a's light byte.  That variant renders checksum 3165952421.  See
// ASM486-HANDOFF.md, "mip-1 flat-row index hoist".
// The eight texels of one fully-flat row: no head, because the caller emits the
// index bytes once for the whole block, and no trailing `addl %ebp,%edx',
// because all four corners are equal so lightrightstep is zero and %edx never
// moves.  Upper-case suffixes keep its patch labels disjoint from the
// horizontal-flat body below.
//
// This is a separate macro rather than a shared one with the row below: gas does
// not substitute macro parameters through a nested expansion, so a wrapper that
// called a shared texel macro would emit the literal label `.LLBPatchm1fsuffix_0'
// and collide with itself.
.macro SURF8_MIP1_FULLY_FLAT_ROW suffix
	movb	6(%esi),%cl
	movb	7(%esi),%bl
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_0:
	movb	5(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_1:
	movb	4(%esi),%cl
	rorl	$16,%eax
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_2:
	movb	3(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_3:
	movb	2(%esi),%cl
	movl	%eax,4(%edi)
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_4:
	movb	1(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_5:
	movb	(%esi),%cl
	rorl	$16,%eax
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_6:
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_7:
	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
.endm

// The eight texels of one flat row, with no prologue and no epilogue, so the
// horizontal-flat and fully-flat bodies can share them.  `suffix' becomes both
// the macro argument and the patch-label suffix, so the two bodies must be
// invoked with disjoint suffix sets (lower case here, upper case below).

// One horizontal-flat row: per-row head (under the hoist) plus the per-row
// light step.  The premise counter compares %dh at the row head against %dh at
// the bottom of the same row; both ends must be inside the row, because
// sampling once per unrolled block reports every row with a non-zero vertical
// step as a false positive.
.macro SURF8_MIP1_FLAT_ROW suffix
#ifdef PROFILE486
	movb	%dh,sb_flat_dh
#endif
#ifdef ASM486_SURF8_MIP1_INDEX_HOIST
	movb	%dh,%bh
	movb	%dh,%ch
#endif
	movb	6(%esi),%cl
	SURF8_MIP1_FLAT_INDEX_HIGH
	movb	7(%esi),%bl
	SURF8_MIP1_FLAT_INDEX_LOW
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_0:
	movb	5(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_1:
	movb	4(%esi),%cl
	SURF8_MIP1_FLAT_INDEX_HIGH
	rorl	$16,%eax
	SURF8_MIP1_FLAT_INDEX_LOW
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_2:
	movb	3(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_3:
	movb	2(%esi),%cl
	movl	%eax,4(%edi)
	SURF8_MIP1_FLAT_INDEX_HIGH
	SURF8_MIP1_FLAT_INDEX_LOW
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_4:
	movb	1(%esi),%bl
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_5:
	movb	(%esi),%cl
	SURF8_MIP1_FLAT_INDEX_HIGH
	rorl	$16,%eax
	SURF8_MIP1_FLAT_INDEX_LOW
	movb	0x12345678(%ebx),%ah
.LLBPatchm1f\suffix\()_6:
	movb	0x12345678(%ecx),%al
.LLBPatchm1f\suffix\()_7:
	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	jz	LSurf8Mip1DhSkipped\suffix\()
	cmpb	%dh,sb_flat_dh
	jne	LSurf8Mip1DhMoved\suffix\()
	incl	C(bench486_surf8_flat_rows)
	jmp	LSurf8Mip1DhSkipped\suffix\()
LSurf8Mip1DhMoved\suffix\():
	incl	C(bench486_surf8_flat_dh_moved)
	incl	C(bench486_surf8_flat_rows)
LSurf8Mip1DhSkipped\suffix\():
#endif
	addl	%ebp,%edx
.endm

#ifdef ASM486_SURF8_MIP1_INDEX_HOIST
	.p2align 4,,15
LSurf8Mip1FullyFlat:
	movb	%dh,%bh
	movb	%dh,%ch
	SURF8_MIP1_FULLY_FLAT_ROW A
	SURF8_MIP1_FULLY_FLAT_ROW B
	SURF8_MIP1_FULLY_FLAT_ROW C
	SURF8_MIP1_FULLY_FLAT_ROW D
	SURF8_MIP1_FULLY_FLAT_ROW E
	SURF8_MIP1_FULLY_FLAT_ROW F
	SURF8_MIP1_FULLY_FLAT_ROW G
	SURF8_MIP1_FULLY_FLAT_ROW H
	jmp	LSurfaceBlockMip1Done
#endif

	.p2align 4,,15
LSurf8Mip1HorizontalFlat:
	// All eight rows are unrolled here and emitted once per block.
	SURF8_MIP1_FLAT_ROW a
	SURF8_MIP1_FLAT_ROW b
	SURF8_MIP1_FLAT_ROW c
	SURF8_MIP1_FLAT_ROW d
	SURF8_MIP1_FLAT_ROW e
	SURF8_MIP1_FLAT_ROW f
	SURF8_MIP1_FLAT_ROW g
	SURF8_MIP1_FLAT_ROW h
	jmp	LSurfaceBlockMip1Done
#endif


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

.macro SURF8_MIP2_ROW suffix
	// Start the independent texel reads before saving and scaling the light
	// delta, so they can be ready by the first two colormap lookups.
	movb	2(%esi),%cl
	movb	3(%esi),%bl
	movl	%ebp,C(lightdelta)

	sarl	$2,%ebp
	movb	%dh,%bh

	addl	%ebp,%edx

	movb	%dh,%ch
	addl	%ebp,%edx

	movb	0x12345678(%ebx),%ah
.LLBPatchm2\suffix\()_18:
	movb	1(%esi),%bl

	movb	0x12345678(%ecx),%al
.LLBPatchm2\suffix\()_19:
	movb	(%esi),%cl

	movb	%dh,%bh
	addl	%ebp,%edx

	rorl	$16,%eax
	movb	%dh,%ch

	movb	0x12345678(%ebx),%ah
.LLBPatchm2\suffix\()_20:
	movl	C(lightright),%edx

	movb	0x12345678(%ecx),%al
.LLBPatchm2\suffix\()_21:
	movl	C(lightdelta),%ebp

	movl	%eax,(%edi)
	addl	C(sourcetstep),%esi
	addl	C(surfrowbytes),%edi
	addl	C(lightrightstep),%edx
	addl	C(lightdeltastep),%ebp
	movl	%edx,C(lightright)
.endm

// The 0x3 high-nibble seed and 0xF step produce exactly four carry iterations.
// Emit the same row updates in sequence and remove the per-row carry branch.
Lblockrows4_mip2:
	SURF8_MIP2_ROW A
	SURF8_MIP2_ROW B
	SURF8_MIP2_ROW C
	SURF8_MIP2_ROW D

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
	.long	.LLBPatchm2A_18-4
	.long	.LLBPatchm2A_19-4
	.long	.LLBPatchm2A_20-4
	.long	.LLBPatchm2A_21-4
	.long	.LLBPatchm2B_18-4
	.long	.LLBPatchm2B_19-4
	.long	.LLBPatchm2B_20-4
	.long	.LLBPatchm2B_21-4
	.long	.LLBPatchm2C_18-4
	.long	.LLBPatchm2C_19-4
	.long	.LLBPatchm2C_20-4
	.long	.LLBPatchm2C_21-4
	.long	.LLBPatchm2D_18-4
	.long	.LLBPatchm2D_19-4
	.long	.LLBPatchm2D_20-4
	.long	.LLBPatchm2D_21-4
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
#ifdef ASM486_SURF8_MIP0_HORIZONTAL_FLAT
	.long	.LLBPatchflatA_0-4
	.long	.LLBPatchflatA_1-4
	.long	.LLBPatchflatA_2-4
	.long	.LLBPatchflatA_3-4
	.long	.LLBPatchflatA_4-4
	.long	.LLBPatchflatA_5-4
	.long	.LLBPatchflatA_6-4
	.long	.LLBPatchflatA_7-4
	.long	.LLBPatchflatA_8-4
	.long	.LLBPatchflatA_9-4
	.long	.LLBPatchflatA_10-4
	.long	.LLBPatchflatA_11-4
	.long	.LLBPatchflatA_12-4
	.long	.LLBPatchflatA_13-4
	.long	.LLBPatchflatA_14-4
	.long	.LLBPatchflatA_15-4
	.long	.LLBPatchflatB_0-4
	.long	.LLBPatchflatB_1-4
	.long	.LLBPatchflatB_2-4
	.long	.LLBPatchflatB_3-4
	.long	.LLBPatchflatB_4-4
	.long	.LLBPatchflatB_5-4
	.long	.LLBPatchflatB_6-4
	.long	.LLBPatchflatB_7-4
	.long	.LLBPatchflatB_8-4
	.long	.LLBPatchflatB_9-4
	.long	.LLBPatchflatB_10-4
	.long	.LLBPatchflatB_11-4
	.long	.LLBPatchflatB_12-4
	.long	.LLBPatchflatB_13-4
	.long	.LLBPatchflatB_14-4
	.long	.LLBPatchflatB_15-4
	.long	.LLBPatchflatC_0-4
	.long	.LLBPatchflatC_1-4
	.long	.LLBPatchflatC_2-4
	.long	.LLBPatchflatC_3-4
	.long	.LLBPatchflatC_4-4
	.long	.LLBPatchflatC_5-4
	.long	.LLBPatchflatC_6-4
	.long	.LLBPatchflatC_7-4
	.long	.LLBPatchflatC_8-4
	.long	.LLBPatchflatC_9-4
	.long	.LLBPatchflatC_10-4
	.long	.LLBPatchflatC_11-4
	.long	.LLBPatchflatC_12-4
	.long	.LLBPatchflatC_13-4
	.long	.LLBPatchflatC_14-4
	.long	.LLBPatchflatC_15-4
	.long	.LLBPatchflatD_0-4
	.long	.LLBPatchflatD_1-4
	.long	.LLBPatchflatD_2-4
	.long	.LLBPatchflatD_3-4
	.long	.LLBPatchflatD_4-4
	.long	.LLBPatchflatD_5-4
	.long	.LLBPatchflatD_6-4
	.long	.LLBPatchflatD_7-4
	.long	.LLBPatchflatD_8-4
	.long	.LLBPatchflatD_9-4
	.long	.LLBPatchflatD_10-4
	.long	.LLBPatchflatD_11-4
	.long	.LLBPatchflatD_12-4
	.long	.LLBPatchflatD_13-4
	.long	.LLBPatchflatD_14-4
	.long	.LLBPatchflatD_15-4
	.macro SURF8_MIP0_FULLY_FLAT_PATCH_ROW suffix
	.long	.LLBPatchflatf\suffix\()_0-4
	.long	.LLBPatchflatf\suffix\()_1-4
	.long	.LLBPatchflatf\suffix\()_2-4
	.long	.LLBPatchflatf\suffix\()_3-4
	.long	.LLBPatchflatf\suffix\()_4-4
	.long	.LLBPatchflatf\suffix\()_5-4
	.long	.LLBPatchflatf\suffix\()_6-4
	.long	.LLBPatchflatf\suffix\()_7-4
	.long	.LLBPatchflatf\suffix\()_8-4
	.long	.LLBPatchflatf\suffix\()_9-4
	.long	.LLBPatchflatf\suffix\()_10-4
	.long	.LLBPatchflatf\suffix\()_11-4
	.long	.LLBPatchflatf\suffix\()_12-4
	.long	.LLBPatchflatf\suffix\()_13-4
	.long	.LLBPatchflatf\suffix\()_14-4
	.long	.LLBPatchflatf\suffix\()_15-4
	.endm
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW a
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW b
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW c
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW d
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW e
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW f
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW g
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW h
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW i
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW j
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW k
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW l
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW m
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW n
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW o
	SURF8_MIP0_FULLY_FLAT_PATCH_ROW p
	.long	.LLBPatchflatE_0-4
	.long	.LLBPatchflatE_1-4
	.long	.LLBPatchflatE_2-4
	.long	.LLBPatchflatE_3-4
	.long	.LLBPatchflatE_4-4
	.long	.LLBPatchflatE_5-4
	.long	.LLBPatchflatE_6-4
	.long	.LLBPatchflatE_7-4
	.long	.LLBPatchflatE_8-4
	.long	.LLBPatchflatE_9-4
	.long	.LLBPatchflatE_10-4
	.long	.LLBPatchflatE_11-4
	.long	.LLBPatchflatE_12-4
	.long	.LLBPatchflatE_13-4
	.long	.LLBPatchflatE_14-4
	.long	.LLBPatchflatE_15-4
	.long	.LLBPatchflatF_0-4
	.long	.LLBPatchflatF_1-4
	.long	.LLBPatchflatF_2-4
	.long	.LLBPatchflatF_3-4
	.long	.LLBPatchflatF_4-4
	.long	.LLBPatchflatF_5-4
	.long	.LLBPatchflatF_6-4
	.long	.LLBPatchflatF_7-4
	.long	.LLBPatchflatF_8-4
	.long	.LLBPatchflatF_9-4
	.long	.LLBPatchflatF_10-4
	.long	.LLBPatchflatF_11-4
	.long	.LLBPatchflatF_12-4
	.long	.LLBPatchflatF_13-4
	.long	.LLBPatchflatF_14-4
	.long	.LLBPatchflatF_15-4
	.long	.LLBPatchflatG_0-4
	.long	.LLBPatchflatG_1-4
	.long	.LLBPatchflatG_2-4
	.long	.LLBPatchflatG_3-4
	.long	.LLBPatchflatG_4-4
	.long	.LLBPatchflatG_5-4
	.long	.LLBPatchflatG_6-4
	.long	.LLBPatchflatG_7-4
	.long	.LLBPatchflatG_8-4
	.long	.LLBPatchflatG_9-4
	.long	.LLBPatchflatG_10-4
	.long	.LLBPatchflatG_11-4
	.long	.LLBPatchflatG_12-4
	.long	.LLBPatchflatG_13-4
	.long	.LLBPatchflatG_14-4
	.long	.LLBPatchflatG_15-4
	.long	.LLBPatchflatH_0-4
	.long	.LLBPatchflatH_1-4
	.long	.LLBPatchflatH_2-4
	.long	.LLBPatchflatH_3-4
	.long	.LLBPatchflatH_4-4
	.long	.LLBPatchflatH_5-4
	.long	.LLBPatchflatH_6-4
	.long	.LLBPatchflatH_7-4
	.long	.LLBPatchflatH_8-4
	.long	.LLBPatchflatH_9-4
	.long	.LLBPatchflatH_10-4
	.long	.LLBPatchflatH_11-4
	.long	.LLBPatchflatH_12-4
	.long	.LLBPatchflatH_13-4
	.long	.LLBPatchflatH_14-4
	.long	.LLBPatchflatH_15-4
	.macro SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW suffix
	.long	.LLBPatchflat\suffix\()_0-4
	.long	.LLBPatchflat\suffix\()_1-4
	.long	.LLBPatchflat\suffix\()_2-4
	.long	.LLBPatchflat\suffix\()_3-4
	.long	.LLBPatchflat\suffix\()_4-4
	.long	.LLBPatchflat\suffix\()_5-4
	.long	.LLBPatchflat\suffix\()_6-4
	.long	.LLBPatchflat\suffix\()_7-4
	.long	.LLBPatchflat\suffix\()_8-4
	.long	.LLBPatchflat\suffix\()_9-4
	.long	.LLBPatchflat\suffix\()_10-4
	.long	.LLBPatchflat\suffix\()_11-4
	.long	.LLBPatchflat\suffix\()_12-4
	.long	.LLBPatchflat\suffix\()_13-4
	.long	.LLBPatchflat\suffix\()_14-4
	.long	.LLBPatchflat\suffix\()_15-4
	.endm
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW I
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW J
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW K
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW L
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW M
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW N
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW O
	SURF8_MIP0_HORIZONTAL_FLAT_PATCH_ROW P
#endif
#ifdef ASM486_SURF8_MIP1_HORIZONTAL_FLAT
	.long	.LLBPatchm1fa_0-4
	.long	.LLBPatchm1fa_1-4
	.long	.LLBPatchm1fa_2-4
	.long	.LLBPatchm1fa_3-4
	.long	.LLBPatchm1fa_4-4
	.long	.LLBPatchm1fa_5-4
	.long	.LLBPatchm1fa_6-4
	.long	.LLBPatchm1fa_7-4
	.long	.LLBPatchm1fb_0-4
	.long	.LLBPatchm1fb_1-4
	.long	.LLBPatchm1fb_2-4
	.long	.LLBPatchm1fb_3-4
	.long	.LLBPatchm1fb_4-4
	.long	.LLBPatchm1fb_5-4
	.long	.LLBPatchm1fb_6-4
	.long	.LLBPatchm1fb_7-4
	.long	.LLBPatchm1fc_0-4
	.long	.LLBPatchm1fc_1-4
	.long	.LLBPatchm1fc_2-4
	.long	.LLBPatchm1fc_3-4
	.long	.LLBPatchm1fc_4-4
	.long	.LLBPatchm1fc_5-4
	.long	.LLBPatchm1fc_6-4
	.long	.LLBPatchm1fc_7-4
	.long	.LLBPatchm1fd_0-4
	.long	.LLBPatchm1fd_1-4
	.long	.LLBPatchm1fd_2-4
	.long	.LLBPatchm1fd_3-4
	.long	.LLBPatchm1fd_4-4
	.long	.LLBPatchm1fd_5-4
	.long	.LLBPatchm1fd_6-4
	.long	.LLBPatchm1fd_7-4
	.long	.LLBPatchm1fe_0-4
	.long	.LLBPatchm1fe_1-4
	.long	.LLBPatchm1fe_2-4
	.long	.LLBPatchm1fe_3-4
	.long	.LLBPatchm1fe_4-4
	.long	.LLBPatchm1fe_5-4
	.long	.LLBPatchm1fe_6-4
	.long	.LLBPatchm1fe_7-4
	.long	.LLBPatchm1ff_0-4
	.long	.LLBPatchm1ff_1-4
	.long	.LLBPatchm1ff_2-4
	.long	.LLBPatchm1ff_3-4
	.long	.LLBPatchm1ff_4-4
	.long	.LLBPatchm1ff_5-4
	.long	.LLBPatchm1ff_6-4
	.long	.LLBPatchm1ff_7-4
	.long	.LLBPatchm1fg_0-4
	.long	.LLBPatchm1fg_1-4
	.long	.LLBPatchm1fg_2-4
	.long	.LLBPatchm1fg_3-4
	.long	.LLBPatchm1fg_4-4
	.long	.LLBPatchm1fg_5-4
	.long	.LLBPatchm1fg_6-4
	.long	.LLBPatchm1fg_7-4
	.long	.LLBPatchm1fh_0-4
	.long	.LLBPatchm1fh_1-4
	.long	.LLBPatchm1fh_2-4
	.long	.LLBPatchm1fh_3-4
	.long	.LLBPatchm1fh_4-4
	.long	.LLBPatchm1fh_5-4
	.long	.LLBPatchm1fh_6-4
	.long	.LLBPatchm1fh_7-4
#ifdef ASM486_SURF8_MIP1_INDEX_HOIST
	// A second eight-row body for the fully-flat case, sharing the texel macro
	// but with its own patch labels: eight rows of eight sites again.
	.long	.LLBPatchm1fA_0-4
	.long	.LLBPatchm1fA_1-4
	.long	.LLBPatchm1fA_2-4
	.long	.LLBPatchm1fA_3-4
	.long	.LLBPatchm1fA_4-4
	.long	.LLBPatchm1fA_5-4
	.long	.LLBPatchm1fA_6-4
	.long	.LLBPatchm1fA_7-4
	.long	.LLBPatchm1fB_0-4
	.long	.LLBPatchm1fB_1-4
	.long	.LLBPatchm1fB_2-4
	.long	.LLBPatchm1fB_3-4
	.long	.LLBPatchm1fB_4-4
	.long	.LLBPatchm1fB_5-4
	.long	.LLBPatchm1fB_6-4
	.long	.LLBPatchm1fB_7-4
	.long	.LLBPatchm1fC_0-4
	.long	.LLBPatchm1fC_1-4
	.long	.LLBPatchm1fC_2-4
	.long	.LLBPatchm1fC_3-4
	.long	.LLBPatchm1fC_4-4
	.long	.LLBPatchm1fC_5-4
	.long	.LLBPatchm1fC_6-4
	.long	.LLBPatchm1fC_7-4
	.long	.LLBPatchm1fD_0-4
	.long	.LLBPatchm1fD_1-4
	.long	.LLBPatchm1fD_2-4
	.long	.LLBPatchm1fD_3-4
	.long	.LLBPatchm1fD_4-4
	.long	.LLBPatchm1fD_5-4
	.long	.LLBPatchm1fD_6-4
	.long	.LLBPatchm1fD_7-4
	.long	.LLBPatchm1fE_0-4
	.long	.LLBPatchm1fE_1-4
	.long	.LLBPatchm1fE_2-4
	.long	.LLBPatchm1fE_3-4
	.long	.LLBPatchm1fE_4-4
	.long	.LLBPatchm1fE_5-4
	.long	.LLBPatchm1fE_6-4
	.long	.LLBPatchm1fE_7-4
	.long	.LLBPatchm1fF_0-4
	.long	.LLBPatchm1fF_1-4
	.long	.LLBPatchm1fF_2-4
	.long	.LLBPatchm1fF_3-4
	.long	.LLBPatchm1fF_4-4
	.long	.LLBPatchm1fF_5-4
	.long	.LLBPatchm1fF_6-4
	.long	.LLBPatchm1fF_7-4
	.long	.LLBPatchm1fG_0-4
	.long	.LLBPatchm1fG_1-4
	.long	.LLBPatchm1fG_2-4
	.long	.LLBPatchm1fG_3-4
	.long	.LLBPatchm1fG_4-4
	.long	.LLBPatchm1fG_5-4
	.long	.LLBPatchm1fG_6-4
	.long	.LLBPatchm1fG_7-4
	.long	.LLBPatchm1fH_0-4
	.long	.LLBPatchm1fH_1-4
	.long	.LLBPatchm1fH_2-4
	.long	.LLBPatchm1fH_3-4
	.long	.LLBPatchm1fH_4-4
	.long	.LLBPatchm1fH_5-4
	.long	.LLBPatchm1fH_6-4
	.long	.LLBPatchm1fH_7-4
#endif
#endif

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
	// Four unrolled mip-2 rows replace the original four shared patch sites.
	addl	$12,%ecx
#ifdef ASM486_SURF8_MIP0_HORIZONTAL_FLAT
	// Sixteen horizontal-flat rows plus sixteen fully-flat rows, 16 sites each.
	addl	$512,%ecx
#endif
#ifdef ASM486_SURF8_MIP1_HORIZONTAL_FLAT
	// Eight rows of eight colormap sites each.
	addl	$64,%ecx
#endif
#ifdef ASM486_SURF8_MIP1_INDEX_HOIST
	// A second eight-row body for the fully-flat case, sharing the texel
	// macro but with its own patch labels: eight rows of eight sites again.
	addl	$64,%ecx
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
