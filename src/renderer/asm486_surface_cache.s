/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_surface_cache.s
// Surface gradients, texture animation, and surface-cache routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

#ifdef ASM486_SURFACE_GRADIENTS
	.extern C(D_CalcGradientsProfileBegin_asm486)
	.extern C(D_CalcGradientsProfileEnd_asm486)
	.extern C(D_CalcGradientsProfileAxisHit_asm486)
	.extern C(D_CalcGradientsProfileAxisMiss_asm486)
	.extern C(TransformVector)
	.extern C(d_gradient_miplevel)
	.extern C(d_mipscale_values)
	.extern C(d_mip_xscale)
	.extern C(d_mip_yscale)
	.extern C(d_mip_t16)
	.extern C(d_texaxis_cache_asm)
	.extern C(d_texaxis_cache_mask)
	.extern C(transformed_modelorg)
	.extern C(currententity)
	.extern C(r_framecount)
	.extern C(d_sdivzstepu)
	.extern C(d_sdivzstepv)
	.extern C(d_tdivzstepu)
	.extern C(d_tdivzstepv)
	.extern C(d_sdivzorigin)
	.extern C(d_tdivzorigin)
	.extern C(sadjust)
	.extern C(tadjust)
	.extern C(bbextents)
	.extern C(bbextentt)
	.extern C(xcenter)
	.extern C(ycenter)
	.section .rodata
	.p2align 2
.Ldgradient_fixed16:
	.float 65536.0
.Ldgradient_half:
	.float 0.5
	.text
#endif

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
	.align 1

Ltexture_animation_broken:
	.ascii	"R_TextureAnimation: broken cycle\0"
Ltexture_animation_infinite:
	.ascii	"R_TextureAnimation: infinite cycle\0"
#ifdef ASM486_TEXTURE_ANIMATION
	.p2align 3
Ltexture_animation_ten:
	.double	10.0
#endif

	.text
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

#ifdef ASM486_SURFACE_GRADIENTS
	.p2align 4,,15

// void D_CalcGradients_asm486(msurface_t *pface)
// Calculate the perspective texture gradients and maintain an independent
// 256-entry view-axis cache.  The x87 operation order follows D_CalcGradients.
C(D_CalcGradients_asm486):
	.globl C(D_CalcGradients_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp
	movl	8(%ebp),%esi		// pface
#ifdef PROFILE486
	pushl	%esi
	call	C(D_CalcGradientsProfileBegin_asm486)
	addl	$4,%esp
#endif

	movl	52(%esi),%edi		// pface->texinfo
	movl	C(currententity),%edx
	movl	%edi,%eax
	shrl	$4,%eax
	movl	%edx,%ecx
	shrl	$4,%ecx
	xorl	%ecx,%eax
	andl	C(d_texaxis_cache_mask),%eax
	leal	(%eax,%eax,8),%eax
	shll	$2,%eax			// 36-byte cache entries
	leal	C(d_texaxis_cache_asm)(%eax),%ebx
	movl	C(r_framecount),%ecx
	cmpl	%edi,(%ebx)
	jne	.Lgradient_cache_miss
	cmpl	%edx,4(%ebx)
	jne	.Lgradient_cache_miss
	cmpl	%ecx,8(%ebx)
	jne	.Lgradient_cache_miss
#ifdef PROFILE486
	call	C(D_CalcGradientsProfileAxisHit_asm486)
#endif
	jmp	.Lgradient_cache_ready

.Lgradient_cache_miss:
	leal	12(%ebx),%eax		// entry->saxis
	pushl	%eax
	pushl	%edi			// texinfo->vecs[0]
	call	C(TransformVector)
	addl	$8,%esp
	leal	24(%ebx),%eax		// entry->taxis
	leal	16(%edi),%edx		// texinfo->vecs[1]
	pushl	%eax
	pushl	%edx
	call	C(TransformVector)
	addl	$8,%esp
	movl	%edi,(%ebx)
	movl	C(currententity),%eax
	movl	%eax,4(%ebx)
	movl	C(r_framecount),%eax
	movl	%eax,8(%ebx)
#ifdef PROFILE486
	call	C(D_CalcGradientsProfileAxisMiss_asm486)
#endif

.Lgradient_cache_ready:
	movl	C(d_gradient_miplevel),%ecx

	// u/v derivatives.  The negative v term matches the source's unary minus
	// before multiplication and each destination is rounded to float here.
	flds	12(%ebx)
	fmuls	C(d_mip_xscale)(,%ecx,4)
	fstps	C(d_sdivzstepu)
	flds	24(%ebx)
	fmuls	C(d_mip_xscale)(,%ecx,4)
	fstps	C(d_tdivzstepu)
	flds	16(%ebx)
	fchs
	fmuls	C(d_mip_yscale)(,%ecx,4)
	fstps	C(d_sdivzstepv)
	flds	28(%ebx)
	fchs
	fmuls	C(d_mip_yscale)(,%ecx,4)
	fstps	C(d_tdivzstepv)

	// axis[2]*mipscale - xcenter*stepu - ycenter*stepv
	flds	20(%ebx)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	flds	C(xcenter)
	fmuls	C(d_sdivzstepu)
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmuls	C(d_sdivzstepv)
	fsubrp	%st(0),%st(1)
	fstps	C(d_sdivzorigin)
	flds	32(%ebx)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	flds	C(xcenter)
	fmuls	C(d_tdivzstepu)
	fsubrp	%st(0),%st(1)
	flds	C(ycenter)
	fmuls	C(d_tdivzstepv)
	fsubrp	%st(0),%st(1)
	fstps	C(d_tdivzorigin)

	// VectorScale stores the three scaled model-origin components as floats;
	// retain those stores before the two dot products to match the C reference.
	flds	C(transformed_modelorg)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	-24(%ebp)
	flds	C(transformed_modelorg)+4
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	-20(%ebp)
	flds	C(transformed_modelorg)+8
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	-16(%ebp)

	// sadjust's first fixed-point conversion is part of the source expression.
	flds	-24(%ebp)
	fmuls	12(%ebx)
	flds	-20(%ebp)
	fmuls	16(%ebx)
	faddp	%st(0),%st(1)
	flds	-16(%ebp)
	fmuls	20(%ebx)
	faddp	%st(0),%st(1)
	fmuls	.Ldgradient_fixed16
	fadds	.Ldgradient_half
	fnstcw	-42(%ebp)
	movw	-42(%ebp),%ax
	orb	$12,%ah			// C float-to-int casts truncate toward zero
	movw	%ax,-44(%ebp)
	fldcw	-44(%ebp)
	fistpl	-28(%ebp)
	fldcw	-42(%ebp)
	movswl	44(%esi),%eax		// texturemins[0] << 16 >> mip
	shll	$16,%eax
	sarl	%cl,%eax
	subl	%eax,-28(%ebp)
	flds	12(%edi)
	fmuls	C(d_mip_t16)(,%ecx,4)
	fiaddl	-28(%ebp)
	fldcw	-44(%ebp)
	fistpl	C(sadjust)
	fldcw	-42(%ebp)

	flds	-24(%ebp)
	fmuls	24(%ebx)
	flds	-20(%ebp)
	fmuls	28(%ebx)
	faddp	%st(0),%st(1)
	flds	-16(%ebp)
	fmuls	32(%ebx)
	faddp	%st(0),%st(1)
	fmuls	.Ldgradient_fixed16
	fadds	.Ldgradient_half
	fnstcw	-42(%ebp)
	movw	-42(%ebp),%ax
	orb	$12,%ah
	movw	%ax,-44(%ebp)
	fldcw	-44(%ebp)
	fistpl	-28(%ebp)
	fldcw	-42(%ebp)
	movswl	46(%esi),%eax		// texturemins[1] << 16 >> mip
	shll	$16,%eax
	sarl	%cl,%eax
	subl	%eax,-28(%ebp)
	flds	28(%edi)
	fmuls	C(d_mip_t16)(,%ecx,4)
	fiaddl	-28(%ebp)
	fldcw	-44(%ebp)
	fistpl	C(tadjust)
	fldcw	-42(%ebp)

	movswl	48(%esi),%eax		// extents[0] << 16 >> mip, minus epsilon
	shll	$16,%eax
	sarl	%cl,%eax
	subl	$1,%eax
	movl	%eax,C(bbextents)
	movswl	50(%esi),%eax		// extents[1] << 16 >> mip, minus epsilon
	shll	$16,%eax
	sarl	%cl,%eax
	subl	$1,%eax
	movl	%eax,C(bbextentt)

#ifdef PROFILE486
	call	C(D_CalcGradientsProfileEnd_asm486)
#endif
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

	.p2align 4,,15

// void *D_CacheSurfaceHit_asm486(void *cache, int surface_dlightframe,
//     int frame, void *texture, int *lightadj, msurface_t *surface)
// Match the C cache hit predicate, including the unused-style sentinel and
// the discrete dynamic-light probe for phantom dlight marks.
C(D_CacheSurfaceHit_asm486):
	.globl C(D_CacheSurfaceHit_asm486)
	movl	4(%esp),%eax		// cache
	testl	%eax,%eax
	jz	.Lsurface_cache_miss
	cmpl	$0,24(%eax)		// cache->dlight
	jne	.Lsurface_cache_miss
	movl	16(%esp),%edx		// r_drawsurf.texture
	cmpl	SURFCACHE_TEXTURE_OFFSET(%eax),%edx	// cache->texture
	jne	.Lsurface_cache_miss
	movl	20(%esp),%edx		// r_drawsurf.lightadj
	movl	(%edx),%ecx
	cmpl	8(%eax),%ecx
	jne	.Lsurface_cache_miss
	movl	24(%esp),%ecx		// surface
	cmpb	$255,57(%ecx)		// styles[1] unused
	je	.Lsurface_cache_check_dlight
	movl	4(%edx),%ecx
	cmpl	12(%eax),%ecx
	jne	.Lsurface_cache_miss
	movl	8(%edx),%ecx
	cmpl	16(%eax),%ecx
	jne	.Lsurface_cache_miss
	movl	12(%edx),%ecx
	cmpl	20(%eax),%ecx
	jne	.Lsurface_cache_miss

.Lsurface_cache_check_dlight:
	movl	8(%esp),%edx		// surface->dlightframe
	cmpl	12(%esp),%edx		// current frame
	jne	.Lsurface_cache_hit
	pushl	%eax			// preserve cache across R_DlightContributes
	pushl	28(%esp)			// surface
	call	C(R_DlightContributes)
	addl	$4,%esp
	testl	%eax,%eax
	popl	%eax
	jne	.Lsurface_cache_miss
.Lsurface_cache_hit:
	ret

.Lsurface_cache_miss:
	xorl	%eax,%eax
	ret

	.p2align 4,,15

#ifdef ASM486_SURFACE_CACHE_CHECK
// int D_SurfaceCacheForRes(int width, int height)
// Own resolution scaling and the default 320x200 cache baseline. Keep command
// line token lookup and atoi in their shared C helpers.
C(D_SurfaceCacheForRes):
	.globl C(D_SurfaceCacheForRes)
	pushl	%ebp
	movl	%esp,%ebp
	subl	$4,%esp
	pushl	$.Ldsc_surface_cache_size_argument
	call	C(COM_CheckParm)
	addl	$4,%esp
	testl	%eax,%eax
	jne	.Ldsc_surface_cache_override
	movl	8(%ebp),%eax		// width
	imull	12(%ebp),%eax		// width * height, low 32 bits
	cmpl	$64000,%eax
	jg	.Ldsc_surface_cache_scale
	movl	$2457600,%eax		// SURFCACHE_SIZE_AT_320X200
	jmp	.Ldsc_surface_cache_done
.Ldsc_surface_cache_scale:
	subl	$64000,%eax
	leal	(%eax,%eax,2),%eax	// (pixels - 64000) * 3
	addl	$2457600,%eax		// SURFCACHE_SIZE_AT_320X200
	jmp	.Ldsc_surface_cache_done
.Ldsc_surface_cache_override:
	movl	%eax,-4(%ebp)		// argument index
	movl	C(com_argv),%edx
	movl	-4(%ebp),%eax
	movl	4(%edx,%eax,4),%eax	// com_argv[index + 1]
	pushl	%eax
	call	C(Q_atoi)
	addl	$4,%esp
	shll	$10,%eax			// * 1024
.Ldsc_surface_cache_done:
	leave
	ret

	.section .rodata
.Ldsc_surface_cache_size_argument:
	.asciz	"-surfcachesize"
	.text

// void D_InitCaches(void *buffer, int size)
// Initialize the surface-cache sentinel and trailing guard bytes. Console
// formatting remains in Con_Printf; cache state and guard setup are owned here.
C(D_InitCaches):
	.globl C(D_InitCaches)
	cmpl	$0,C(msg_suppress_1)
	jne	.Ldinit_caches_state
	movl	8(%esp),%eax		// size
	cltd
	movl	$1024,%ecx
	idivl	%ecx
	pushl	%eax
	pushl	$.Ldinit_caches_message
	call	C(Con_Printf)
	addl	$8,%esp
.Ldinit_caches_state:
	movl	4(%esp),%eax		// buffer
	movl	8(%esp),%edx		// size
	subl	$4,%edx			// GUARDSIZE
	movl	%edx,C(sc_size)
	movl	%eax,C(sc_base)
	movl	%eax,C(sc_rover)
	movl	$0,0(%eax)			// sc_base->next
	movl	$0,4(%eax)			// sc_base->owner
	movl	%edx,28(%eax)		// sc_base->size
	leal	(%eax,%edx),%ecx		// cache guard starts at buffer + sc_size
	movb	$0,0(%ecx)
	movb	$1,1(%ecx)
	movb	$2,2(%ecx)
	movb	$3,3(%ecx)
	ret

	.section .rodata
.Ldinit_caches_message:
	.asciz	"%ik surface cache\n"
	.text

#if !defined(ASM486_DRAWING_DRIVER)
// In the complete drawing-driver profile, d_driverasm.s owns this entry.
C(D_FlushCaches):
	.globl C(D_FlushCaches)
	pushl	%esi
	pushl	%edi
	movl	C(sc_base),%esi
	testl	%esi,%esi
	je	.Ldflush_caches_return
.Ldflush_caches_owner:
	movl	4(%esi),%edi		// owner
	testl	%edi,%edi
	je	.Ldflush_caches_next
	movl	$0,(%edi)			// *owner = NULL
.Ldflush_caches_next:
	movl	0(%esi),%esi		// next
	testl	%esi,%esi
	jne	.Ldflush_caches_owner
	movl	C(sc_base),%eax
	movl	%eax,C(sc_rover)
	movl	$0,0(%eax)			// sc_base->next
	movl	$0,4(%eax)			// sc_base->owner
	movl	C(sc_size),%edx
	movl	%edx,28(%eax)		// sc_base->size
.Ldflush_caches_return:
	popl	%edi
	popl	%esi
	ret
#endif

// surfcache_t *D_SCAlloc_asm486(int width, int payload_size)
// Walk/reclaim the rover chain, split a sufficiently large tail block, and
// update wrap/thrash state. The C allocator remains the benchmark reference.
C(D_SCAlloc):
	.globl C(D_SCAlloc)
C(D_SCAlloc_asm486):
	.globl C(D_SCAlloc_asm486)
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$16,%esp

	// Locals: 0=aligned block size, 4=width, 8=new block, 12=wrapped flag.
	movl	36(%esp),%ebx		// width
	testl	%ebx,%ebx
	js	.Ldsc_bad_width
	cmpl	$256,%ebx
	jg	.Ldsc_bad_width
	movl	%ebx,4(%esp)
	movl	40(%esp),%edx		// payload size
	testl	%edx,%edx
	jle	.Ldsc_bad_size
	cmpl	$0x10000,%edx
	jg	.Ldsc_bad_size

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_profile_request_done
	incl	C(bench486_surface_cache_allocations)
	movl	40(%esp),%eax
	addl	%eax,C(bench486_surface_cache_requested_bytes)
.Ldsc_profile_request_done:
#endif

	addl	$SURFCACHE_DATA_OFFSET,%edx
	addl	$3,%edx
	andl	$-4,%edx
	movl	%edx,0(%esp)
	cmpl	C(sc_size),%edx
	jle	.Ldsc_size_fits
	pushl	%edx
	pushl	$.Ldsc_too_large
	call	C(Sys_Error)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

.Ldsc_size_fits:
	movl	$0,12(%esp)			// wrapped_this_time
	movl	C(sc_rover),%edi
	testl	%edi,%edi
	jz	.Ldsc_wrap
	movl	C(sc_size),%eax
	subl	0(%esp),%eax			// free bytes after sc_base
	movl	C(sc_base),%edx
	subl	%edx,%edi
	cmpl	%eax,%edi
	jle	.Ldsc_rover_ready

.Ldsc_wrap:
	cmpl	$0,C(sc_rover)
	je	.Ldsc_set_rover_base
	movl	$1,12(%esp)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_set_rover_base
	incl	C(bench486_surface_cache_wraps)
#endif
.Ldsc_set_rover_base:
	movl	C(sc_base),%edi
	movl	%edi,C(sc_rover)

.Ldsc_rover_ready:
	movl	C(sc_rover),%edi		// restore pointer after extent comparison
	movl	%edi,8(%esp)			// new = sc_rover
	movl	4(%edi),%eax			// owner
	testl	%eax,%eax
	jz	.Ldsc_collect
	movl	$0,(%eax)				// *owner = NULL
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_collect
	incl	C(bench486_surface_cache_invalidated_blocks)
	movl	28(%edi),%eax
	addl	%eax,C(bench486_surface_cache_reclaimed_bytes)
#endif

.Ldsc_collect:
	movl	8(%esp),%esi			// new
	movl	28(%esi),%eax
	cmpl	0(%esp),%eax
	jge	.Ldsc_collect_done

.Ldsc_collect_next:
	movl	0(%edi),%edi			// sc_rover = sc_rover->next
	testl	%edi,%edi
	jnz	.Ldsc_have_next
	pushl	$.Ldsc_end_of_memory
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

.Ldsc_have_next:
	movl	%edi,C(sc_rover)
	movl	4(%edi),%eax
	testl	%eax,%eax
	jz	.Ldsc_add_next
	movl	$0,(%eax)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_add_next
	incl	C(bench486_surface_cache_invalidated_blocks)
	movl	28(%edi),%eax
	addl	%eax,C(bench486_surface_cache_reclaimed_bytes)
#endif

.Ldsc_add_next:
	movl	28(%esi),%eax
	addl	28(%edi),%eax
	movl	%eax,28(%esi)
	movl	0(%edi),%eax
	movl	%eax,0(%esi)
	movl	28(%esi),%eax
	cmpl	0(%esp),%eax
	jl	.Ldsc_collect_next

.Ldsc_collect_done:
	movl	28(%esi),%eax
	subl	0(%esp),%eax
	cmpl	$256,%eax
	jle	.Ldsc_keep_block

	// A remainder above 256 bytes becomes the new rover fragment.
	movl	%esi,%edi
	addl	0(%esp),%edi
	movl	%edi,C(sc_rover)
	movl	%eax,28(%edi)
	movl	0(%esi),%edx
	movl	%edx,0(%edi)
	movl	$0,32(%edi)			// width
	movl	$0,4(%edi)			// owner
	movl	%edi,0(%esi)
	movl	0(%esp),%eax
	movl	%eax,28(%esi)
	jmp	.Ldsc_block_ready

.Ldsc_keep_block:
	movl	0(%esi),%edi
	movl	%edi,C(sc_rover)

.Ldsc_block_ready:
	movl	4(%esp),%eax
	movl	%eax,32(%esi)			// width
#ifdef DEBUG
	testl	%eax,%eax
	jz	.Ldsc_debug_height_done
	movl	0(%esp),%eax
	subl	$SURFCACHE_DATA_OFFSET,%eax
	xorl	%edx,%edx
	divl	4(%esp)
	movl	%eax,SURFCACHE_HEIGHT_OFFSET(%esi)
.Ldsc_debug_height_done:
#endif
	movl	$0,4(%esi)			// owner = NULL

	cmpl	$0,C(d_roverwrapped)
	je	.Ldsc_not_yet_wrapped
	movl	12(%esp),%eax
	testl	%eax,%eax
	jnz	.Ldsc_mark_thrash
	movl	C(sc_rover),%eax
	cmpl	C(d_initial_rover),%eax
	jb	.Ldsc_finish
	jmp	.Ldsc_mark_thrash

.Ldsc_not_yet_wrapped:
	cmpl	$0,12(%esp)
	je	.Ldsc_finish
	movl	$1,C(d_roverwrapped)
	jmp	.Ldsc_finish

.Ldsc_mark_thrash:
	cmpl	$0,C(r_cache_thrash)
	jne	.Ldsc_finish
	movl	$1,C(r_cache_thrash)
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Ldsc_finish
	incl	C(bench486_surface_cache_thrash_frames)
#endif

.Ldsc_finish:
#ifdef DEBUG
	call	C(D_CheckCacheGuard)
#endif
	movl	%esi,%eax

.Ldsc_return:
	addl	$16,%esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

.Ldsc_bad_width:
	pushl	%ebx
	pushl	$.Ldsc_bad_width_message
	call	C(Sys_Error)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

.Ldsc_bad_size:
	pushl	40(%esp)
	pushl	$.Ldsc_bad_size_message
	call	C(Sys_Error)
	addl	$8,%esp
	xorl	%eax,%eax
	jmp	.Ldsc_return

	.section .rodata
.Ldsc_bad_width_message:
	.asciz "D_SCAlloc: bad cache width %d\n"
.Ldsc_bad_size_message:
	.asciz "D_SCAlloc: bad cache size %d\n"
.Ldsc_too_large:
	.asciz "D_SCAlloc: %i > cache size"
.Ldsc_end_of_memory:
	.asciz "D_SCAlloc: hit the end of memory"
	.text

// void D_CacheSurfaceSetup_asm486(msurface_t *surface, int miplevel,
//                                  drawsurf_t *drawsurf)
// Set the four miss-path fields consumed by R_DrawSurface. Structure offsets
// are checked against C at compile time in d_surf.c.
C(D_CacheSurfaceSetup_asm486):
	.globl C(D_CacheSurfaceSetup_asm486)
	movl	4(%esp),%eax		// surface
	movl	8(%esp),%ecx		// miplevel
	movl	12(%esp),%edx		// drawsurf
	movl	%ecx,32(%edx)		// surfmip
	movswl	48(%eax),%eax		// extents[0]
	sarl	%cl,%eax
	movl	%eax,36(%edx)		// surfwidth
	movl	%eax,4(%edx)		// rowbytes
	movl	4(%esp),%eax		// reload surface
	movswl	50(%eax),%eax		// extents[1]
	sarl	%cl,%eax
	movl	%eax,40(%edx)		// surfheight
	ret

// void D_CacheSurfaceKeys_asm486(msurface_t *surface, texture_t *texture,
//                                drawsurf_t *drawsurf, int *lightstylevalues)
// Resolve the four surface styles and stage the animated texture/cache key.
C(D_CacheSurfaceKeys_asm486):
	.globl C(D_CacheSurfaceKeys_asm486)
	pushl	%esi
	pushl	%edi
	movl	12(%esp),%eax		// surface
	movl	16(%esp),%esi		// texture
	movl	20(%esp),%ecx		// drawsurf
	movl	24(%esp),%edx		// d_lightstylevalue
	movl	%esi,28(%ecx)		// texture
	movzbl	56(%eax),%esi		// styles[0]
	movl	(%edx,%esi,4),%edi
	movl	%edi,12(%ecx)		// lightadj[0]
	movzbl	57(%eax),%esi		// styles[1]
	movl	(%edx,%esi,4),%edi
	movl	%edi,16(%ecx)		// lightadj[1]
	movzbl	58(%eax),%esi		// styles[2]
	movl	(%edx,%esi,4),%edi
	movl	%edi,20(%ecx)		// lightadj[2]
	movzbl	59(%eax),%esi		// styles[3]
	movl	(%edx,%esi,4),%edi
	movl	%edi,24(%ecx)		// lightadj[3]
	popl	%edi
	popl	%esi
	ret

// surfcache_t *D_CacheSurfaceCheckAndPrepare_asm486(msurface_t *surface,
//     texture_t *texture, drawsurf_t *drawsurf, int *lightstylevalues,
//     surfcache_t *cache)
// Return a valid cache hit without writing the miss-only drawsurf cache keys.
// If the entry misses, prepare the same texture and four style tags consumed
// by the existing rebuild path.
C(D_CacheSurfaceCheckAndPrepare_asm486):
	.globl C(D_CacheSurfaceCheckAndPrepare_asm486)
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		// surface
	movl	20(%esp),%esi		// texture
	movl	28(%esp),%edx		// d_lightstylevalue
	movl	32(%esp),%eax		// cache
	testl	%eax,%eax
	jz		.Ldsc_check_prepare_miss
	cmpl	$0,24(%eax)		// cache->dlight
	jne		.Ldsc_check_prepare_miss
	cmpl	SURFCACHE_TEXTURE_OFFSET(%eax),%esi
	jne		.Ldsc_check_prepare_miss
	movzbl	56(%ebx),%ecx		// styles[0]
	movl	(%edx,%ecx,4),%edi
	cmpl	8(%eax),%edi		// lightadj[0]
	jne		.Ldsc_check_prepare_miss
	cmpb	$255,57(%ebx)		// styles[1] unused
	je		.Ldsc_check_prepare_dlight
	movzbl	57(%ebx),%ecx
	movl	(%edx,%ecx,4),%edi
	cmpl	12(%eax),%edi
	jne		.Ldsc_check_prepare_miss
	movzbl	58(%ebx),%ecx
	movl	(%edx,%ecx,4),%edi
	cmpl	16(%eax),%edi
	jne		.Ldsc_check_prepare_miss
	movzbl	59(%ebx),%ecx
	movl	(%edx,%ecx,4),%edi
	cmpl	20(%eax),%edi
	jne		.Ldsc_check_prepare_miss

.Ldsc_check_prepare_dlight:
	movl	4(%ebx),%ecx		// surface->dlightframe
	cmpl	C(r_framecount),%ecx
	jne		.Ldsc_check_prepare_return
	// Strict control schedule: preserve the cache pointer across the call on
	// the stack, matching the pre-experiment implementation.
	pushl	%eax
	pushl	%ebx				// surface
	call	C(R_DlightContributes)
	addl	$4,%esp
	testl	%eax,%eax
	popl	%eax
	jz		.Ldsc_check_prepare_return

.Ldsc_check_prepare_miss:
	// Prepare all keys for the cache rebuild path. Reload stack arguments so
	// this also works after R_DlightContributes clobbers caller-saved registers.
	movl	24(%esp),%ecx		// drawsurf
	movl	28(%esp),%edx		// d_lightstylevalue
	pushl	%edx
	pushl	%ecx
	pushl	%esi
	pushl	%ebx
	call	C(D_CacheSurfaceKeys_asm486)
	addl	$16,%esp
	xorl	%eax,%eax
.Ldsc_check_prepare_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

// void D_CacheSurfaceStoreTags_asm486(surfcache_t *cache,
//                                      drawsurf_t *drawsurf)
// Copy the texture and four light-style cache tags from the prepared draw.
C(D_CacheSurfaceStoreTags_asm486):
	.globl C(D_CacheSurfaceStoreTags_asm486)
	movl	4(%esp),%eax		// cache
	movl	8(%esp),%edx		// drawsurf
	movl	12(%edx),%ecx
	movl	%ecx,8(%eax)		// cache->lightadj[0]
	movl	16(%edx),%ecx
	movl	%ecx,12(%eax)		// cache->lightadj[1]
	movl	20(%edx),%ecx
	movl	%ecx,16(%eax)		// cache->lightadj[2]
	movl	24(%edx),%ecx
	movl	%ecx,20(%eax)		// cache->lightadj[3]
	movl	28(%edx),%ecx
	movl	%ecx,SURFCACHE_TEXTURE_OFFSET(%eax)	// cache->texture
	ret

// void D_CacheSurfaceAttach_asm486(msurface_t *surface, int mip,
//     surfcache_t *cache, drawsurf_t *drawsurf, int cache_created)
// Attach newly allocated blocks once; always point R_DrawSurface at cache data.
C(D_CacheSurfaceAttach_asm486):
	.globl C(D_CacheSurfaceAttach_asm486)
	movl	4(%esp),%eax		// surface
	movl	8(%esp),%ecx		// mip level
	leal	28(%eax,%ecx,4),%ecx	// &surface->cachespots[mip]
	movl	12(%esp),%edx		// cache
	cmpl	$0,20(%esp)
	je	.Ldsc_attach_data
	movl	%edx,(%ecx)			// surface->cachespots[mip] = cache
	movl	%ecx,4(%edx)			// cache->owner = slot
.Ldsc_attach_data:
	movl	16(%esp),%eax		// drawsurf
	leal	SURFCACHE_DATA_OFFSET(%edx),%edx
	movl	%edx,(%eax)			// drawsurf->surfdat = cache->data
	ret

// void D_CacheSurfaceDispatch_asm486(msurface_t *surface,
//                                     drawsurf_t *drawsurf)
// Complete the cache-miss draw handoff and call the existing surface drawer.
C(D_CacheSurfaceDispatch_asm486):
	.globl C(D_CacheSurfaceDispatch_asm486)
	movl	4(%esp),%eax		// surface
	movl	8(%esp),%edx		// drawsurf
	movl	%eax,8(%edx)			// drawsurf->surf
	incl	C(c_surf)
	call	C(R_DrawSurface)
	ret

// void D_CacheSurfaceSetDlight_asm486(surfcache_t *cache, int surf_frame,
//                                      int frame, int contributed)
C(D_CacheSurfaceSetDlight_asm486):
	.globl C(D_CacheSurfaceSetDlight_asm486)
	movl	4(%esp),%eax		// cache
	movl	8(%esp),%edx		// surface dlight frame
	cmpl	12(%esp),%edx		// current frame
	jne	.Ldsc_clear_dlight
	movl	16(%esp),%edx		// contributed sample flag
	movl	%edx,24(%eax)			// cache->dlight
	ret
.Ldsc_clear_dlight:
	movl	$0,24(%eax)
	ret

	.p2align 4,,15

// surfcache_t *D_CacheSurface(msurface_t *surface, int miplevel)
// Own texture-animation selection, cache-key preparation and hit/miss flow;
// the focused helpers below this boundary keep their independent C or ASM
// selectors and the C dispatcher remains available in benchmark builds.
C(D_CacheSurface):
	.globl C(D_CacheSurface)
#ifndef PROFILE486
	// The common static-texture cache hit needs only caller-saved registers.
	// Probe it before building the full C-call frame; any animated texture,
	// cache miss, key mismatch, or current-frame dynamic-light case falls back
	// to the complete path below.
	movl	4(%esp),%eax		// surface
	movl	cs_surface_texinfo(%eax),%edx
	movl	cs_texinfo_texture(%edx),%ecx
	cmpl	$0,cs_texture_anim_total(%ecx)
	jne	.Lcache_surface_full_entry
	movl	C(currententity),%edx
	cmpl	$0,cs_entity_frame(%edx)
	je	.Lcache_surface_fast_static
	cmpl	$0,cs_texture_alternate_anims(%ecx)
	jne	.Lcache_surface_full_entry
.Lcache_surface_fast_static:
	movl	8(%esp),%edx		// miplevel
	movl	cs_surface_cachespots(%eax,%edx,4),%edx
	testl	%edx,%edx
	jz	.Lcache_surface_full_entry
	cmpl	$0,24(%edx)		// cache->dlight
	jne	.Lcache_surface_full_entry
	cmpl	SURFCACHE_TEXTURE_OFFSET(%edx),%ecx
	jne	.Lcache_surface_full_entry
	movl	4(%esp),%ecx		// retain surface for style and dlight keys
	movzbl	56(%ecx),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%eax
	cmpl	8(%edx),%eax
	jne	.Lcache_surface_full_entry
	cmpb	$255,57(%ecx)		// unused style sentinel
	je	.Lcache_surface_fast_dlight
	movzbl	57(%ecx),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%eax
	cmpl	12(%edx),%eax
	jne	.Lcache_surface_full_entry
	cmpb	$255,58(%ecx)
	je	.Lcache_surface_fast_dlight
	movzbl	58(%ecx),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%eax
	cmpl	16(%edx),%eax
	jne	.Lcache_surface_full_entry
	movzbl	59(%ecx),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%eax
	cmpl	20(%edx),%eax
	jne	.Lcache_surface_full_entry
.Lcache_surface_fast_dlight:
	movl	cs_surface_dlightframe(%ecx),%eax
	cmpl	C(r_framecount),%eax
	je	.Lcache_surface_full_entry
	movl	%edx,%eax
	ret
.Lcache_surface_full_entry:
#endif
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$52,%esp
	movl	8(%ebp),%esi		// surface
	movl	12(%ebp),%ebx		// miplevel
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call C(D_CacheSurfaceProfileBegin_asm486)
	addl	$4,%esp
#endif
	// Match R_TextureAnimation's call guard: static textures avoid the call;
	// alternate animations are consulted only for nonzero entity frames.
	movl	cs_surface_texinfo(%esi),%edx
	movl	cs_texinfo_texture(%edx),%edi
	cmpl	$0,cs_texture_anim_total(%edi)
	jne	.Lcache_surface_animate
	movl	C(currententity),%eax
	cmpl	$0,cs_entity_frame(%eax)
	je	.Lcache_surface_static_texture
	cmpl	$0,cs_texture_alternate_anims(%edi)
	je	.Lcache_surface_static_texture
.Lcache_surface_animate:
	pushl	%edi
	call	C(R_TextureAnimation)
	addl	$4,%esp
	movl	%eax,%edi
.Lcache_surface_static_texture:
	movl	cs_surface_cachespots(%esi,%ebx,4),%eax
	movl	%eax,%ebx			// keep cache in saved register through hit test

	// Compare cache keys before preparing drawsurf fields. The hit path returns
	// only the cache; rebuild paths fill all five drawsurf fields below.
	testl	%ebx,%ebx
	jz	.Lcache_surface_keys_only
	cmpl	$0,24(%ebx)		// cache->dlight
	jne	.Lcache_surface_keys_only
	cmpl	SURFCACHE_TEXTURE_OFFSET(%ebx),%edi
	jne	.Lcache_surface_keys_only
	movzbl	56(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	cmpl	8(%ebx),%ecx
	jne	.Lcache_surface_keys_only
	cmpb	$255,57(%esi)		// styles[1], also the unused sentinel
	je	.Lcache_surface_dlight_check
	// Do not fetch the lightstyle table for the unused-style sentinel.
	movzbl	57(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	cmpl	12(%ebx),%ecx
	jne	.Lcache_surface_keys_only
	cmpb	$255,58(%esi)
	je	.Lcache_surface_dlight_check
	// styles[2] terminates the active style list; later keys are unused.
	movzbl	58(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	cmpl	16(%ebx),%ecx
	jne	.Lcache_surface_keys_only
	movzbl	59(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	cmpl	20(%ebx),%ecx
	jne	.Lcache_surface_keys_only
	jmp	.Lcache_surface_dlight_check

.Lcache_surface_keys_only:
	// Misses need both the original cache pointer and mip level; the hit path
	// keeps the cache pointer in saved EBX and avoids a stack spill/reload.
	movl	%ebx,-16(%ebp)
	movl	12(%ebp),%ebx		// restore miplevel for the rebuild path
	movl	%edi,C(r_drawsurf)+28	// texture
	movzbl	56(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	movl	%ecx,C(r_drawsurf)+12
	movzbl	57(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	movl	%ecx,C(r_drawsurf)+16
	movzbl	58(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	movl	%ecx,C(r_drawsurf)+20
	movzbl	59(%esi),%eax
	movl	C(d_lightstylevalue)(,%eax,4),%ecx
	movl	%ecx,C(r_drawsurf)+24
	jmp	.Lcache_surface_miss

.Lcache_surface_dlight_check:
	movl	cs_surface_dlightframe(%esi),%edx
	cmpl	C(r_framecount),%edx
	jne	.Lcache_surface_hit
	#ifdef PROFILE486
	incl	C(bench486_surface_cache_dlight_probes)
	#endif
	pushl	%esi
	call	C(R_DlightContributes)
	addl	$4,%esp
	#ifdef PROFILE486
	testl	%eax,%eax
	je	.Lcache_surface_hit
	incl	C(bench486_surface_cache_dlight_contributing_probes)
	jmp	.Lcache_surface_keys_only
	#else
	testl	%eax,%eax
	jne	.Lcache_surface_keys_only
	#endif
.Lcache_surface_hit:
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileHit_asm486)
	addl	$4,%esp
#endif
	movl	%ebx,%eax
	addl	$52,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.Lcache_surface_miss:
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%esi
	pushl	%eax
	call	C(D_CacheSurfaceProfileMiss_asm486)
	addl	$8,%esp
#endif
	movl	$0,-24(%ebp)		// cache_created
	pushl	$C(r_drawsurf)
	pushl	%ebx
	pushl	%esi
	call	C(D_CacheSurfaceSetup_asm486)
	addl	$12,%esp
	cmpl	$0,-16(%ebp)
	jne	.Lcache_surface_have_cache
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileAllocBegin_asm486)
	addl	$4,%esp
#endif
	movl	C(r_drawsurf)+36,%eax	// surfwidth
	movl	C(r_drawsurf)+40,%ecx	// surfheight
	mull	%ecx			// i486 one-operand multiply
	pushl	%eax			// width * height
	pushl	C(r_drawsurf)+36	// width
	call	C(D_SCAlloc)
	addl	$8,%esp
	movl	%eax,-16(%ebp)
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileAllocEnd_asm486)
	addl	$4,%esp
#endif
	movl	$1,-24(%ebp)
.Lcache_surface_have_cache:
	pushl	-24(%ebp)
	pushl	$C(r_drawsurf)
	pushl	-16(%ebp)
	pushl	%ebx
	pushl	%esi
	call	C(D_CacheSurfaceAttach_asm486)
	addl	$20,%esp
	pushl	$C(r_drawsurf)
	pushl	-16(%ebp)
	call	C(D_CacheSurfaceStoreTags_asm486)
	addl	$8,%esp
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileDrawBegin_asm486)
	addl	$4,%esp
#endif
	pushl	$C(r_drawsurf)
	pushl	%esi
	call	C(D_CacheSurfaceDispatch_asm486)
	addl	$8,%esp
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileDrawEnd_asm486)
	addl	$4,%esp
#endif
	pushl	C(r_dlight_contributed)
	pushl	C(r_framecount)
	movl	cs_surface_dlightframe(%esi),%eax
	pushl	%eax
	pushl	-16(%ebp)
	call	C(D_CacheSurfaceSetDlight_asm486)
	addl	$16,%esp
#ifdef PROFILE486
	leal	-64(%ebp),%eax
	pushl	%eax
	call	C(D_CacheSurfaceProfileFinish_asm486)
	addl	$4,%esp
#endif
	movl	cs_surface_cachespots(%esi,%ebx,4),%eax

.Lcache_surface_return:
	addl	$52,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

	.p2align 4,,15

// int D_MipLevelForScale_asm486(float scale)
// Use the 486 x87 compare flags for the three descending mip thresholds.
// fcomps pops the temporary scale, leaving no value on the FP stack.
#ifdef ASM486_MIP_LEVEL
C(D_MipLevelForScale):
	.globl C(D_MipLevelForScale)
#endif
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


#ifdef ASM486_SURFACE_ZGRADIENTS
	.p2align 4,,15

// void R_SetSurfaceZGradients_asm486(mplane_t *plane)
// Reuse the previous plane/entity/frame result, otherwise transform the plane
// normal and build the three 1/z gradients with the original x87 operation order.
#ifdef ASM486_SURFACE_ZGRADIENTS
.globl C(R_SetSurfaceZGradients)
C(R_SetSurfaceZGradients):
#endif
.globl C(R_SetSurfaceZGradients_asm486)
C(R_SetSurfaceZGradients_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$20,%esp
	movl	8(%ebp),%eax
	movl	%eax,-4(%ebp)		// plane

	movl	C(r_zgradient_asm_cache_frame),%eax
	cmpl	C(r_framecount),%eax
	jne	.Lzgradient_miss
	movl	C(r_zgradient_asm_cache_plane),%eax
	cmpl	-4(%ebp),%eax
	jne	.Lzgradient_miss
	movl	C(r_zgradient_asm_cache_entity),%eax
	cmpl	C(currententity),%eax
	jne	.Lzgradient_miss
	movl	C(surface_p),%edx
	movl	C(r_zgradient_asm_cache_zistepu),%eax
	movl	%eax,st_d_zistepu(%edx)
	movl	C(r_zgradient_asm_cache_zistepv),%eax
	movl	%eax,st_d_zistepv(%edx)
	movl	C(r_zgradient_asm_cache_ziorigin),%eax
	movl	%eax,st_d_ziorigin(%edx)
	leave
	ret

.Lzgradient_miss:
	leal	-20(%ebp),%eax		// p_normal output
	pushl	%eax
	pushl	-4(%ebp)			// plane->normal begins at offset zero
	call	C(TransformVector)
	addl	$8,%esp

	// Match the compiler's C expression order: dist - (term0 + term1),
	// then subtract term2 before taking the reciprocal.
	movl	-4(%ebp),%eax
	flds	C(modelorg)
	fmuls	pl_normal(%eax)
	flds	C(modelorg)+4
	fmuls	pl_normal+4(%eax)
	faddp	%st,%st(1)
	fsubrs	pl_dist(%eax)
	flds	C(modelorg)+8
	fmuls	pl_normal+8(%eax)
	fsubrp	%st,%st(1)
	fld1
	fdivp	%st,%st(1)		// 1 / (dist - dot)

	flds	-20(%ebp)			// p_normal[0]
	fmuls	C(xscaleinv)
	fmul	%st(1),%st
	fsts	C(r_zgradient_asm_cache_zistepu)

	flds	-16(%ebp)			// p_normal[1]
	fmuls	C(yscaleinv)
	fmul	%st(2),%st
	fchs
	fsts	C(r_zgradient_asm_cache_zistepv)

	fxch	%st(2)			// reciprocal | zistepu | zistepv
	fmuls	-12(%ebp)			// p_normal[2] * distinv
	flds	C(xcenter)
	fmul	%st(2),%st
	fsubrp	%st,%st(1)		// subtract xcenter * extended zistepu
	flds	C(ycenter)
	fmul	%st(3),%st
	fsubrp	%st,%st(1)		// subtract ycenter * extended zistepv
	fsts	C(r_zgradient_asm_cache_ziorigin)

	movl	-4(%ebp),%eax
	movl	%eax,C(r_zgradient_asm_cache_plane)
	movl	C(currententity),%eax
	movl	%eax,C(r_zgradient_asm_cache_entity)
	movl	C(r_framecount),%eax
	movl	%eax,C(r_zgradient_asm_cache_frame)

	movl	C(surface_p),%edx
	fxch	%st(1)
	fstps	st_d_zistepu(%edx)
	fxch	%st(1)
	fstps	st_d_zistepv(%edx)
	fstps	st_d_ziorigin(%edx)
	leave
	ret
#endif

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
	cmpl	%edx,cs_texture_anim_min(%eax)	// base->anim_min > relative
	jg	.Ltexture_animation_next
	cmpl	%edx,cs_texture_anim_max(%eax)	// base->anim_max <= relative
	jle	.Ltexture_animation_next
	ret

.Ltexture_animation_next:
	movl	cs_texture_anim_next(%eax),%eax	// base->anim_next
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

#ifdef ASM486_TEXTURE_ANIMATION
	.p2align 4,,15

// texture_t *R_TextureAnimation_asm486(texture_t *base)
// Match the C wrapper, including alternate-anims selection, the static-texture
// fast path, truncation of cl.time*10 toward zero, signed remainder, and the
// assembly frame resolver. The x87 control word is restored around FISTP.
C(R_TextureAnimation_asm486):
	.globl C(R_TextureAnimation_asm486)
	pushl	%ebx
	subl	$8,%esp
	movl	16(%esp),%ebx		// base
	movl	C(currententity),%eax
	cmpl	$0,cs_entity_frame(%eax)
	je	.Ltexture_animation_entry_primary
	movl	cs_texture_alternate_anims(%ebx),%eax
	testl	%eax,%eax
	jz	.Ltexture_animation_entry_primary
	movl	%eax,%ebx

.Ltexture_animation_entry_primary:
	movl	cs_texture_anim_total(%ebx),%ecx
	testl	%ecx,%ecx
	jz	.Ltexture_animation_entry_return_base

	fnstcw	0(%esp)
	movw	0(%esp),%dx
	orw	$0x0c00,%dx
	movw	%dx,2(%esp)
	fldl	C(cl)+cs_cl_time
	fmull	Ltexture_animation_ten
	fldcw	2(%esp)
	fistpl	4(%esp)
	fldcw	0(%esp)
	movl	4(%esp),%eax
	cdq
	idivl	%ecx			// C signed remainder, truncated toward zero
	movl	%edx,%ecx			// relative phase
	movl	%ebx,%eax			// current texture
	xorl	%edx,%edx			// links followed

.Ltexture_animation_entry_check:
	cmpl	%ecx,cs_texture_anim_min(%eax)
	jg	.Ltexture_animation_entry_next
	cmpl	%ecx,cs_texture_anim_max(%eax)
	jle	.Ltexture_animation_entry_next
	jmp	.Ltexture_animation_entry_return

.Ltexture_animation_entry_next:
	movl	cs_texture_anim_next(%eax),%eax
	testl	%eax,%eax
	jz	.Ltexture_animation_entry_broken
	incl	%edx
	cmpl	$100,%edx
	jg	.Ltexture_animation_entry_infinite
	jmp	.Ltexture_animation_entry_check

.Ltexture_animation_entry_broken:
	pushl	$Ltexture_animation_broken
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	jmp	.Ltexture_animation_entry_return

.Ltexture_animation_entry_infinite:
	pushl	$Ltexture_animation_infinite
	call	C(Sys_Error)
	addl	$4,%esp
	xorl	%eax,%eax
	jmp	.Ltexture_animation_entry_return

.Ltexture_animation_entry_return_base:
	movl	%ebx,%eax
.Ltexture_animation_entry_return:
	addl	$8,%esp
	popl	%ebx
	ret
#endif

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

// void D_FillRect(vrect_t *rect, int color)
//
// The rectangle coordinates and clipping arithmetic are kept in 32-bit
// registers, matching D_FillRect_C. Large rows use an aligned REP STOSL body
// with byte prologue/tail. The small aligned dword case intentionally retains
// the original two 32-bit add operations used to replicate color; for palette
// colors 0..255 this is a repeated byte, and for other inputs it preserves the
// C routine's historical result exactly.
