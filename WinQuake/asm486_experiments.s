// asm486_experiments.s
//
// Small, isolated 486 experiment implementations.
// The original C paths remain available as the runtime reference; build-time
// switches select these routines only for a measured experiment.

#include "asm_i386.h"

	.data
	.align 1

Ltexture_animation_broken:
	.ascii	"R_TextureAnimation: broken cycle\0"
Ltexture_animation_infinite:
	.ascii	"R_TextureAnimation: infinite cycle\0"

	.text
	.align 4

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
.Lmemset_tail_loop:
	movb	%al,(%edi)
	incl	%edi
	decl	%edx
	jnz	.Lmemset_tail_loop

.Lmemset_done:
	popl	%edi
	ret

	.align 4

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

	.align 4

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

	.align 4

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

	.align 4

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

	.align 4

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

	.align 4

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

.Llightmap_normalize_loop:
	movl	%edx,%eax
	subl	(%edi),%eax
	sarl	$2,%eax			// (8 - VID_CBITS), with VID_CBITS == 6
	cmpl	$64,%eax
	jge	.Llightmap_normalize_store
	movl	$64,%eax
.Llightmap_normalize_store:
	movl	%eax,(%edi)
	addl	$4,%edi
	decl	%esi
	jnz	.Llightmap_normalize_loop

.Llightmap_normalize_done:
	popl	%esi
	popl	%edi
	ret

	.align 4

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

	.align 4

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
	btl	%ebx,%ecx
	jnc	.Lbsp_clip_next
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
	btrl	%ebx,%ecx			// node is entirely on screen
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
