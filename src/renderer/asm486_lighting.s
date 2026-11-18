/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_lighting.s
// Lightmap accumulation and dynamic-light routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

.data
	.align 1

#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION
	.p2align 2
.Ldlight_project_256:
	.float	256.0
#endif
.text

	.p2align 4,,15

// void R_BuildLightMapFusedNoDlights_asm486(unsigned *dest, byte *lightmap,
//                                            int size, int maps,
//                                            unsigned scale, int *lightadj)
// Fused no-dlight accumulation plus inverse/shift/clamp for maps 2..4.
#define FUSED_LOAD_BASE(adj) \
	movzbl	(%esi,%ecx),%eax; \
	mull	adj(%ebx); \
	addl	%eax,%ebp
#define FUSED_LOAD_PLANE(plane,adj) \
	movl	plane(%esp),%edx; \
	movzbl	(%edx,%ecx),%eax; \
	mull	adj(%ebx); \
	addl	%eax,%ebp
#define FUSED_FINISH(clamp,loop) \
	movl	$65280,%eax; \
	subl	%ebp,%eax; \
	sarl	$2,%eax; \
	cmpl	$64,%eax; \
	jge	clamp; \
	movl	$64,%eax; \
clamp:	\
	movl	%eax,(%edi,%ecx,4); \
	incl	%ecx; \
	cmpl	40(%esp),%ecx; \
	jb	loop

C(R_BuildLightMapFusedNoDlights_asm486):
	.globl C(R_BuildLightMapFusedNoDlights_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$12,%esp
	movl	32(%esp),%edi		// dest
	movl	36(%esp),%esi		// lightmap
	movl	40(%esp),%edx		// size
	movl	52(%esp),%ebx		// lightadj
	leal	(%esi,%edx),%eax
	movl	%eax,0(%esp)
	addl	%edx,%eax
	movl	%eax,4(%esp)
	addl	%edx,%eax
	movl	%eax,8(%esp)
	movl	44(%esp),%eax		// maps
	cmpl	$2,%eax
	je	.Lfused_maps2
	cmpl	$3,%eax
	je	.Lfused_maps3
	cmpl	$4,%eax
	je	.Lfused_maps4
	jmp	.Lfused_done

.Lfused_maps2:
	xorl	%ecx,%ecx
.Lfused_loop2:
	movl	48(%esp),%ebp
	FUSED_LOAD_BASE(0)
	FUSED_LOAD_PLANE(0,4)
	FUSED_FINISH(.Lfused_clamp2,.Lfused_loop2)
	jmp	.Lfused_done

.Lfused_maps3:
	xorl	%ecx,%ecx
.Lfused_loop3:
	movl	48(%esp),%ebp
	FUSED_LOAD_BASE(0)
	FUSED_LOAD_PLANE(0,4)
	FUSED_LOAD_PLANE(4,8)
	FUSED_FINISH(.Lfused_clamp3,.Lfused_loop3)
	jmp	.Lfused_done

.Lfused_maps4:
	xorl	%ecx,%ecx
.Lfused_loop4:
	movl	48(%esp),%ebp
	FUSED_LOAD_BASE(0)
	FUSED_LOAD_PLANE(0,4)
	FUSED_LOAD_PLANE(4,8)
	FUSED_LOAD_PLANE(8,12)
	FUSED_FINISH(.Lfused_clamp4,.Lfused_loop4)

.Lfused_done:
	addl	$12,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

#undef FUSED_LOAD_BASE
#undef FUSED_LOAD_PLANE
#undef FUSED_FINISH

	.p2align 4,,15

// void R_BuildLightMapNormalize_asm486(unsigned *lights, int size)
// Invert and clamp a lightmap in place.  Keep the array pointer and count in
// registers and perform one store per element; the C compiler emits an
// additional pre-clamp store in the original inline loop on the 486 target.
C(R_BuildLightMapNormalize_asm486):
	.globl C(R_BuildLightMapNormalize_asm486)
	pushl	%edi
	pushl	%esi
	movl	12(%esp),%edi		// lights
	movl	16(%esp),%esi		// size
	movl	$0xff00,%edx		// 255 << 8
	testl	%esi,%esi
	jle	.Llightmap_normalize_done

.Llightmap_normalize_loop4:
	movl	%esi,%ecx
	shrl	$2,%ecx
	jz	.Llightmap_normalize_tail

.Llightmap_normalize_unrolled:
	movl	%edx,%eax
	subl	(%edi),%eax
	sarl	$2,%eax			// (8 - VID_CBITS), with VID_CBITS == 6
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store0
	movl	$64,%eax
	.Llightmap_normalize_store0:
	movl	%eax,(%edi)

	movl	%edx,%eax
	subl	4(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store1
	movl	$64,%eax
	.Llightmap_normalize_store1:
	movl	%eax,4(%edi)

	movl	%edx,%eax
	subl	8(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store2
	movl	$64,%eax
	.Llightmap_normalize_store2:
	movl	%eax,8(%edi)

	movl	%edx,%eax
	subl	12(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store3
	movl	$64,%eax
	.Llightmap_normalize_store3:
	movl	%eax,12(%edi)
	addl	$16,%edi

	decl	%ecx
	jnz	.Llightmap_normalize_unrolled

	andl	$3,%esi
	jz	.Llightmap_normalize_done

.Llightmap_normalize_tail:
	movl	%edx,%eax
	subl	(%edi),%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_normalize_tail_store
	movl	$64,%eax
.Llightmap_normalize_tail_store:
	movl	%eax,(%edi)
	addl	$4,%edi
	decl	%esi
	jnz	.Llightmap_normalize_tail
	jmp	.Llightmap_normalize_done
.Llightmap_normalize_done:
	popl	%esi
	popl	%edi
	ret

	.p2align 4,,15

// int R_AddDynamicLightSamples_asm486(unsigned *blocklights, int smax,
//                                     int tmax, int local0, int local1,
//                                     float local1_float, int idist_limit,
//                                     int irad, int all_lit)
// Walk one sample rectangle while preserving C's per-row float-to-int
// truncation.  A positive fractional t coordinate becomes one unit closer to
// zero after its row crosses into negative values.
#define DLIGHT_SAMPLE_PIXEL_AT(offset) \
	movl	%edx,%eax; \
	subl	$16,%edx; \
	testl	%eax,%eax; \
	jge	1f; \
	negl	%eax; \
1: 	cmpl	%ecx,%eax; \
	jg	2f; \
	sarl	$1,%eax; \
	addl	%ecx,%eax; \
	jmp	3f; \
2: 	addl	%ebp,%eax; \
	3: 	cmpl	%ebx,%eax; \
	jge	4f; \
	sall	$8,%eax; \
	negl	%eax; \
	addl	64(%esp),%eax; \
	addl	%eax,offset(%esi); \
	incl	%edi; \
4:

#define DLIGHT_SAMPLE_ALL_AT(offset) \
	movl	%edx,%eax; \
	subl	$16,%edx; \
	testl	%eax,%eax; \
	jge	1f; \
	negl	%eax; \
1:  	cmpl	%ecx,%eax; \
	jg	2f; \
	sarl	$1,%eax; \
	addl	%ecx,%eax; \
	jmp	3f; \
2:  	addl	%ebp,%eax; \
3:  	sall	$8,%eax; \
	negl	%eax; \
	addl	64(%esp),%eax; \
	addl	%eax,offset(%esi)

C(R_AddDynamicLightSamples_asm486):
	.globl C(R_AddDynamicLightSamples_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$16,%esp

	// Four saved registers plus the 16-byte local block precede the args.
	movl	36(%esp),%esi		// blocklights
	movl	60(%esp),%ebx		// idist_limit
	xorl	%edi,%edi			// contributed count
	movl	44(%esp),%eax		// tmax
	movl	%eax,12(%esp)
	movl	52(%esp),%eax		// signed td for the current row
	movl	%eax,0(%esp)
	movl	$0,4(%esp)		// positive fractional t-coordinate flag
	cmpl	$0,%eax
	jl	.Ldlight_fraction_ready
	fildl	52(%esp)
	flds	56(%esp)
	fcompp
	fwait
	fnstsw	%ax
	sahf
	jbe	.Ldlight_fraction_ready
	movl	$1,4(%esp)
.Ldlight_fraction_ready:
	cmpl	$0,68(%esp)		// all sampled distances pass
	jz	.Ldlight_row
	movl	$1,%edi
	jmp	.Ldlight_all_row

.Ldlight_row:
	// ECX is the absolute row distance and EBP is td >> 1.  Keep the
	// signed row distance in the local block for the next row.
	movl	0(%esp),%eax
	cmpl	$0,4(%esp)
	je	.Ldlight_row_t_ready
	testl	%eax,%eax
	jge	.Ldlight_row_t_ready
	incl	%eax
.Ldlight_row_t_ready:
	movl	%eax,%ecx
	sarl	$31,%eax
	xorl	%eax,%ecx
	subl	%eax,%ecx
	movl	%ecx,%ebp
	sarl	$1,%ebp
	movl	48(%esp),%edx		// reset signed sd for this row
	movl	40(%esp),%eax		// smax / 4
	shrl	$2,%eax
	movl	%eax,8(%esp)
	testl	%eax,%eax
	jz	.Ldlight_tail_select

.Ldlight_quad:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	DLIGHT_SAMPLE_PIXEL_AT(4)
	DLIGHT_SAMPLE_PIXEL_AT(8)
	DLIGHT_SAMPLE_PIXEL_AT(12)
	addl	$16,%esi
	decl	8(%esp)
	jnz	.Ldlight_quad

.Ldlight_tail_select:
	movl	40(%esp),%eax
	andl	$3,%eax
	jmp	.Ldlight_tail_table(,%eax,4)

.Ldlight_tail3:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	addl	$4,%esi
.Ldlight_tail2:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	addl	$4,%esi
.Ldlight_tail1:
	DLIGHT_SAMPLE_PIXEL_AT(0)
	addl	$4,%esi
	jmp	.Ldlight_row_done

.Ldlight_all_row:
	movl	0(%esp),%eax
	cmpl	$0,4(%esp)
	je	.Ldlight_all_row_t_ready
	testl	%eax,%eax
	jge	.Ldlight_all_row_t_ready
	incl	%eax
.Ldlight_all_row_t_ready:
	movl	%eax,%ecx
	sarl	$31,%eax
	xorl	%eax,%ecx
	subl	%eax,%ecx
	movl	%ecx,%ebp
	sarl	$1,%ebp
	movl	48(%esp),%edx		// reset signed sd for this row
	movl	40(%esp),%eax		// smax / 4
	shrl	$2,%eax
	movl	%eax,8(%esp)
	testl	%eax,%eax
	jz	.Ldlight_all_tail_select

.Ldlight_all_quad:
	DLIGHT_SAMPLE_ALL_AT(0)
	DLIGHT_SAMPLE_ALL_AT(4)
	DLIGHT_SAMPLE_ALL_AT(8)
	DLIGHT_SAMPLE_ALL_AT(12)
	addl	$16,%esi
	decl	8(%esp)
	jnz	.Ldlight_all_quad

.Ldlight_all_tail_select:
	movl	40(%esp),%eax
	andl	$3,%eax
	jmp	.Ldlight_all_tail_table(,%eax,4)

.Ldlight_all_tail3:
	DLIGHT_SAMPLE_ALL_AT(0)
	addl	$4,%esi
.Ldlight_all_tail2:
	DLIGHT_SAMPLE_ALL_AT(0)
	addl	$4,%esi
.Ldlight_all_tail1:
	DLIGHT_SAMPLE_ALL_AT(0)
	addl	$4,%esi
	jmp	.Ldlight_row_done

.Ldlight_row_done:
	subl	$16,0(%esp)
	decl	12(%esp)
	jnz	.Ldlight_row

	movl	%edi,%eax
	addl	$16,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

	// Keep jump-table data out of .text so the linear ISA audit only decodes
	// instructions.  The 32-bit flat DOS target can use these relocated entries.
	.section .rodata
.Ldlight_tail_table:
	.long .Ldlight_row_done, .Ldlight_tail1, .Ldlight_tail2, .Ldlight_tail3
.Ldlight_all_tail_table:
	.long .Ldlight_row_done, .Ldlight_all_tail1, .Ldlight_all_tail2, .Ldlight_all_tail3
	.text


#ifdef ASM486_LIGHTMAP_BUILD

.set LMB_SURF,       -4
.set LMB_SMAX,       -8
.set LMB_TMAX,      -12
.set LMB_SIZE,      -16
.set LMB_LIGHTMAP,  -20
.set LMB_SCALE,     -24
.set LMB_MAPS,      -28
.set LMB_FIRST,     -32
.set LMB_INVERSE,   -36
.set LMB_INDEX,     -40

	.p2align 4,,15
// void R_BuildLightMap(void)
// Convert the C dispatcher and its inline fill/table loops to 32-bit i486
// assembly. The style, fused-style, dynamic-light, and normalization helpers
// remain independently selectable at their existing C/ASM seams.
C(R_BuildLightMap):
	.globl C(R_BuildLightMap)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$40,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	C(r_drawsurf)+lm_drawsurf_surf,%esi
	movl	%esi,LMB_SURF(%ebp)
	movswl	lm_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,LMB_SMAX(%ebp)
	movswl	lm_surface_extents+2(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,LMB_TMAX(%ebp)
	movl	LMB_SMAX(%ebp),%eax
	mull	LMB_TMAX(%ebp)
	movl	%eax,LMB_SIZE(%ebp)
	movl	lm_surface_samples(%esi),%eax
	movl	%eax,LMB_LIGHTMAP(%ebp)

	// C float truth is false only for +0 and -0. Test the magnitude bits;
	// subnormals and NaNs remain true.
	testl	$0x7fffffff,C(r_fullbright)+lm_cvar_value
	jne	.Llightmap_fullbright
	movl	C(cl)+lm_client_worldmodel,%eax
	cmpl	$0,lm_model_lightdata(%eax)
	je	.Llightmap_fullbright

	movl	C(r_refdef)+lm_refdef_ambientlight,%eax
	shll	$8,%eax
	movl	%eax,LMB_SCALE(%ebp)

	// If style zero exists, first try the no-dlight fused fast paths.
	movl	LMB_LIGHTMAP(%ebp),%eax
	testl	%eax,%eax
	je	.Llightmap_ambient_only
	cmpb	$255,lm_surface_styles(%esi)
	je	.Llightmap_ambient_only
	movl	C(r_drawsurf)+lm_drawsurf_lightadj,%eax
	movl	%eax,LMB_FIRST(%ebp)
	movl	lm_surface_dlightframe(%esi),%eax
	cmpl	C(r_framecount),%eax
	je	.Llightmap_style_accumulate

	// A single style has a cached 256-entry invert/clamp table. Rebuild it
	// only when the first-style adjustment or ambient scale changes.
	cmpb	$255,lm_surface_styles+1(%esi)
	jne	.Llightmap_fused_styles
	movl	$65280,%eax
	subl	LMB_SCALE(%ebp),%eax
	movl	%eax,LMB_INVERSE(%ebp)
	cmpl	$0,C(lightmap_single_table_valid)
	je	.Llightmap_single_rebuild
	movl	C(lightmap_single_first),%edx
	cmpl	LMB_FIRST(%ebp),%edx
	jne	.Llightmap_single_rebuild
	movl	C(lightmap_single_inverse_scale),%edx
	cmpl	LMB_INVERSE(%ebp),%edx
	je	.Llightmap_single_table_ready

.Llightmap_single_rebuild:
	movl	$0,LMB_INDEX(%ebp)
	movl	$C(lightmap_single_table),%edi
.Llightmap_single_table_loop:
	movl	LMB_INDEX(%ebp),%eax
	mull	LMB_FIRST(%ebp)
	subl	LMB_INVERSE(%ebp),%eax
	negl	%eax
	sarl	$2,%eax
	cmpl	$64,%eax
	jge	.Llightmap_single_table_store
	movl	$64,%eax
.Llightmap_single_table_store:
	movl	LMB_INDEX(%ebp),%ecx
	movl	%eax,(%edi,%ecx,4)
	incl	LMB_INDEX(%ebp)
	cmpl	$256,LMB_INDEX(%ebp)
	jl	.Llightmap_single_table_loop
	movl	LMB_FIRST(%ebp),%eax
	movl	%eax,C(lightmap_single_first)
	movl	LMB_INVERSE(%ebp),%eax
	movl	%eax,C(lightmap_single_inverse_scale)
	movl	$1,C(lightmap_single_table_valid)

.Llightmap_single_table_ready:
#ifdef PROFILE486
	movl	C(bench486_lm_single_texels),%eax
	addl	LMB_SIZE(%ebp),%eax
	movl	%eax,C(bench486_lm_single_texels)
#endif
	movl	LMB_LIGHTMAP(%ebp),%esi
	movl	$C(lightmap_single_table),%ebx
	movl	$C(blocklights),%edi
	movl	LMB_SIZE(%ebp),%ecx
.Llightmap_single_output_loop:
	movzbl	(%esi),%eax
	movl	(%ebx,%eax,4),%eax
	movl	%eax,(%edi)
	incl	%esi
	addl	$4,%edi
	decl	%ecx
	jnz	.Llightmap_single_output_loop
	jmp	.Llightmap_return

.Llightmap_fused_styles:
	cmpb	$255,lm_surface_styles+2(%esi)
	jne	.Llightmap_fused_check_map3
	movl	$2,LMB_MAPS(%ebp)
	jmp	.Llightmap_fused_dispatch
.Llightmap_fused_check_map3:
	cmpb	$255,lm_surface_styles+3(%esi)
	jne	.Llightmap_fused_map4
	movl	$3,LMB_MAPS(%ebp)
	jmp	.Llightmap_fused_dispatch
.Llightmap_fused_map4:
	movl	$4,LMB_MAPS(%ebp)
.Llightmap_fused_dispatch:
#ifdef PROFILE486
	movl	C(bench486_lm_fused_texels),%eax
	addl	LMB_SIZE(%ebp),%eax
	movl	%eax,C(bench486_lm_fused_texels)
	movl	LMB_MAPS(%ebp),%edx
	shll	$2,%edx
	movl	LMB_SIZE(%ebp),%eax
	addl	%eax,C(bench486_lm_fused_maps)(,%edx,1)
#endif
	leal	lm_drawsurf_lightadj+C(r_drawsurf),%eax
	pushl	%eax
	pushl	LMB_SCALE(%ebp)
	pushl	LMB_MAPS(%ebp)
	pushl	LMB_SIZE(%ebp)
	pushl	LMB_LIGHTMAP(%ebp)
	pushl	$C(blocklights)
#ifdef ASM486_FUSED_LIGHTMAP
	call	C(R_BuildLightMapFusedNoDlights_asm486)
#else
	call	C(R_BuildLightMapFusedNoDlights_C)
#endif
	addl	$24,%esp
	jmp	.Llightmap_return

.Llightmap_style_accumulate:
	movl	$1,LMB_MAPS(%ebp)
.Llightmap_count_styles:
	movl	LMB_MAPS(%ebp),%eax
	cmpl	$4,%eax
	jge	.Llightmap_styles_dispatch
	cmpb	$255,lm_surface_styles(%esi,%eax)
	je	.Llightmap_styles_dispatch
	incl	LMB_MAPS(%ebp)
	jmp	.Llightmap_count_styles
.Llightmap_styles_dispatch:
	leal	lm_drawsurf_lightadj+C(r_drawsurf),%eax
	pushl	%eax
	pushl	LMB_SCALE(%ebp)
	pushl	LMB_MAPS(%ebp)
	pushl	LMB_SIZE(%ebp)
	pushl	LMB_LIGHTMAP(%ebp)
	pushl	$C(blocklights)
#ifdef ASM486_LIGHTMAP_STYLES
	call	C(R_BuildLightMapStyles_asm486)
#else
	call	C(R_BuildLightMapStyles_C)
#endif
	addl	$24,%esp
	jmp	.Llightmap_dynamic_lights

.Llightmap_ambient_only:
	movl	$C(blocklights),%edi
	movl	LMB_SIZE(%ebp),%ecx
	movl	LMB_SCALE(%ebp),%eax
	cld
	rep	stosl

.Llightmap_dynamic_lights:
	movl	LMB_SURF(%ebp),%esi
	movl	lm_surface_dlightframe(%esi),%eax
	cmpl	C(r_framecount),%eax
	jne	.Llightmap_normalize
	movl	$0,C(r_dlight_contributed)
	call	C(R_AddDynamicLights)

.Llightmap_normalize:
	pushl	LMB_SIZE(%ebp)
	pushl	$C(blocklights)
#ifdef ASM486_LIGHTMAP_NORMALIZE
	call	C(R_BuildLightMapNormalize_asm486)
#else
	call	C(R_BuildLightMapNormalize_C)
#endif
	addl	$8,%esp
	jmp	.Llightmap_return

.Llightmap_fullbright:
	movl	$C(blocklights),%edi
	movl	LMB_SIZE(%ebp),%ecx
	xorl	%eax,%eax
	cld
	rep	stosl

.Llightmap_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_DYNAMIC_LIGHT_PROJECTION

.set DLP_FIST_TMP, 4
.set DLP_CW_CEIL,  10
.set DLP_CW_CHOP,  12
.set DLP_CW_OLD,   14

	.p2align 4,,15
// int R_AddDynamicLightProject_asm486(int lnum, msurface_t *surf,
//     int smax, int tmax, float *local0, float *local1, int *local0_int,
//     int *local1_int, int *idist_limit, int *irad, int *all_lit)
// Preserve the x87 evaluation order and temporary rounding modes emitted by
// the optimized C reference. The scratch area mirrors its CW and conversion
// temporaries while the projection and all surface decisions run in assembly.
C(R_AddDynamicLightProject_asm486):
	.globl C(R_AddDynamicLightProject_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$20,%esp

	movl	40(%esp),%ecx		// lnum
	shll	$5,%ecx
	movl	44(%esp),%esi		// surf
	movl	64(%esp),%edi		// local0_int output
	movl	72(%esp),%ebx		// idist_limit output
	movl	12(%esi),%eax		// surf->plane

	// Keep planedist in extended precision as the C compiler does.
	flds	C(cl_dlights)(%ecx)
	fmuls	pl_normal(%eax)
	flds	C(cl_dlights)+4(%ecx)
	fmuls	pl_normal+4(%eax)
	faddp	%st,%st(1)
	fsubs	pl_dist(%eax)
	flds	C(cl_dlights)+8(%ecx)
	fmuls	pl_normal+8(%eax)
	faddp	%st,%st(1)

	// rad = radius - fabs(planedist); reject when rad < minlight.
	fld	%st(0)
	fabs
	fsubrs	C(cl_dlights)+12(%ecx)
	flds	C(cl_dlights)+24(%ecx)
	fcom	%st(1)
	fnstsw	%ax
	testb	$0x45,%ah
	je	.Ldlight_project_reject
	movl	52(%esi),%edx		// surf->texinfo

	// irad = trunc(rad * 256), using C's round-toward-zero conversion.
	flds	.Ldlight_project_256
	fld	%st(2)
	fmul	%st(1),%st
	fnstcw	DLP_CW_OLD(%esp)
	movw	DLP_CW_OLD(%esp),%bp
	orl	$0x0c00,%ebp
	movw	%bp,DLP_CW_CHOP(%esp)
	movl	76(%esp),%eax		// irad output
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	(%eax)
	fldcw	DLP_CW_OLD(%esp)

	// idist_limit = ceil((rad - minlight) * 256).
	fxch	%st(2)
	fsubp	%st,%st(1)
	fmulp	%st,%st(1)
	fnstcw	DLP_CW_OLD(%esp)
	movw	DLP_CW_OLD(%esp),%bp
	andl	$0xfffff3ff,%ebp
	orl	$0x0800,%ebp
	movw	%bp,DLP_CW_CEIL(%esp)
	fldcw	DLP_CW_CEIL(%esp)
	frndint
	fldcw	DLP_CW_OLD(%esp)
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	DLP_FIST_TMP(%esp)
	fldcw	DLP_CW_OLD(%esp)
	movl	DLP_FIST_TMP(%esp),%eax
	addl	$255,%eax
	sarl	$8,%eax
	movl	%eax,(%ebx)

	// Project the light onto the plane and into both texture axes.
	movl	12(%esi),%ebp		// surf->plane
	flds	pl_normal(%ebp)
	fmul	%st(1),%st
	fsubrs	C(cl_dlights)(%ecx)
	flds	pl_normal+4(%ebp)
	fmul	%st(2),%st
	fsubrs	C(cl_dlights)+4(%ecx)
	fxch	%st(2)
	fmuls	pl_normal+8(%ebp)
	fsubrs	C(cl_dlights)+8(%ecx)
	flds	12(%edx)
	fisubs	44(%esi)
	flds	(%edx)
	fmul	%st(3),%st
	faddp	%st,%st(1)
	flds	4(%edx)
	fmul	%st(4),%st
	faddp	%st,%st(1)
	flds	8(%edx)
	fmul	%st(2),%st
	faddp	%st,%st(1)
	flds	28(%edx)
	fisubs	46(%esi)
	fxch	%st(3)
	fmuls	16(%edx)
	faddp	%st,%st(3)
	fxch	%st(3)
	fmuls	20(%edx)
	faddp	%st,%st(2)
	fmuls	24(%edx)
	faddp	%st,%st(1)
	fxch	%st(1)
	movl	56(%esp),%esi		// local0 output
	fsts	(%esi)
	fxch	%st(1)
	movl	60(%esp),%ecx		// local1 output
	fsts	(%ecx)
	fxch	%st(1)
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	(%edi)
	fldcw	DLP_CW_OLD(%esp)
	fldcw	DLP_CW_CHOP(%esp)
	fistpl	DLP_FIST_TMP(%esp)
	fldcw	DLP_CW_OLD(%esp)
	movl	DLP_FIST_TMP(%esp),%ebp
	movl	68(%esp),%edx		// local1_int output
	movl	%ebp,(%edx)
	movl	(%edi),%esi		// local0_int

	// Match the C nearest-rectangle surface-edge cull.
	movl	%esi,%eax
	testl	%esi,%esi
	js	.Ldlight_project_abs_s
.Ldlight_project_s_ready:
	movl	48(%esp),%edi		// smax
	leal	-1(%edi),%ecx
	shll	$4,%ecx
	movl	%esi,%edx
	subl	%ecx,%edx
	js	.Ldlight_project_abs_s_edge
.Ldlight_project_s_edge_ready:
	cmpl	%edx,%eax
	jl	.Ldlight_project_use_s_edge
.Ldlight_project_sd_ready:
	movl	%ebp,%edx			// local1_int
	testl	%ebp,%ebp
	js	.Ldlight_project_abs_t
.Ldlight_project_t_ready:
	movl	52(%esp),%esi		// tmax
	leal	-1(%esi),%ecx
	shll	$4,%ecx
	movl	%ebp,%edi
	subl	%ecx,%edi
	js	.Ldlight_project_abs_t_edge
.Ldlight_project_t_edge_ready:
	cmpl	%edi,%edx
	jl	.Ldlight_project_use_t_edge
.Ldlight_project_td_ready:
	cmpl	%edx,%eax
	jl	.Ldlight_project_td_larger
	sarl	$1,%edx
	addl	%edx,%eax
	jmp	.Ldlight_project_store_all_lit
.Ldlight_project_td_larger:
	sarl	$1,%eax
	addl	%eax,%edx
	movl	%edx,%eax
.Ldlight_project_store_all_lit:
	xorl	%ecx,%ecx
	cmpl	(%ebx),%eax
	setl	%cl
	movl	80(%esp),%ebx		// all_lit output
	movl	%ecx,(%ebx)
	movl	$1,%eax
	jmp	.Ldlight_project_return

.Ldlight_project_abs_s:
	negl	%eax
	jmp	.Ldlight_project_s_ready
.Ldlight_project_abs_s_edge:
	negl	%edx
	jmp	.Ldlight_project_s_edge_ready
.Ldlight_project_use_s_edge:
	movl	%edx,%eax
	jmp	.Ldlight_project_sd_ready
.Ldlight_project_abs_t:
	negl	%edx
	jmp	.Ldlight_project_t_ready
.Ldlight_project_abs_t_edge:
	negl	%edi
	jmp	.Ldlight_project_t_edge_ready
.Ldlight_project_use_t_edge:
	movl	%edi,%edx
	jmp	.Ldlight_project_td_ready

.Ldlight_project_reject:
	fstp	%st(0)
	fstp	%st(0)
	fstp	%st(0)
	xorl	%eax,%eax
.Ldlight_project_return:
	addl	$20,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

#endif

#ifdef ASM486_DYNAMIC_LIGHT_ORCHESTRATION

.set DLO_SURF,        -4
.set DLO_SMAX,        -8
.set DLO_TMAX,       -12
// -16 remains unused; keep the sparse surface-light mask in EDI.
.set DLO_CONTRIB,    -20
.set DLO_LOCAL0,     -24
.set DLO_LOCAL1,     -28
.set DLO_LOCAL0_INT, -32
.set DLO_LOCAL1_INT, -36
.set DLO_LIMIT,      -40
.set DLO_IRAD,       -44
.set DLO_ALL_LIT,    -48
	.p2align 4,,15
// void R_AddDynamicLights(void)
// Keep the sparse surface-bit scan and the C/ASM sample-loop choice here.
// Projection and surface culling run in the separate assembly x87 helper.
C(R_AddDynamicLights):
	.globl C(R_AddDynamicLights)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$48,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	C(r_drawsurf)+dl_drawsurf_surf,%esi
	movl	%esi,DLO_SURF(%ebp)
	movswl	dl_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLO_SMAX(%ebp)
	movswl	dl_surface_extents+2(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLO_TMAX(%ebp)
	// The ASM callees preserve EDI; the C sample fallback follows i386 ABI.
	movl	dl_surface_dlightbits(%esi),%edi
	movl	C(r_dlight_contributed),%eax
	movl	%eax,DLO_CONTRIB(%ebp)

.Ldlight_orchestration_next:
	testl	%edi,%edi
	je	.Ldlight_orchestration_done
	bsfl	%edi,%ebx
	btrl	%ebx,%edi

	// int project(lnum, surf, smax, tmax, &local0, &local1,
	//             &local0_int, &local1_int, &limit, &irad, &all_lit)
	leal	DLO_ALL_LIT(%ebp),%eax
	pushl	%eax
	leal	DLO_IRAD(%ebp),%eax
	pushl	%eax
	leal	DLO_LIMIT(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL1_INT(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL0_INT(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL1(%ebp),%eax
	pushl	%eax
	leal	DLO_LOCAL0(%ebp),%eax
	pushl	%eax
	pushl	DLO_TMAX(%ebp)
	pushl	DLO_SMAX(%ebp)
	pushl	DLO_SURF(%ebp)
	pushl	%ebx
	call	C(R_AddDynamicLightProject_asm486)
	addl	$44,%esp
	testl	%eax,%eax
	je	.Ldlight_orchestration_next

#ifdef ASM486_DYNAMIC_LIGHTS
	// Keep integer s coordinates while preserving C's fractional t-row rounding.
	pushl	DLO_ALL_LIT(%ebp)
	pushl	DLO_IRAD(%ebp)
	pushl	DLO_LIMIT(%ebp)
	pushl	DLO_LOCAL1(%ebp)
	pushl	DLO_LOCAL1_INT(%ebp)
	pushl	DLO_LOCAL0_INT(%ebp)
	pushl	DLO_TMAX(%ebp)
	pushl	DLO_SMAX(%ebp)
	pushl	$C(blocklights)
	call	C(R_AddDynamicLightSamples_asm486)
	addl	$36,%esp
#else
	// The selectable C reference consumes the original floating coordinates.
	pushl	DLO_IRAD(%ebp)
	pushl	DLO_LIMIT(%ebp)
	pushl	DLO_LOCAL1(%ebp)
	pushl	DLO_LOCAL0(%ebp)
	pushl	DLO_TMAX(%ebp)
	pushl	DLO_SMAX(%ebp)
	pushl	$C(blocklights)
	call	C(R_AddDynamicLightSamples_C)
	addl	$28,%esp
#endif
	orl	%eax,DLO_CONTRIB(%ebp)
	jmp	.Ldlight_orchestration_next

.Ldlight_orchestration_done:
	movl	DLO_CONTRIB(%ebp),%eax
	movl	%eax,C(r_dlight_contributed)
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_DLIGHT_CONTRIBUTES

.set DLC_SURF,        -4
.set DLC_SMAX,        -8
.set DLC_TMAX,       -12
.set DLC_BITS,       -16
.set DLC_LOCAL0,     -20
.set DLC_LOCAL1,     -24
.set DLC_LOCAL0_INT, -28
.set DLC_LOCAL1_INT, -32
.set DLC_LIMIT,      -36
.set DLC_IRAD,       -40
.set DLC_ALL_LIT,    -44
	.p2align 4,,15
// int R_DlightContributes_asm486(msurface_t *surf)
// Test the nearest clamped texel for each sparse surface light bit. The
// projection helper supplies the same ceil distance limit used by the full
// dynamic-light sample loop, so an eligible texel is exactly idist < limit.
	.globl C(R_DlightContributes_asm486)
	.globl C(R_DlightContributes)
C(R_DlightContributes_asm486):
C(R_DlightContributes):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$44,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%esi
	movl	%esi,DLC_SURF(%ebp)
	movswl	dl_surface_extents(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLC_SMAX(%ebp)
	movswl	dl_surface_extents+2(%esi),%eax
	sarl	$4,%eax
	incl	%eax
	movl	%eax,DLC_TMAX(%ebp)
	movl	dl_surface_dlightbits(%esi),%eax
	movl	%eax,DLC_BITS(%ebp)

.Ldlight_contributes_next:
	movl	DLC_BITS(%ebp),%eax
	testl	%eax,%eax
	je	.Ldlight_contributes_no
	bsfl	%eax,%ebx
	leal	-1(%eax),%edx
	andl	%edx,%eax
	movl	%eax,DLC_BITS(%ebp)

	// Project this light and retain C's float coordinates and int truncation.
	leal	DLC_ALL_LIT(%ebp),%eax
	pushl	%eax
	leal	DLC_IRAD(%ebp),%eax
	pushl	%eax
	leal	DLC_LIMIT(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL1_INT(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL0_INT(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL1(%ebp),%eax
	pushl	%eax
	leal	DLC_LOCAL0(%ebp),%eax
	pushl	%eax
	pushl	DLC_TMAX(%ebp)
	pushl	DLC_SMAX(%ebp)
	pushl	DLC_SURF(%ebp)
	pushl	%ebx
	call	C(R_AddDynamicLightProject_asm486)
	addl	$44,%esp
	testl	%eax,%eax
	je	.Ldlight_contributes_next

	// C clamps (local + 8) / 16 to the nearest sample, then measures sd/td.
	movl	DLC_LOCAL0_INT(%ebp),%eax
	testl	%eax,%eax
	jle	.Ldlight_contributes_s_zero
	addl	$8,%eax
	sarl	$4,%eax
	cmpl	DLC_SMAX(%ebp),%eax
	jl	.Ldlight_contributes_s_ready
	movl	DLC_SMAX(%ebp),%eax
	decl	%eax
	jmp	.Ldlight_contributes_s_ready
.Ldlight_contributes_s_zero:
	xorl	%eax,%eax
.Ldlight_contributes_s_ready:
	shll	$4,%eax
	movl	DLC_LOCAL0_INT(%ebp),%esi
	subl	%eax,%esi
	testl	%esi,%esi
	jge	.Ldlight_contributes_sd_ready
	negl	%esi
.Ldlight_contributes_sd_ready:

	movl	DLC_LOCAL1_INT(%ebp),%eax
	testl	%eax,%eax
	jle	.Ldlight_contributes_t_zero
	addl	$8,%eax
	sarl	$4,%eax
	cmpl	DLC_TMAX(%ebp),%eax
	jl	.Ldlight_contributes_t_ready
	movl	DLC_TMAX(%ebp),%eax
	decl	%eax
	jmp	.Ldlight_contributes_t_ready
.Ldlight_contributes_t_zero:
	xorl	%eax,%eax
.Ldlight_contributes_t_ready:
	shll	$4,%eax
	movl	DLC_LOCAL1_INT(%ebp),%edx
	subl	%eax,%edx
	testl	%edx,%edx
	jge	.Ldlight_contributes_td_ready
	negl	%edx
.Ldlight_contributes_td_ready:

	cmpl	%edx,%esi
	jle	.Ldlight_contributes_td_dominant
	movl	%esi,%eax
	sarl	$1,%edx
	addl	%edx,%eax
	jmp	.Ldlight_contributes_test
.Ldlight_contributes_td_dominant:
	movl	%edx,%eax
	sarl	$1,%esi
	addl	%esi,%eax
.Ldlight_contributes_test:
	cmpl	DLC_LIMIT(%ebp),%eax
	jl	.Ldlight_contributes_yes
	jmp	.Ldlight_contributes_next

.Ldlight_contributes_yes:
	movl	$1,%eax
	jmp	.Ldlight_contributes_return
.Ldlight_contributes_no:
	xorl	%eax,%eax
.Ldlight_contributes_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif
