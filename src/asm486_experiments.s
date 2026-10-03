// asm486_experiments.s
//
// Small, isolated 486 experiment implementations.
// The original C paths remain available as the runtime reference; build-time
// switches select these routines only for a measured experiment.

#include "asm_i386.h"
#include "d_ifacea.h"

	.data
	.align 1

Ltexture_animation_broken:
	.ascii	"R_TextureAnimation: broken cycle\0"
Ltexture_animation_infinite:
	.ascii	"R_TextureAnimation: infinite cycle\0"
	.p2align 4,,15
Lalias_transform_coords:
	.long	0, 0, 0
Lalias_transform_temp:
	.long	0

#ifdef TARGET_I386
	.p2align 4,,15
// i386 replacements for the i486 register-form BT and BTR in
// R_RecursiveWorldNodeClip_asm486.
//
// BT r/m32,r32 and BTR r/m32,r32 do not exist on a 386; only the immediate form
// (0F BA) does.  The bit index there is the frustum plane loop counter, which
// runs 0..3 and exits at 4, so a four-entry mask table expresses both
// operations exactly -- and, unlike a ROLL through CL, it needs no scratch
// register, which matters because all six registers are live in that loop.
// Emitted only for the i386 build so the i486 object keeps its current .data.
Lplane_bit_masks:
	.long	1, 2, 4, 8
#endif

	.text
	.p2align 4,,15

// void Q_memset_asm486(void *dest, int fill, int count)
C(Q_memset_asm486):
	.globl C(Q_memset_asm486)
	pushl	%edi
	movl	8(%esp),%edi		// dest
	movl	12(%esp),%eax		// fill
	movl	16(%esp),%ecx		// count
	testl	%ecx,%ecx
	jle	.Lmemset_done

	andl	$0xff,%eax

// Align the destination with byte stores.  The remaining count is kept in
// ECX until the dword count and tail count are split below.
.Lmemset_align:
	testl	$3,%edi
	jz	.Lmemset_aligned
	movb	%al,(%edi)
	incl	%edi
	decl	%ecx
	jnz	.Lmemset_align
	jmp	.Lmemset_done

.Lmemset_aligned:
// Expand the byte into a repeated dword pattern without newer instructions.
	movl	%eax,%edx
	shll	$8,%edx
	orl	%edx,%eax
	movl	%eax,%edx
	shll	$16,%edx
	orl	%edx,%eax

	movl	%ecx,%edx			// preserve the byte tail count
	shrl	$2,%ecx
	jz	.Lmemset_tail
	cld
	rep
	stosl

.Lmemset_tail:
	andl	$3,%edx
	jz	.Lmemset_done
	movl	%edx,%ecx
	cld
	rep
	stosb

.Lmemset_done:
	popl	%edi
	ret

	.p2align 4,,15

// void Q_memcpy_asm486(void *dest, void *src, int count)
// Matches the existing Q_memcpy contract: forward copy, no overlap handling.
C(Q_memcpy_asm486):
	.globl C(Q_memcpy_asm486)
	pushl	%edi
	pushl	%esi
	movl	12(%esp),%edi		// dest
	movl	16(%esp),%esi		// src
	movl	20(%esp),%ecx		// count
	testl	%ecx,%ecx
	jle	.Lmemcpy_done

// A dword loop is safe only when both pointers have the same alignment.
	movl	%edi,%eax
xorl	%esi,%eax
	testl	$3,%eax
jnz	.Lmemcpy_bytes

.Lmemcpy_align:
	testl	$3,%edi
	jz	.Lmemcpy_aligned
	movb	(%esi),%al
	movb	%al,(%edi)
	incl	%esi
	incl	%edi
	decl	%ecx
	jnz	.Lmemcpy_align
	jmp	.Lmemcpy_done

.Lmemcpy_aligned:
	movl	%ecx,%edx			// preserve the byte tail count
	shrl	$2,%ecx
	jz	.Lmemcpy_tail
	cld
	rep
	movsl

.Lmemcpy_tail:
	andl	$3,%edx
	jz	.Lmemcpy_done
	movl	%edx,%ecx
	cld
	rep
	movsb
	jmp	.Lmemcpy_done

.Lmemcpy_bytes:
	cld
	rep
	movsb

.Lmemcpy_done:
	popl	%esi
	popl	%edi
	ret

	.p2align 4,,15

// void *D_GetTextureAxesHit_asm486(void *entry, void *texinfo,
//     void *entity, int frame)
// Probe the three-key texture-axis cache record without touching the cached
// axis vectors.  The caller performs the hash/index calculation and handles
// the miss path in C.
C(D_GetTextureAxesHit_asm486):
	.globl C(D_GetTextureAxesHit_asm486)
	movl	4(%esp),%eax		// entry
	testl	%eax,%eax
	jz	.Ltexaxis_miss
	movl	8(%esp),%edx		// texinfo
	cmpl	(%eax),%edx
	jne	.Ltexaxis_miss
	movl	12(%esp),%edx		// entity
	cmpl	4(%eax),%edx
	jne	.Ltexaxis_miss
	movl	16(%esp),%edx		// frame
	cmpl	8(%eax),%edx
	jne	.Ltexaxis_miss
	ret

.Ltexaxis_miss:
	xorl	%eax,%eax
	ret

	.p2align 4,,15

// void *D_CacheSurfaceHit_asm486(void *cache, int surface_dlightframe,
//     int frame, void *texture, int *lightadj)
// Check the non-DEBUG surfcache_t fast-path fields.  The caller keeps texture
// animation, light-style loads, allocation, and surface generation in C.
C(D_CacheSurfaceHit_asm486):
	.globl C(D_CacheSurfaceHit_asm486)
	movl	4(%esp),%eax		// cache
	testl	%eax,%eax
	jz	.Lsurface_cache_miss
	cmpl	$0,24(%eax)		// cache->dlight
	jne	.Lsurface_cache_miss
	movl	8(%esp),%edx		// surface->dlightframe
	cmpl	12(%esp),%edx		// r_framecount
	je	.Lsurface_cache_miss
	movl	16(%esp),%edx		// r_drawsurf.texture
	cmpl	40(%eax),%edx		// cache->texture
	jne	.Lsurface_cache_miss
	movl	20(%esp),%edx		// r_drawsurf.lightadj
	movl	(%edx),%ecx
	cmpl	8(%eax),%ecx
	jne	.Lsurface_cache_miss
	movl	4(%edx),%ecx
	cmpl	12(%eax),%ecx
	jne	.Lsurface_cache_miss
	movl	8(%edx),%ecx
	cmpl	16(%eax),%ecx
	jne	.Lsurface_cache_miss
	movl	12(%edx),%ecx
	cmpl	20(%eax),%ecx
	jne	.Lsurface_cache_miss
	ret

.Lsurface_cache_miss:
	xorl	%eax,%eax
	ret

	.p2align 4,,15

// int D_MipLevelForScale_asm486(float scale)
// Use the 486 x87 compare flags for the three descending mip thresholds.
// fcomps pops the temporary scale, leaving no value on the FP stack.
C(D_MipLevelForScale_asm486):
	.globl C(D_MipLevelForScale_asm486)
	flds	4(%esp)
	fcoms	C(d_scalemip)
	fnstsw	%ax
	testb	$1,%ah			// C0: scale < d_scalemip[0]
	jnz	.Lmip_check_1
	xorl	%eax,%eax
	fstp	%st(0)
	jmp	.Lmip_clamp

.Lmip_check_1:
	fcoms	C(d_scalemip)+4
	fnstsw	%ax
	testb	$1,%ah			// C0: scale < d_scalemip[1]
	jnz	.Lmip_check_2
	movl	$1,%eax
	fstp	%st(0)
	jmp	.Lmip_clamp

.Lmip_check_2:
	fcomps	C(d_scalemip)+8
	fnstsw	%ax
	testb	$1,%ah			// C0: scale < d_scalemip[2]
	jnz	.Lmip_level_3
	movl	$2,%eax
	fstp	%st(0)
	jmp	.Lmip_clamp

.Lmip_level_3:
	movl	$3,%eax

.Lmip_clamp:
	movl	C(d_minmip),%edx
	cmpl	%edx,%eax
	jge	.Lmip_return
	movl	%edx,%eax
.Lmip_return:
	ret

	.p2align 4,,15

// texture_t *R_TextureAnimationFrame_asm486(texture_t *base, int relative)
// Select the frame whose [anim_min, anim_max) interval contains relative.
// The caller handles alternate animations, the no-animation fast path, and
// the relative-time calculation.  Keep the C loop as the reference path.
C(R_TextureAnimationFrame_asm486):
	.globl C(R_TextureAnimationFrame_asm486)
	movl	4(%esp),%eax		// base
	movl	8(%esp),%edx		// relative
	xorl	%ecx,%ecx			// count

.Ltexture_animation_check:
	cmpl	%edx,28(%eax)		// base->anim_min > relative
	jg	.Ltexture_animation_next
	cmpl	%edx,32(%eax)		// base->anim_max <= relative
	jle	.Ltexture_animation_next
	ret

.Ltexture_animation_next:
	movl	36(%eax),%eax		// base->anim_next
	testl	%eax,%eax
	jz	.Ltexture_animation_broken
	incl	%ecx
	cmpl	$100,%ecx
	jg	.Ltexture_animation_infinite
	jmp	.Ltexture_animation_check

.Ltexture_animation_broken:
	pushl	$Ltexture_animation_broken
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	ret

.Ltexture_animation_infinite:
	pushl	$Ltexture_animation_infinite
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	ret

	.p2align 4,,15

// void R_BuildLightMapStyles_asm486(unsigned *dest, byte *lightmap,
//                                    int size, int maps, unsigned scale,
//                                    unsigned *lightadj)
// Combine contiguous 8-bit lightmap planes in the same order as the C
// reference.  The first plane includes ambient scale; later planes add.
C(R_BuildLightMapStyles_asm486):
	.globl C(R_BuildLightMapStyles_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%edi		// dest
	movl	24(%esp),%esi		// lightmap
	movl	32(%esp),%ebp		// maps
	movl	40(%esp),%ebx		// lightadj
	cmpl	$0,28(%esp)
	jle	.Llightmap_styles_done
	testl	%ebp,%ebp
	jle	.Llightmap_styles_done

	xorl	%ecx,%ecx			// pixel index
.Llightmap_styles_first:
	movzbl	(%esi,%ecx),%eax
	mull	(%ebx)
	addl	36(%esp),%eax		// scale
	movl	%eax,(%edi,%ecx,4)
	incl	%ecx
	cmpl	28(%esp),%ecx
	jb	.Llightmap_styles_first

	decl	%ebp
	jz	.Llightmap_styles_done
	addl	28(%esp),%esi			// next lightmap plane
	addl	$4,%ebx			// next style adjustment

.Llightmap_styles_extra:
	xorl	%ecx,%ecx
.Llightmap_styles_extra_loop:
	movzbl	(%esi,%ecx),%eax
	mull	(%ebx)
	addl	%eax,(%edi,%ecx,4)
	incl	%ecx
	cmpl	28(%esp),%ecx
	jb	.Llightmap_styles_extra_loop

	decl	%ebp
	jz	.Llightmap_styles_done
	addl	28(%esp),%esi
	addl	$4,%ebx
	jmp	.Llightmap_styles_extra

.Llightmap_styles_done:
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

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
//                                     int idist_limit, int irad,
//                                     int all_lit)
// Walk one dynamic-light sample rectangle using the same integer distance
// rule as R_AddDynamicLights.  The floating-point projection remains in C;
// this helper owns only the repeated sample-distance and accumulation loop.
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
	addl	60(%esp),%eax; \
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
	addl	60(%esp),%eax; \
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
	movl	56(%esp),%ebx		// idist_limit
	xorl	%edi,%edi			// contributed count
	movl	44(%esp),%eax		// tmax
	movl	%eax,12(%esp)
	movl	52(%esp),%eax		// signed td for the current row
	movl	%eax,0(%esp)
	movl	$0,4(%esp)		// contributed
	cmpl	$0,64(%esp)		// all sampled distances pass
	jz	.Ldlight_row
	movl	$1,%edi
	jmp	.Ldlight_all_row

.Ldlight_row:
	// ECX is the absolute row distance and EBP is td >> 1.  Keep the
	// signed row distance in the local block for the next row.
	movl	0(%esp),%eax
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

.Ldlight_tail_table:
	.long .Ldlight_row_done, .Ldlight_tail1, .Ldlight_tail2, .Ldlight_tail3
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

.Ldlight_all_tail_table:
	.long .Ldlight_row_done, .Ldlight_all_tail1, .Ldlight_all_tail2, .Ldlight_all_tail3
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

	.p2align 4,,15

// double R_RecursiveWorldNodePlaneDot_asm486(mplane_t *plane)
// Calculate the viewpoint/plane dot used to choose the front BSP child.
// Axis-aligned planes avoid the three x87 multiplies; arbitrary planes keep
// the same left-to-right multiply/add order as the C DotProduct macro.
C(R_RecursiveWorldNodePlaneDot_asm486):
	.globl C(R_RecursiveWorldNodePlaneDot_asm486)
	movl	4(%esp),%edx		// plane
	movzbl	16(%edx),%eax		// plane->type
	testl	%eax,%eax
	jz	.Lbsp_plane_dot_x
	cmpl	$1,%eax
	je	.Lbsp_plane_dot_y
	cmpl	$2,%eax
	je	.Lbsp_plane_dot_z

	flds	C(modelorg)
	fmuls	(%edx)
	flds	C(modelorg)+4
	fmuls	4(%edx)
	faddp	%st,%st(1)
	flds	C(modelorg)+8
	fmuls	8(%edx)
	faddp	%st,%st(1)
	fsubs	12(%edx)
	ret

.Lbsp_plane_dot_x:
	flds	C(modelorg)
	fsubs	12(%edx)
	ret

.Lbsp_plane_dot_y:
	flds	C(modelorg)+4
	fsubs	12(%edx)
	ret

.Lbsp_plane_dot_z:
	flds	C(modelorg)+8
	fsubs	12(%edx)
	ret

	.p2align 4,,15

// int R_RecursiveWorldNodeClip_asm486(mnode_t *node, int clipflags)
// Evaluate the four frustum planes for one visible BSP node.  The C helper
// returns -1 for a fully rejected node and otherwise returns the reduced
// clip mask; use the same contract here so the caller keeps its recursion and
// surface logic unchanged.
C(R_RecursiveWorldNodeClip_asm486):
	.globl C(R_RecursiveWorldNodeClip_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%edx		// node
	movl	24(%esp),%ecx		// clipflags
	testl	%ecx,%ecx
	jz	.Lbsp_clip_done
	xorl	%ebx,%ebx			// plane index
	leal	C(pfrustum_indexes),%esi	// array of four index pointers
	leal	C(view_clipplanes),%edi	// first clipplane

.Lbsp_clip_plane:
#ifdef TARGET_I386
	// BT leaves the tested bit in CF; TEST leaves the *equality* in ZF and
	// always clears CF.  So the "bit not set" branch has to be jz, not jnc.
	movl	Lplane_bit_masks(,%ebx,4),%eax
	testl	%eax,%ecx
	jz	.Lbsp_clip_next
#else
	btl	%ebx,%ecx
	jnc	.Lbsp_clip_next
#endif
	movl	(%esi),%eax			// pindex

	// DotProduct(rejectpt, plane->normal) - plane->dist.
	movl	0(%eax),%ebp
	filds	8(%edx,%ebp,2)
	fmuls	0(%edi)
	movl	4(%eax),%ebp
	filds	8(%edx,%ebp,2)
	fmuls	4(%edi)
	faddp	%st(0),%st(1)
	movl	8(%eax),%ebp
	filds	8(%edx,%ebp,2)
	fmuls	8(%edi)
	faddp	%st(0),%st(1)
	fsubs	12(%edi)
	ftst
	fnstsw	%ax
	testb	$4,%ah			// unordered (NaN): C <= is false
	jnz	.Lbsp_clip_reject_done
	testb	$0x41,%ah			// C0 or C3: d <= 0
	jnz	.Lbsp_clip_reject
.Lbsp_clip_reject_done:
	fstp	%st(0)
	movl	(%esi),%eax			// fnstsw %ax clobbered EAX

	// DotProduct(acceptpt, plane->normal) - plane->dist.
	movl	12(%eax),%ebp
	filds	8(%edx,%ebp,2)
	fmuls	0(%edi)
	movl	16(%eax),%ebp
	filds	8(%edx,%ebp,2)
	fmuls	4(%edi)
	faddp	%st(0),%st(1)
	movl	20(%eax),%ebp
	filds	8(%edx,%ebp,2)
	fmuls	8(%edi)
	faddp	%st(0),%st(1)
	fsubs	12(%edi)
	ftst
	fnstsw	%ax
	testb	$4,%ah			// unordered (NaN): C >= is false
	jnz	.Lbsp_clip_accept_done
	testb	$1,%ah			// C0: d < 0
	jnz	.Lbsp_clip_accept_done
#ifdef TARGET_I386
	movl	Lplane_bit_masks(,%ebx,4),%eax
	notl	%eax
	andl	%eax,%ecx			// node is entirely on screen
#else
	btrl	%ebx,%ecx			// node is entirely on screen
#endif
.Lbsp_clip_accept_done:
	fstp	%st(0)
	jmp	.Lbsp_clip_next

.Lbsp_clip_reject:
	fstp	%st(0)
	movl	$-1,%eax
	jmp	.Lbsp_clip_return

.Lbsp_clip_next:
	incl	%ebx
	addl	$4,%esi
	addl	$24,%edi
	cmpl	$4,%ebx
	jl	.Lbsp_clip_plane

.Lbsp_clip_done:
	movl	%ecx,%eax
.Lbsp_clip_return:
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

	.p2align 4,,15

// int R_AliasCheckBBoxProject_asm486(auxvert_t *viewaux,
//                                    finalvert_t *viewpts, int numv)
// Project the unclipped alias bounding-box vertices and return anyclip in the
// low byte and allclip in the next byte.  Keep the reciprocal and both screen
// coordinates in the x87 stack while the integer registers hold the loop
// state and clip masks.
#define bbox_aux_size	12
#define bbox_fv_flags	24
#define bbox_fv_size	32
#define bbox_r_fvrectx	60
#define bbox_r_fvrecty	64
#define bbox_r_fvrectright	92
#define bbox_r_fvrectbottom	96

C(R_AliasCheckBBoxProject_asm486):
	.globl C(R_AliasCheckBBoxProject_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%esi		// viewaux
	movl	24(%esp),%edi		// viewpts
	movl	28(%esp),%ecx		// numv
	xorl	%edx,%edx			// anyclip
	movl	$0x000f,%ebx			// allclip
	testl	%ecx,%ecx
	jle	.Lalias_bbox_project_done

.Lalias_bbox_project_loop:
	xorl	%ebp,%ebp			// flags
	testl	$0x0010,bbox_fv_flags(%edi)
	jnz	.Lalias_bbox_project_next

	// zi = 1.0 / viewaux->fv[2]; keep zi below the projected value.
	fld1
	fdivs	8(%esi)

	// v0 = viewaux->fv[0] * aliasxscale * zi + aliasxcenter.
	flds	0(%esi)
	fmuls	C(aliasxscale)
	fmul	%st(1),%st
	fadds	C(aliasxcenter)
	fcoms	C(r_refdef)+bbox_r_fvrectx
	fnstsw	%ax
	testb	$1,%ah
	jz	.Lalias_bbox_project_no_left
	orl	$0x0001,%ebp
.Lalias_bbox_project_no_left:
	fcoms	C(r_refdef)+bbox_r_fvrectright
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_no_right
	orl	$0x0004,%ebp
.Lalias_bbox_project_no_right:
	fstp	%st(0)			// discard v0, leave zi

	// v1 = viewaux->fv[1] * aliasyscale * zi + aliasycenter.
	flds	4(%esi)
	fmuls	C(aliasyscale)
	fmul	%st(1),%st
	fadds	C(aliasycenter)
	fcoms	C(r_refdef)+bbox_r_fvrecty
	fnstsw	%ax
	testb	$1,%ah
	jz	.Lalias_bbox_project_no_top
	orl	$0x0002,%ebp
.Lalias_bbox_project_no_top:
	fcoms	C(r_refdef)+bbox_r_fvrectbottom
	fnstsw	%ax
	testb	$0x45,%ah
	jnz	.Lalias_bbox_project_no_bottom
	orl	$0x0008,%ebp
.Lalias_bbox_project_no_bottom:
	fstp	%st(0)			// discard v1
	fstp	%st(0)			// discard zi

	orl	%ebp,%edx
	andl	%ebp,%ebx

.Lalias_bbox_project_next:
	addl	$bbox_aux_size,%esi
	addl	$bbox_fv_size,%edi
	decl	%ecx
	jnz	.Lalias_bbox_project_loop

.Lalias_bbox_project_done:
	shll	$8,%ebx
	movl	%ebx,%eax
	orl	%edx,%eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

	.p2align 4,,15

// void R_AliasTransformFinalVert_asm486(finalvert_t *fv, auxvert_t *av,
//                                        trivertx_t *pverts,
//                                        stvert_t *pstverts)
// Transform one clipped alias vertex and calculate its lighting value.  The
// input bytes are expanded once, then reused for all three x87 dot products.
C(R_AliasTransformFinalVert_asm486):
	.globl C(R_AliasTransformFinalVert_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	20(%esp),%edi		// fv
	movl	24(%esp),%ebp		// av
	movl	28(%esp),%esi		// pverts
	movl	32(%esp),%ebx		// pstverts

	movzbl	0(%esi),%eax
	movl	%eax,Lalias_transform_coords
	movzbl	1(%esi),%eax
	movl	%eax,Lalias_transform_coords+4
	movzbl	2(%esi),%eax
	movl	%eax,Lalias_transform_coords+8

	fildl	Lalias_transform_coords
	fmuls	C(aliastransform)+0
	fildl	Lalias_transform_coords+4
	fmuls	C(aliastransform)+4
	faddp	%st(0),%st(1)
	fildl	Lalias_transform_coords+8
	fmuls	C(aliastransform)+8
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+12
	fstps	0(%ebp)

	fildl	Lalias_transform_coords
	fmuls	C(aliastransform)+16
	fildl	Lalias_transform_coords+4
	fmuls	C(aliastransform)+20
	faddp	%st(0),%st(1)
	fildl	Lalias_transform_coords+8
	fmuls	C(aliastransform)+24
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+28
	fstps	4(%ebp)

	fildl	Lalias_transform_coords
	fmuls	C(aliastransform)+32
	fildl	Lalias_transform_coords+4
	fmuls	C(aliastransform)+36
	faddp	%st(0),%st(1)
	fildl	Lalias_transform_coords+8
	fmuls	C(aliastransform)+40
	faddp	%st(0),%st(1)
	fadds	C(aliastransform)+44
	fstps	8(%ebp)

	movl	stv_s(%ebx),%eax
	movl	%eax,fv_v+8(%edi)
	movl	stv_t(%ebx),%eax
	movl	%eax,fv_v+12(%edi)
	movl	stv_onseam(%ebx),%eax
	movl	%eax,fv_flags(%edi)

	movzbl	tv_lightnormalindex(%esi),%eax
	leal	(%eax,%eax,2),%eax
	flds	C(r_avertexnormals)(,%eax,4)
	fmuls	C(r_plightvec)
	flds	C(r_avertexnormals)+4(,%eax,4)
	fmuls	C(r_plightvec)+4
	faddp	%st(0),%st(1)
	flds	C(r_avertexnormals)+8(,%eax,4)
	fmuls	C(r_plightvec)+8
	faddp	%st(0),%st(1)
	fsts	Lalias_transform_temp
	movl	C(r_ambientlight),%eax
	movb	Lalias_transform_temp+3,%dl
	testb	$0x80,%dl
	jnz	.Lalias_transform_shaded
	fstp	%st(0)
	jmp	.Lalias_transform_store_light

.Lalias_transform_shaded:
	fmuls	C(r_shadelight)
	fistpl	Lalias_transform_temp
	addl	Lalias_transform_temp,%eax
	jns	.Lalias_transform_store_light
	xorl	%eax,%eax

.Lalias_transform_store_light:
	movl	%eax,fv_v+16(%edi)
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
