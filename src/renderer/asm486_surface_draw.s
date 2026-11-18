/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_surface_draw.s
// Depth points, solid spans, and cached surface drawing.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

#ifdef DEBUG
#define SURFCACHE_HEIGHT_OFFSET 36
#define SURFCACHE_TEXTURE_OFFSET 44
#define SURFCACHE_DATA_OFFSET 48
#else
#define SURFCACHE_HEIGHT_OFFSET 0
#define SURFCACHE_TEXTURE_OFFSET 40
#define SURFCACHE_DATA_OFFSET 44
#endif

	.data
	.p2align 4,,15
#ifdef ASM486_ZPOINT
Lzpoint_scale:
	.float	32768.0
#endif
	.text
	.p2align 4,,15

#ifdef ASM486_ZPOINT
	.p2align 4,,15
// void D_DrawZPoint(void)
// Draw one z-buffered pixel using the descriptor and video globals. Preserve
// the C conversion's truncate-toward-zero rule by changing only the x87
// rounding-control bits around FISTPL, then restoring the caller's control word.
C(D_DrawZPoint):
	.globl C(D_DrawZPoint)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$24,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	C(r_zpointdesc)+4,%eax	// v
	movl	%eax,-24(%ebp)
	movl	C(r_zpointdesc),%ecx	// u
	movl	%ecx,-20(%ebp)

	// Pixel index is d_scantable[v] + u bytes.
	movl	-24(%ebp),%eax
	movl	C(d_scantable)(,%eax,4),%eax
	addl	-20(%ebp),%eax
	addl	C(d_viewbuffer),%eax
	movl	%eax,-16(%ebp)

	fnstcw	-8(%ebp)
	movw	-8(%ebp),%dx
	orw	$0x0c00,%dx
	movw	%dx,-10(%ebp)
	fldcw	-10(%ebp)
	flds	C(r_zpointdesc)+8
	fmuls	Lzpoint_scale
	fistpl	-4(%ebp)
	fldcw	-8(%ebp)

	// zspantable[v] is the precomputed short* for the start of this row.
	movl	-24(%ebp),%eax
	movl	C(zspantable)(,%eax,4),%edi
	movl	-20(%ebp),%ecx
	leal	(%edi,%ecx,2),%edi
	movswl	(%edi),%eax
	cmpl	-4(%ebp),%eax
	jg	.Lzpoint_done
	movl	-4(%ebp),%eax
	movw	%ax,(%edi)
	movl	-16(%ebp),%edi
	movl	C(r_zpointdesc)+12,%eax
	movb	%al,(%edi)

.Lzpoint_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_SOLID_SURFACE
	.p2align 4,,15
// void D_DrawSolidSurface(surf_t *surf, int color)
// Fill each span with the low byte of color. The C small-span path writes one
// pixel even for a non-positive count; retain that edge behavior as well.
C(D_DrawSolidSurface):
	.globl C(D_DrawSolidSurface)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$8,%esp		// next span and u2 locals

	movl	8(%ebp),%eax
	movl	8(%eax),%esi	// surf_t.spans
	movl	12(%ebp),%ebx
	movl	%ebx,%eax
	shll	$24,%ebx
	movl	%eax,%edx
	shll	$16,%edx
	orl	%edx,%ebx
	movl	%eax,%edx
	shll	$8,%edx
	orl	%edx,%ebx
	orl	%eax,%ebx

.Lsolid_surface_span:
	testl	%esi,%esi
	jz	.Lsolid_surface_done
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lsolid_surface_unprofiled
	incl	C(bench486_solid_span_count)
.Lsolid_surface_unprofiled:
#endif


	movl	%esi,%eax
	movl	espan_t_pnext(%eax),%edx
	movl	%edx,-16(%ebp)
	movl	espan_t_count(%eax),%ecx
	movzwl	espan_t_v(%eax),%eax
	movl	C(viewspantable)(,%eax,4),%edi
	movzwl	espan_t_u(%esi),%eax
	addl	%eax,%edi
	cmpl	$16,%ecx
	jge	.Lsolid_surface_large_span
	leal	-1(%eax,%ecx),%edx	// u2 = u + count - 1
	movl	%edx,-20(%ebp)
	subl	%eax,%edx
	cmpl	$8,%edx
	movl	-20(%ebp),%edx
	movb	%bl,(%edi)
	jge	.Lsolid_surface_alignment_path
	incl	%eax
	incl	%edi
.Lsolid_surface_short_tail:
	cmpl	%edx,%eax
	jg	.Lsolid_surface_next_span
	movb	%bl,(%edi)
	incl	%eax
	incl	%edi
	jmp	.Lsolid_surface_short_tail

.Lsolid_surface_alignment_path:
	incl	%eax
	incl	%edi
.Lsolid_surface_align:
	testl	$3,%eax
	jz	.Lsolid_surface_aligned
	movb	%bl,(%edi)
	incl	%eax
	incl	%edi
	jmp	.Lsolid_surface_align
.Lsolid_surface_aligned:
	subl	$4,%edx
.Lsolid_surface_words:
	cmpl	%edx,%eax
	jg	.Lsolid_surface_word_tail_start
	movl	%ebx,(%edi)
	addl	$4,%eax
	addl	$4,%edi
	jmp	.Lsolid_surface_words
.Lsolid_surface_word_tail_start:
	addl	$4,%edx
.Lsolid_surface_word_tail:
	cmpl	%edx,%eax
	jg	.Lsolid_surface_next_span
	movb	%bl,(%edi)
	incl	%eax
	incl	%edi
	jmp	.Lsolid_surface_word_tail

.Lsolid_surface_large_span:
	movl	%ebx,%eax
	cld
	rep stosb

.Lsolid_surface_next_span:
	movl	-16(%ebp),%esi
	jmp	.Lsolid_surface_span

.Lsolid_surface_done:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret
#endif

#ifdef ASM486_SURFACE_DRAW

.set RDS_SURF,       -4
.set RDS_TEXTURE,    -8
.set RDS_MIP,       -12
.set RDS_TEXWIDTH,  -16
.set RDS_TMAX,      -20
.set RDS_BASEPTR,   -24
.set RDS_SOFFSET,   -28
.set RDS_SMAX,      -32
.set RDS_BLOCKSIZE, -36
.set RDS_HBLOCKS,   -40
.set RDS_DEST,      -44
.set RDS_SMASK,     -48
.set RDS_DRAWER,    -52
.set RDS_LIGHTPTR,  -56
.set RDS_STEPBACK,  -60
.set RDS_COUNT,     -64

.macro RDS_PREPARE_BLOCK
	movl	RDS_LIGHTPTR(%ebp),%eax
	movl	%eax,C(r_lightptr)
	addl	$4,RDS_LIGHTPTR(%ebp)
	movl	RDS_DEST(%ebp),%eax
	movl	%eax,C(prowdestbase)
	addl	RDS_BLOCKSIZE(%ebp),%eax
	movl	%eax,RDS_DEST(%ebp)
	movl	RDS_BASEPTR(%ebp),%eax
	addl	RDS_SOFFSET(%ebp),%eax
	movl	%eax,C(pbasesource)
.endm

.macro RDS_ADVANCE_POWER
	movl	RDS_SOFFSET(%ebp),%eax
	addl	RDS_BLOCKSIZE(%ebp),%eax
	andl	RDS_SMASK(%ebp),%eax
	movl	%eax,RDS_SOFFSET(%ebp)
.endm

.macro RDS_ADVANCE_NONPOWER
	movl	RDS_SOFFSET(%ebp),%eax
	addl	RDS_BLOCKSIZE(%ebp),%eax
	cmpl	RDS_SMAX(%ebp),%eax
	jl	9f
	xorl	%eax,%eax
9:
	movl	%eax,RDS_SOFFSET(%ebp)
.endm

	.p2align 4,,15
// void R_DrawSurface(void)
// Build block lighting, prepare wrapped texture addresses, and draw every
// horizontal block through the existing i486 mip drawers.
C(R_DrawSurface):
	.globl C(R_DrawSurface)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$64,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileBegin_asm486_C)
#endif
	call	C(R_BuildLightMap)
#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileAfterLightmap_asm486_C)
#endif

	movl	C(r_drawsurf)+sd_drawsurf_surf,%eax
	movl	%eax,RDS_SURF(%ebp)
	movl	C(r_drawsurf)+sd_drawsurf_texture,%edx
	movl	%edx,RDS_TEXTURE(%ebp)
	movl	C(r_drawsurf)+sd_drawsurf_surfmip,%ecx
	movl	%ecx,RDS_MIP(%ebp)

	movl	C(r_drawsurf)+sd_drawsurf_rowbytes,%eax
	movl	%eax,C(surfrowbytes)

	movl	16(%edx),%eax		// mip width
	movl	20(%edx),%ebx		// mip height
	shrl	%cl,%eax
	shrl	%cl,%ebx
	movl	%eax,RDS_TEXWIDTH(%ebp)
	movl	%ebx,RDS_TMAX(%ebp)

	movl	$16,%edx
	shrl	%cl,%edx
	movl	%edx,RDS_BLOCKSIZE(%ebp)
	movl	%edx,C(blocksize)

	movl	$4,%eax
	subl	%ecx,%eax
	movl	%eax,C(blockdivshift)
	movl	$1,%edx
	movb	%al,%cl
	shll	%cl,%edx
	decl	%edx
	movl	%edx,C(blockdivmask)

	movl	RDS_SURF(%ebp),%esi
	movswl	sd_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,C(r_lightwidth)

	movl	C(r_drawsurf)+sd_drawsurf_surfwidth,%eax
	movl	C(blockdivshift),%ecx
	sarl	%cl,%eax
	movl	%eax,C(r_numhblocks)
	movl	C(r_drawsurf)+sd_drawsurf_surfheight,%eax
	sarl	%cl,%eax
	movl	%eax,C(r_numvblocks)

#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileCountBlocks_asm486_C)
#endif

	movl	RDS_TEXTURE(%ebp),%edx
	movl	RDS_MIP(%ebp),%ecx
	movl	sd_texture_offsets(%edx,%ecx,4),%eax
	addl	%edx,%eax
	movl	%eax,C(r_source)

	movl	RDS_TEXWIDTH(%ebp),%eax
	movl	%eax,C(sourcetstep)
	movl	RDS_TMAX(%ebp),%eax
	mull	RDS_TEXWIDTH(%ebp)
	movl	%eax,RDS_STEPBACK(%ebp)
	movl	%eax,C(r_stepback)
	addl	C(r_source),%eax
	movl	%eax,C(r_sourcemax)

	movl	RDS_SURF(%ebp),%esi
	movswl	sd_surface_texturemins(%esi),%eax
	movl	RDS_MIP(%ebp),%ecx
	sarl	%cl,%eax
	movl	RDS_TEXWIDTH(%ebp),%edx
	shll	$16,%edx
	addl	%edx,%eax
	movl	RDS_TEXWIDTH(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_soffset_modulo
	leal	-1(%ecx),%edx
	testl	%edx,%ecx
	jnz	.Lrds_soffset_modulo
	andl	%edx,%eax
	jmp	.Lrds_soffset_ready
.Lrds_soffset_modulo:
	cdq
	idivl	%ecx
	movl	%edx,%eax
.Lrds_soffset_ready:
	movl	%eax,RDS_SOFFSET(%ebp)
	movl	RDS_TEXWIDTH(%ebp),%eax
	movl	%eax,RDS_SMAX(%ebp)

	movswl	sd_surface_texturemins+2(%esi),%eax
	movl	RDS_MIP(%ebp),%ecx
	sarl	%cl,%eax
	movl	RDS_TMAX(%ebp),%edx
	shll	$16,%edx
	addl	%edx,%eax
	movl	RDS_TMAX(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_toffset_modulo
	leal	-1(%ecx),%edx
	testl	%edx,%ecx
	jnz	.Lrds_toffset_modulo
	andl	%edx,%eax
	jmp	.Lrds_toffset_ready
.Lrds_toffset_modulo:
	cdq
	idivl	%ecx
	movl	%edx,%eax
.Lrds_toffset_ready:
	mull	RDS_TEXWIDTH(%ebp)
	addl	C(r_source),%eax
	movl	%eax,RDS_BASEPTR(%ebp)

	movl	$C(blocklights),%eax
	movl	%eax,RDS_LIGHTPTR(%ebp)
	movl	C(r_drawsurf)+sd_drawsurf_surfdat,%eax
	movl	%eax,RDS_DEST(%ebp)
	movl	RDS_MIP(%ebp),%ecx
	movl	.Lrds_drawer_table(,%ecx,4),%eax
	movl	%eax,RDS_DRAWER(%ebp)
	movl	C(r_numhblocks),%eax
	movl	%eax,RDS_HBLOCKS(%ebp)

#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileStartBlocks_asm486_C)
#endif

	movl	RDS_SMAX(%ebp),%eax
	testl	%eax,%eax
	jz	.Lrds_draw_non_power_of_two
	leal	-1(%eax),%edx
	testl	%edx,%eax
	jnz	.Lrds_draw_non_power_of_two
	movl	%edx,RDS_SMASK(%ebp)
	movl	RDS_HBLOCKS(%ebp),%eax
	movl	%eax,RDS_COUNT(%ebp)
	movl	RDS_MIP(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_power_mip0
	cmpl	$1,%ecx
	je	.Lrds_power_mip1
	cmpl	$2,%ecx
	je	.Lrds_power_mip2
	cmpl	$3,%ecx
	je	.Lrds_power_mip3
	jmp	.Lrds_power_indirect

.Lrds_power_mip0:
.Lrds_power_mip0_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip0)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip0_loop
	jmp	.Lrds_draw_complete

.Lrds_power_mip1:
.Lrds_power_mip1_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip1)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip1_loop
	jmp	.Lrds_draw_complete

.Lrds_power_mip2:
.Lrds_power_mip2_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip2)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip2_loop
	jmp	.Lrds_draw_complete

.Lrds_power_mip3:
.Lrds_power_mip3_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip3)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_mip3_loop
	jmp	.Lrds_draw_complete

.Lrds_power_indirect:
.Lrds_power_indirect_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	*RDS_DRAWER(%ebp)
	RDS_ADVANCE_POWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_power_indirect_loop
	jmp	.Lrds_draw_complete

.Lrds_draw_non_power_of_two:
	movl	RDS_HBLOCKS(%ebp),%eax
	movl	%eax,RDS_COUNT(%ebp)
	movl	RDS_MIP(%ebp),%ecx
	testl	%ecx,%ecx
	jz	.Lrds_nonpower_mip0
	cmpl	$1,%ecx
	je	.Lrds_nonpower_mip1
	cmpl	$2,%ecx
	je	.Lrds_nonpower_mip2
	cmpl	$3,%ecx
	je	.Lrds_nonpower_mip3
	jmp	.Lrds_nonpower_indirect

.Lrds_nonpower_mip0:
.Lrds_nonpower_mip0_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip0)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip0_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_mip1:
.Lrds_nonpower_mip1_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip1)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip1_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_mip2:
.Lrds_nonpower_mip2_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip2)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip2_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_mip3:
.Lrds_nonpower_mip3_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	C(R_DrawSurfaceBlock8_mip3)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_mip3_loop
	jmp	.Lrds_draw_complete

.Lrds_nonpower_indirect:
.Lrds_nonpower_indirect_loop:
	cmpl	$0,RDS_COUNT(%ebp)
	jle	.Lrds_draw_complete
	RDS_PREPARE_BLOCK
	call	*RDS_DRAWER(%ebp)
	RDS_ADVANCE_NONPOWER
	decl	RDS_COUNT(%ebp)
	jg	.Lrds_nonpower_indirect_loop

.Lrds_draw_complete:
#ifdef PROFILE486
	call	C(R_DrawSurfaceProfileFinish_asm486_C)
#endif
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

	.section .rodata
.Lrds_drawer_table:
	.long C(R_DrawSurfaceBlock8_mip0)
	.long C(R_DrawSurfaceBlock8_mip1)
	.long C(R_DrawSurfaceBlock8_mip2)
	.long C(R_DrawSurfaceBlock8_mip3)
	.text

#endif

