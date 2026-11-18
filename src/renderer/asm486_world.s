/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_world.s
// World, brush-model, and clipped-submodel rendering routines.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

#ifdef ASM486_SURFACE_DISPATCH
	.section .rodata
	.p2align 2
.Lds_background_z:
	.float -0.9
	.text
#endif

#ifdef ASM486_SURFACE_DISPATCH
// Restore the base world view after a brush model changed the view axes.
// void D_RestoreWorldDrawingState_asm486(entity_t **rotated, float *world)
C(D_RestoreWorldDrawingState_asm486):
	.globl C(D_RestoreWorldDrawingState_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%eax
	cmpl	$0,(%eax)
	je	.Lds_restore_done
	movl	12(%ebp),%esi
	// cl_entities is an array symbol, not a pointer.
	leal	C(cl_entities),%eax
	movl	%eax,C(currententity)
	leal	C(transformed_modelorg),%edi
	movl	(%esi),%eax
	movl	%eax,(%edi)
	movl	4(%esi),%eax
	movl	%eax,4(%edi)
	movl	8(%esi),%eax
	movl	%eax,8(%edi)
	movl	C(base_vpn),%eax
	movl	%eax,C(vpn)
	movl	C(base_vpn)+4,%eax
	movl	%eax,C(vpn)+4
	movl	C(base_vpn)+8,%eax
	movl	%eax,C(vpn)+8
	movl	C(base_vup),%eax
	movl	%eax,C(vup)
	movl	C(base_vup)+4,%eax
	movl	%eax,C(vup)+4
	movl	C(base_vup)+8,%eax
	movl	%eax,C(vup)+8
	movl	C(base_vright),%eax
	movl	%eax,C(vright)
	movl	C(base_vright)+4,%eax
	movl	%eax,C(vright)+4
	movl	C(base_vright)+8,%eax
	movl	%eax,C(vright)+8
	movl	C(base_modelorg),%eax
	movl	%eax,C(modelorg)
	movl	C(base_modelorg)+4,%eax
	movl	%eax,C(modelorg)+4
	movl	C(base_modelorg)+8,%eax
	movl	%eax,C(modelorg)+8
	call	C(R_TransformFrustum)
	movl	8(%ebp),%eax
	movl	$0,(%eax)
.Lds_restore_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

// void D_SetBmodelDrawingState_asm486(entity_t **rotated, surf_t *s,
//         float *local, float *world)
C(D_SetBmodelDrawingState_asm486):
	.globl C(D_SetBmodelDrawingState_asm486)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%edx
	movl	12(%ebp),%esi
	movl	DS_ENTITY(%esi),%ebx
	cmpl	%ebx,(%edx)
	je	.Lds_set_done
	pushl	20(%ebp)
	pushl	%edx
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	movl	%ebx,C(currententity)
	movl	16(%ebp),%edi
	flds	C(r_origin)
	fsubs	DS_ENTITY_ORIGIN(%ebx)
	fstps	(%edi)
	flds	C(r_origin)+4
	fsubs	DS_ENTITY_ORIGIN+4(%ebx)
	fstps	4(%edi)
	flds	C(r_origin)+8
	fsubs	DS_ENTITY_ORIGIN+8(%ebx)
	fstps	8(%edi)
	leal	C(transformed_modelorg),%eax
	pushl	%eax
	pushl	%edi
	call	C(TransformVector)
	addl	$8,%esp
	call	C(R_RotateBmodelCached)
	movl	8(%ebp),%edx
	movl	%ebx,(%edx)
.Lds_set_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

// Surface dispatcher locals: world modelorg (-24..-16), local modelorg
// (-36..-28), rotated entity (-40), face (-44), cache (-48), loop index (-52),
// x87 control words (-54/-56), and float-to-int result (-60).
#ifdef ASM486_SURFACE_DISPATCH
	.p2align 4,,15

// The surface stack and renderer layouts are pinned by compile-time C asserts
// in d_edge.c. These offsets are therefore an explicit ABI for this routine.
.set DS_SPANS, 8
.set DS_FLAGS, 24
.set DS_DATA, 28
.set DS_ENTITY, 32
.set DS_NEARZI, 36
.set DS_INSUBMODEL, 40
.set DS_ZIORIGIN, 44
.set DS_ZISTEPU, 48
.set DS_ZISTEPV, 52
.set DS_SURFACE_SIZE, 64
.set DS_ENTITY_ORIGIN, 84
.set DS_TEXINFO, 52
.set DS_TEXINFO_MIPADJUST, 32
.set DS_TEXINFO_TEXTURE, 36
.set DS_TEXTURE_OFFSETS, 44
.set DS_MIPTEX_OFFSET, 44
.set DS_CACHE_WIDTH, 32
#define SURF_DRAWSKY 4
#define SURF_DRAWTURB 0x10
#define SURF_DRAWBACKGROUND 0x40
#ifdef DEBUG
.set DS_CACHE_DATA, 48
#else
.set DS_CACHE_DATA, 44
#endif
.set DS_CVAR_VALUE, 16

#ifdef PROFILE486
.macro DS_PROFILE_BEGIN
	call C(D_DrawSurfacesProfileBegin_asm486)
.endm
.macro DS_PROFILE_FINISH
	call C(D_DrawSurfacesProfileFinish_asm486)
.endm
.macro DS_PROFILE_NOTE kind
	pushl	$\kind
	pushl	%esi
	call	C(D_DrawSurfacesProfileRecordSurface_asm486)
	addl	$8,%esp
.endm
.macro DS_PROFILE_ENTER kind
	pushl	$\kind
	call	C(D_DrawSurfacesProfileEnter_asm486)
	addl	$4,%esp
.endm
.macro DS_PROFILE_LEAVE
	call C(D_DrawSurfacesProfileLeave_asm486)
.endm
.macro DS_PROFILE_WORK kind
	pushl	$\kind
	call	C(D_DrawSurfacesProfileWork_asm486)
	addl	$4,%esp
.endm
.macro DS_PROFILE_TIMED_START
	call C(D_DrawSurfacesProfileTimedStart_asm486)
.endm
.macro DS_PROFILE_TIMED_FINISH
	call C(D_DrawSurfacesProfileTimedFinish_asm486)
.endm
.macro DS_PROFILE_TEXTURE_START
	call C(D_DrawSurfacesProfileTextureStart_asm486)
.endm
.macro DS_PROFILE_TEXTURE_FINISH
	call C(D_DrawSurfacesProfileTextureFinish_asm486)
.endm
.macro DS_PROFILE_TEXTURE_WIDTH
	pushl	DS_SPANS(%esi)
	pushl	-48(%ebp)
	pushl	-44(%ebp)
	pushl	%esi
	call C(D_DrawSurfacesProfileTextureWidth_asm486)
	addl	$16,%esp
.endm
#else
.macro DS_PROFILE_BEGIN
.endm
.macro DS_PROFILE_FINISH
.endm
.macro DS_PROFILE_NOTE kind
.endm
.macro DS_PROFILE_ENTER kind
.endm
.macro DS_PROFILE_LEAVE
.endm
.macro DS_PROFILE_WORK kind
.endm
.macro DS_PROFILE_TIMED_START
.endm
.macro DS_PROFILE_TIMED_FINISH
.endm
.macro DS_PROFILE_TEXTURE_START
.endm
.macro DS_PROFILE_TEXTURE_FINISH
.endm
.macro DS_PROFILE_TEXTURE_WIDTH
.endm
#endif

.macro DS_CALC_GRADIENTS
	call C(D_DrawSurfacesCalcGradients_asm486)
.endm



C(D_DrawSurfaces):
	.globl C(D_DrawSurfaces)
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$48,%esp
	DS_PROFILE_BEGIN

	leal	C(cl_entities),%eax
	movl	%eax,C(currententity)
	leal	C(transformed_modelorg),%eax
	pushl	%eax
	leal	C(modelorg),%eax
	pushl	%eax
	call	C(TransformVector)
	addl	$8,%esp
	movl	C(transformed_modelorg),%eax
	movl	%eax,-24(%ebp)
	movl	C(transformed_modelorg)+4,%eax
	movl	%eax,-20(%ebp)
	movl	C(transformed_modelorg)+8,%eax
	movl	%eax,-16(%ebp)
	movl	$0,-40(%ebp)

	// D_DrawSurfaces recomputes both mip-scale tables every invocation.
	xorl	%ecx,%ecx
.Lds_mip_setup:
	flds	C(xscaleinv)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	C(d_mip_xscale)(,%ecx,4)
	flds	C(yscaleinv)
	fmuls	C(d_mipscale_values)(,%ecx,4)
	fstps	C(d_mip_yscale)(,%ecx,4)
	incl	%ecx
	cmpl	$4,%ecx
	jl	.Lds_mip_setup

	movl	C(r_drawflat)+DS_CVAR_VALUE,%eax
	andl	$0x7fffffff,%eax
	testl	%eax,%eax
	jne	.Lds_drawflat

	// Textured and special surfaces share the source surface-stack order.
	movl	C(surfaces),%esi
	addl	$DS_SURFACE_SIZE,%esi
	movl	C(surface_p),%edi
.Lds_surface_loop:
	cmpl	%edi,%esi
	jae	.Lds_surface_done
	cmpl	$0,DS_SPANS(%esi)
	je	.Lds_surface_next
	incl	C(r_drawnpolycount)
	movl	DS_ZISTEPU(%esi),%eax
	movl	%eax,C(d_zistepu)
	movl	DS_ZISTEPV(%esi),%eax
	movl	%eax,C(d_zistepv)
	movl	DS_ZIORIGIN(%esi),%eax
	movl	%eax,C(d_ziorigin)
	movl	DS_FLAGS(%esi),%eax
	testl	$SURF_DRAWSKY,%eax
	jne	.Lds_sky
	testl	$SURF_DRAWBACKGROUND,%eax
	jne	.Lds_background
	testl	$SURF_DRAWTURB,%eax
	jne	.Lds_turbulent
	jmp	.Lds_texture

.Lds_sky:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	DS_PROFILE_NOTE 1
	cmpl	$0,C(r_skymade)
	jne	.Lds_sky_ready
	call	C(R_MakeSky)
.Lds_sky_ready:
	DS_PROFILE_TIMED_START
	DS_PROFILE_ENTER 2
	pushl	DS_SPANS(%esi)
	call	C(D_DrawSkyScans8)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_WORK 2
	DS_PROFILE_TIMED_FINISH
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	jmp	.Lds_surface_next

.Lds_background:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	DS_PROFILE_NOTE 2
	movl	$0,C(d_zistepu)
	movl	$0,C(d_zistepv)
	flds	.Lds_background_z
	fstps	C(d_ziorigin)
	DS_PROFILE_ENTER 0
	fnstcw	-54(%ebp)
	movw	-54(%ebp),%ax
	orb	$12,%ah
	movw	%ax,-56(%ebp)
	fldcw	-56(%ebp)
	flds	C(r_clearcolor)+DS_CVAR_VALUE
	fistpl	-60(%ebp)
	fldcw	-54(%ebp)
	movl	-60(%ebp),%eax
	andl	$0xff,%eax
	pushl	%eax
	pushl	%esi
	call	C(D_DrawSolidSurface)
	addl	$8,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	jmp	.Lds_surface_next

.Lds_turbulent:
	DS_PROFILE_NOTE 3
	movl	DS_DATA(%esi),%eax
	movl	%eax,-44(%ebp)
	movl	$0,C(d_gradient_miplevel)
	movl	DS_TEXINFO(%eax),%edx
	movl	DS_TEXINFO_TEXTURE(%edx),%edx
	movl	DS_TEXTURE_OFFSETS(%edx),%ecx
	addl	%edx,%ecx
	movl	%ecx,C(cacheblock)
	movl	$64,C(cachewidth)
	cmpl	$0,DS_INSUBMODEL(%esi)
	je	.Lds_turb_world
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-28(%ebp),%eax
	pushl	%eax
	pushl	%esi
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_SetBmodelDrawingState_asm486)
	addl	$16,%esp
	jmp	.Lds_turb_state_ready
.Lds_turb_world:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
.Lds_turb_state_ready:
	pushl	-44(%ebp)
	DS_CALC_GRADIENTS
	addl	$4,%esp
	DS_PROFILE_ENTER 3
	pushl	DS_SPANS(%esi)
	call	C(Turbulent8)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_WORK 3
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
	jmp	.Lds_surface_next

.Lds_texture:
	DS_PROFILE_NOTE 4
	cmpl	$0,DS_INSUBMODEL(%esi)
	je	.Lds_texture_world
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-28(%ebp),%eax
	pushl	%eax
	pushl	%esi
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_SetBmodelDrawingState_asm486)
	addl	$16,%esp
	jmp	.Lds_texture_state_ready
.Lds_texture_world:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
.Lds_texture_state_ready:
	movl	DS_DATA(%esi),%eax
	movl	%eax,-44(%ebp)
	movl	DS_TEXINFO(%eax),%edx
	flds	DS_NEARZI(%esi)
	fmuls	C(scale_for_mip)
	fmuls	DS_TEXINFO_MIPADJUST(%edx)
	subl	$4,%esp
	fstps	(%esp)
	call	C(D_MipLevelForScale)
	addl	$4,%esp
	movl	%eax,C(d_gradient_miplevel)
	pushl	%eax
	pushl	-44(%ebp)
	call	C(D_CacheSurface)
	addl	$8,%esp
	movl	%eax,-48(%ebp)
	leal	DS_CACHE_DATA(%eax),%edx
	movl	%edx,C(cacheblock)
	movl	DS_CACHE_WIDTH(%eax),%edx
	movl	%edx,C(cachewidth)
	pushl	-44(%ebp)
	DS_CALC_GRADIENTS
	addl	$4,%esp
	DS_PROFILE_TEXTURE_WIDTH
	DS_PROFILE_TEXTURE_START
	DS_PROFILE_ENTER 4
	pushl	DS_SPANS(%esi)
	movl	C(d_drawspans),%eax
	call	*%eax
	addl	$4,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_TEXTURE_FINISH
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE

.Lds_surface_next:
	addl	$DS_SURFACE_SIZE,%esi
	jmp	.Lds_surface_loop

.Lds_surface_done:
	leal	-24(%ebp),%eax
	pushl	%eax
	leal	-40(%ebp),%eax
	pushl	%eax
	call	C(D_RestoreWorldDrawingState_asm486)
	addl	$8,%esp
	jmp	.Lds_dispatch_finish

.Lds_drawflat:
	movl	C(surfaces),%esi
	addl	$DS_SURFACE_SIZE,%esi
	movl	C(surface_p),%edi
.Lds_flat_loop:
	cmpl	%edi,%esi
	jae	.Lds_dispatch_finish
	cmpl	$0,DS_SPANS(%esi)
	je	.Lds_flat_next
	DS_PROFILE_NOTE 0
	movl	DS_ZISTEPU(%esi),%eax
	movl	%eax,C(d_zistepu)
	movl	DS_ZISTEPV(%esi),%eax
	movl	%eax,C(d_zistepv)
	movl	DS_ZIORIGIN(%esi),%eax
	movl	%eax,C(d_ziorigin)
	DS_PROFILE_ENTER 0
	movl	DS_DATA(%esi),%eax
	andl	$0xff,%eax
	pushl	%eax
	pushl	%esi
	call	C(D_DrawSolidSurface)
	addl	$8,%esp
	DS_PROFILE_LEAVE
	DS_PROFILE_ENTER 1
	pushl	DS_SPANS(%esi)
	call	C(D_DrawZSpans)
	addl	$4,%esp
	DS_PROFILE_LEAVE
.Lds_flat_next:
	addl	$DS_SURFACE_SIZE,%esi
	jmp	.Lds_flat_loop

.Lds_dispatch_finish:
	DS_PROFILE_FINISH
	addl	$48,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	movl	%ebp,%esp
	popl	%ebp
	ret

#endif

#ifdef ASM486_RENDER_WORLD
	.equ RW_POLY_BASE, -40016
	.equ RW_POLY_BYTES, 5000*8
	.equ RW_LOCAL_BYTES, RW_POLY_BYTES+4
	.equ RW_PROFILE_START, -16

	.p2align 4,,15
	.globl C(R_RenderWorld_asm486)
C(R_RenderWorld_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$RW_LOCAL_BYTES,%esp

#ifdef PROFILE486
	movl	C(bench486_bsp_nodes),%eax
	movl	%eax,RW_PROFILE_START(%ebp)
	call	C(R_RenderWorldProfileEnter_asm486)
#endif

	// pbtofpolys points at this frame's full 5000-entry back-to-front queue.
	leal	RW_POLY_BASE(%ebp),%eax
	movl	%eax,C(pbtofpolys)
	leal	C(cl_entities),%eax
	movl	%eax,C(currententity)

	// VectorCopy(r_origin, modelorg) preserves all three float bit patterns.
	movl	C(r_origin),%eax
	movl	%eax,C(modelorg)
	movl	C(r_origin)+4,%eax
	movl	%eax,C(modelorg)+4
	movl	C(r_origin)+8,%eax
	movl	%eax,C(modelorg)+8

	// clmodel is cl_entities[0].model; publish its vertex base before the BSP walk.
	movl	C(currententity),%eax
	movl	132(%eax),%ebx
	movl	148(%ebx),%eax
	movl	%eax,C(r_pcurrentvertbase)
	movl	164(%ebx),%eax
	movl	$15,%edx
	call	C(R_RecursiveWorldNode)

	// Replay queued polygons from back to front, including element zero.
	cmpl	$0,C(r_worldpolysbacktofront)
	je	.Lrw_profile_finish
	movl	C(numbtofpolys),%esi
	decl	%esi
.Lrw_poly_loop:
	cmpl	$0,%esi
	jl	.Lrw_profile_finish
	leal	RW_POLY_BASE(%ebp,%esi,8),%eax
	pushl	0(%eax)			// clipflags, second C argument
	pushl	4(%eax)			// psurf, first C argument
	call	C(R_RenderPoly)
	addl	$8,%esp
	decl	%esi
	jmp	.Lrw_poly_loop

.Lrw_profile_finish:
#ifdef PROFILE486
	pushl	RW_PROFILE_START(%ebp)
	call	C(R_RenderWorldProfileWork_asm486)
	addl	$4,%esp
	call	C(R_RenderWorldProfileLeave_asm486)
#endif

	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
	.extern C(R_RenderFace)
	.extern C(currententity)
	.extern C(modelorg)
	.extern C(r_currentkey)
#ifdef PROFILE486
	.extern C(R_DrawSubmodelPolygonsProfileEntry_asm486)
	.extern C(R_DrawSubmodelPolygonsProfileFaceEnter_asm486)
	.extern C(R_DrawSubmodelPolygonsProfileFaceLeave_asm486)
#endif

	.section .rodata
	.p2align 3
.Lsubmodel_backface_negative_epsilon:
	.double -0.01
.Lsubmodel_backface_positive_epsilon:
	.double 0.01
	.text

	.p2align 4,,15
	.globl C(R_DrawSubmodelPolygons_asm486)
C(R_DrawSubmodelPolygons_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	8(%ebp),%ebx		// pmodel, first C argument
	movl	12(%ebp),%edi		// clipflags, second C argument
	movl	116(%ebx),%ecx		// nummodelsurfaces
	movl	180(%ebx),%esi		// surfaces
	movl	112(%ebx),%eax		// firstmodelsurface
	shll	$6,%eax			// sizeof(msurface_t) == 64
	addl	%eax,%esi

#ifdef PROFILE486
	pushl	%ecx
	call	C(R_DrawSubmodelPolygonsProfileEntry_asm486)
	addl	$4,%esp
	movl	116(%ebx),%ecx
#endif

	testl	%ecx,%ecx
	jle	.Lsubmodel_polygons_finish

.Lsubmodel_polygons_loop:
	movl	12(%esi),%eax		// psurf->plane
	flds	C(modelorg)
	fmuls	0(%eax)
	flds	C(modelorg)+4
	fmuls	4(%eax)
	faddp	%st,%st(1)
	flds	C(modelorg)+8
	fmuls	8(%eax)
	faddp	%st,%st(1)
	// Keep the x87 extended dot live through the epsilon test. GCC's C path
	// compares this value directly; a float store here culls near-plane faces
	// differently.
	fsubs	12(%eax)

	movl	16(%esi),%eax		// psurf->flags
	testl	$2,%eax			// SURF_PLANEBACK
	jz	.Lsubmodel_polygons_front
	fcompl	.Lsubmodel_backface_negative_epsilon
	fnstsw	%ax
	sahf
	// Match GCC's C output for the negative-side test: it checks C0 only, so
	// unordered x87 results follow the same branch as "below".
	jb	.Lsubmodel_polygons_visible
	jmp	.Lsubmodel_polygons_next

.Lsubmodel_polygons_front:
	fcompl	.Lsubmodel_backface_positive_epsilon
	fnstsw	%ax
	sahf
	jp	.Lsubmodel_polygons_next
	ja	.Lsubmodel_polygons_visible
	jmp	.Lsubmodel_polygons_next

.Lsubmodel_polygons_visible:
	movl	C(currententity),%eax
	movl	176(%eax),%eax		// entity->topnode
	movl	40(%eax),%eax		// mleaf->key
	movl	%eax,C(r_currentkey)

	pushl	%ecx
#ifdef PROFILE486
	call	C(R_DrawSubmodelPolygonsProfileFaceEnter_asm486)
#endif
	pushl	%edi			// clipflags, second C argument
	pushl	%esi			// psurf, first C argument
	call	C(R_RenderFace)
	addl	$8,%esp
#ifdef PROFILE486
	call	C(R_DrawSubmodelPolygonsProfileFaceLeave_asm486)
#endif
	popl	%ecx

.Lsubmodel_polygons_next:
	addl	$64,%esi
	decl	%ecx
	jne	.Lsubmodel_polygons_loop

.Lsubmodel_polygons_finish:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_BMODEL_POLYGON_CLIP
	/* Cache transformed BSP splitter planes across this entity's clip calls. */
#define ASM486_BMODEL_CLIP_PLANE_CACHE 1
	.extern C(pbverts)
	.extern C(pbedges)
	.extern C(numbverts)
	.extern C(numbedges)
	.extern C(pfrontenter)
	.extern C(pfrontexit)
	.extern C(makeclippededge)
	.extern C(entity_rotation)
	.extern C(r_entorigin)
	.extern C(currententity)
	.extern C(r_framecount)
	.extern C(bpoly_plane_cache_plane)
	.extern C(bpoly_plane_cache_entity)
	.extern C(bpoly_plane_cache_frame)
	.extern C(bpoly_plane_cache_values)
	.extern C(r_visframecount)
	.extern C(r_currentbkey)
	.extern C(R_RenderBmodelFace)
	.extern C(Con_Printf)
#ifdef PROFILE486
	.extern C(bench486_profile_frame_active)
	.extern C(bench486_bpoly_clip_edges)
	.extern C(bench486_bpoly_adjacent_endpoint_hits)
	.extern C(bench486_bpoly_plane_cache_hits)
	.extern C(bench486_bpoly_plane_cache_misses)
#endif

	.section .rodata
	.p2align 2
.Lbpc_out_of_edges:
	.asciz "Out of edges for bmodel\n"

	.text
	.p2align 4,,15
	.set BPC_SIDE0,       -16
	.set BPC_SIDE1,       -20
	.set BPC_EDGE,        -24
	.set BPC_NEXT,        -28
	.set BPC_SPLIT,       -32
	.set BPC_TDIST,       -36
	.set BPC_TNORMAL0,    -48
	.set BPC_TNORMAL1,    -44
	.set BPC_TNORMAL2,    -40
	.set BPC_LASTDIST,    -52
	.set BPC_DIST,        -56
	.set BPC_FRAC,        -60
	.set BPC_LASTSIDE,    -64
	.set BPC_SIDE,        -68
	.set BPC_PLAST,       -72
	.set BPC_PVERT,       -76
	.set BPC_PTVERT,      -80
	.set BPC_PTEDGE,      -84
	.set BPC_I,           -88
	.set BPC_PN,          -92
	.set BPC_CHILD,       -96
	.set BPC_PREV0,      -100
	.set BPC_PREV1,      -104

	.macro BPC_DOT3 left, right
	flds	0(\left)
	fmuls	0(\right)
	flds	4(\left)
	fmuls	4(\right)
	faddp	%st(0),%st(1)
	flds	8(\left)
	fmuls	8(\right)
	faddp	%st(0),%st(1)
	.endm

	.globl C(R_RecursiveClipBPoly_asm486)
C(R_RecursiveClipBPoly_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
#ifdef PROFILE486
	subl	$104,%esp
#else
	subl	$96,%esp
#endif

	movl	8(%ebp),%eax
	movl	%eax,BPC_EDGE(%ebp)
	movl	$0,BPC_SIDE0(%ebp)
	movl	$0,BPC_SIDE1(%ebp)
#ifdef PROFILE486
	movl	$0,BPC_PREV0(%ebp)
	movl	$0,BPC_PREV1(%ebp)
#endif
	movl	$0,C(makeclippededge)

	/* Transform the BSP splitter plane into this brush model's coordinates. */
	movl	12(%ebp),%eax
	movl	24(%eax),%eax
	movl	%eax,BPC_SPLIT(%ebp)
#ifdef ASM486_BMODEL_CLIP_PLANE_CACHE
	/* Key by splitter plane, entity transform, and frame; hash only selects a slot. */
	movl	%eax,%edx
	shrl	$2,%edx
	andl	$511,%edx
	cmpl	%eax,C(bpoly_plane_cache_plane)(,%edx,4)
	jne	.Lbpclip_plane_cache_miss
	movl	C(currententity),%ecx
	cmpl	%ecx,C(bpoly_plane_cache_entity)(,%edx,4)
	jne	.Lbpclip_plane_cache_miss
	movl	C(r_framecount),%ecx
	cmpl	%ecx,C(bpoly_plane_cache_frame)(,%edx,4)
	jne	.Lbpclip_plane_cache_miss
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lbpclip_plane_cache_hit_counted
	incl	C(bench486_bpoly_plane_cache_hits)
.Lbpclip_plane_cache_hit_counted:
#endif
	shll	$4,%edx
	leal	C(bpoly_plane_cache_values)(,%edx),%edi
	movl	0(%edi),%eax
	movl	%eax,BPC_TDIST(%ebp)
	movl	4(%edi),%eax
	movl	%eax,BPC_TNORMAL0(%ebp)
	movl	8(%edi),%eax
	movl	%eax,BPC_TNORMAL1(%ebp)
	movl	12(%edi),%eax
	movl	%eax,BPC_TNORMAL2(%ebp)
	jmp	.Lbpclip_plane_cache_ready
.Lbpclip_plane_cache_miss:
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lbpclip_plane_cache_miss_counted
	incl	C(bench486_bpoly_plane_cache_misses)
.Lbpclip_plane_cache_miss_counted:
#endif
#endif
	leal	C(r_entorigin),%esi
	movl	BPC_SPLIT(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fchs
	fadds	12(%edi)
	fstps	BPC_TDIST(%ebp)

	leal	C(entity_rotation),%esi
	movl	BPC_SPLIT(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fstps	BPC_TNORMAL0(%ebp)
	addl	$12,%esi
	BPC_DOT3	%esi,%edi
	fstps	BPC_TNORMAL1(%ebp)
	addl	$12,%esi
	BPC_DOT3	%esi,%edi
	fstps	BPC_TNORMAL2(%ebp)
#ifdef ASM486_BMODEL_CLIP_PLANE_CACHE
	/* Publish only complete binary32 transforms; subsequent reads are exact. */
	movl	BPC_SPLIT(%ebp),%eax
	movl	%eax,C(bpoly_plane_cache_plane)(,%edx,4)
	movl	C(currententity),%eax
	movl	%eax,C(bpoly_plane_cache_entity)(,%edx,4)
	movl	C(r_framecount),%eax
	movl	%eax,C(bpoly_plane_cache_frame)(,%edx,4)
	shll	$4,%edx
	leal	C(bpoly_plane_cache_values)(,%edx),%edi
	movl	BPC_TDIST(%ebp),%eax
	movl	%eax,0(%edi)
	movl	BPC_TNORMAL0(%ebp),%eax
	movl	%eax,4(%edi)
	movl	BPC_TNORMAL1(%ebp),%eax
	movl	%eax,8(%edi)
	movl	BPC_TNORMAL2(%ebp),%eax
	movl	%eax,12(%edi)
.Lbpclip_plane_cache_ready:
#endif

.Lbpclip_edge_loop:
	movl	BPC_EDGE(%ebp),%ebx
	testl	%ebx,%ebx
	je	.Lbpclip_edges_done
	movl	8(%ebx),%eax
	movl	%eax,BPC_NEXT(%ebp)
	movl	0(%ebx),%eax
	movl	%eax,BPC_PLAST(%ebp)
	movl	4(%ebx),%eax
	movl	%eax,BPC_PVERT(%ebp)

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lbpclip_profile_endpoints_done
	incl	C(bench486_bpoly_clip_edges)
	movl	BPC_PLAST(%ebp),%eax
	cmpl	BPC_PREV0(%ebp),%eax
	je	.Lbpclip_profile_v0_hit
	cmpl	BPC_PREV1(%ebp),%eax
	jne	.Lbpclip_profile_v1
.Lbpclip_profile_v0_hit:
	incl	C(bench486_bpoly_adjacent_endpoint_hits)
.Lbpclip_profile_v1:
	movl	BPC_PVERT(%ebp),%eax
	cmpl	BPC_PREV0(%ebp),%eax
	je	.Lbpclip_profile_v1_hit
	cmpl	BPC_PREV1(%ebp),%eax
	jne	.Lbpclip_profile_endpoints_done
.Lbpclip_profile_v1_hit:
	incl	C(bench486_bpoly_adjacent_endpoint_hits)
.Lbpclip_profile_endpoints_done:
	movl	BPC_PLAST(%ebp),%eax
	movl	%eax,BPC_PREV0(%ebp)
	movl	BPC_PVERT(%ebp),%eax
	movl	%eax,BPC_PREV1(%ebp)
#endif

	/* lastdist = dot(v[0], tplane.normal) - tplane.dist. */
	movl	BPC_PLAST(%ebp),%esi
	leal	BPC_TNORMAL0(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fsubs	BPC_TDIST(%ebp)
	fstps	BPC_LASTDIST(%ebp)
	/* IEEE single bits are positive iff bits-1 is <= 0x7f7fffff. */
	movl	BPC_LASTDIST(%ebp),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	jbe	.Lbpclip_last_front
	movl	$1,BPC_LASTSIDE(%ebp)
	jmp	.Lbpclip_last_side_ready
.Lbpclip_last_front:
	movl	$0,BPC_LASTSIDE(%ebp)
.Lbpclip_last_side_ready:

	/* dist = dot(v[1], tplane.normal) - tplane.dist. */
	movl	BPC_PVERT(%ebp),%esi
	leal	BPC_TNORMAL0(%ebp),%edi
	BPC_DOT3	%esi,%edi
	fsubs	BPC_TDIST(%ebp)
	fstps	BPC_DIST(%ebp)
	movl	BPC_DIST(%ebp),%eax
	decl	%eax
	cmpl	$0x7f7fffff,%eax
	jbe	.Lbpclip_front
	movl	$1,BPC_SIDE(%ebp)
	jmp	.Lbpclip_side_ready
.Lbpclip_front:
	movl	$0,BPC_SIDE(%ebp)
.Lbpclip_side_ready:
	movl	BPC_SIDE(%ebp),%eax
	cmpl	BPC_LASTSIDE(%ebp),%eax
	je	.Lbpclip_keep_edge

	/* A crossing creates one model vertex and two directed edge records. */
	cmpl	$500,C(numbverts)
	jae	.Lbpclip_return
	flds	BPC_LASTDIST(%ebp)
	flds	BPC_DIST(%ebp)
	fsubr	%st(1),%st(0)
	/* frac = lastdist / (lastdist - dist); match the x87 stack order. */
	fdivrp	%st(0),%st(1)
	fstps	BPC_FRAC(%ebp)

	movl	C(numbverts),%eax
	incl	%eax
	movl	%eax,C(numbverts)
	decl	%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	C(pbverts),%edi
	leal	(%edi,%eax),%edi
	movl	%edi,BPC_PTVERT(%ebp)

	/* Interpolate v[0] + frac * (v[1] - v[0]) in x87 precision. */	movl	BPC_PLAST(%ebp),%esi
	movl	BPC_PVERT(%ebp),%edi
	movl	BPC_PTVERT(%ebp),%ebx
	flds	(%edi)
	fsubs	(%esi)
	fmuls	BPC_FRAC(%ebp)
	fadds	(%esi)
	fstps	(%ebx)
	flds	4(%edi)
	fsubs	4(%esi)
	fmuls	BPC_FRAC(%ebp)
	fadds	4(%esi)
	fstps	4(%ebx)
	flds	8(%edi)
	fsubs	8(%esi)
	fmuls	BPC_FRAC(%ebp)
	fadds	8(%esi)
	fstps	8(%ebx)

	cmpl	$999,C(numbedges)
	jae	.Lbpclip_edges_overflow
	movl	C(numbedges),%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	C(pbedges),%edi
	leal	(%edi,%eax),%edi
	movl	%edi,BPC_PTEDGE(%ebp)

	movl	BPC_LASTSIDE(%ebp),%eax
	testl	%eax,%eax
	jne	.Lbpclip_first_back
	movl	BPC_SIDE0(%ebp),%edx
	jmp	.Lbpclip_first_link
.Lbpclip_first_back:
	movl	BPC_SIDE1(%ebp),%edx
.Lbpclip_first_link:
	movl	BPC_PTEDGE(%ebp),%edi
	movl	%edx,8(%edi)
	testl	%eax,%eax
	jne	.Lbpclip_first_set_back
	movl	%edi,BPC_SIDE0(%ebp)
	jmp	.Lbpclip_first_head_ready
.Lbpclip_first_set_back:
	movl	%edi,BPC_SIDE1(%ebp)
.Lbpclip_first_head_ready:
	movl	BPC_PLAST(%ebp),%edx
	movl	%edx,0(%edi)
	movl	BPC_PTVERT(%ebp),%edx
	movl	%edx,4(%edi)

	movl	BPC_PTEDGE(%ebp),%edi
	leal	12(%edi),%edi
	movl	BPC_SIDE(%ebp),%eax
	testl	%eax,%eax
	jne	.Lbpclip_second_back
	movl	BPC_SIDE0(%ebp),%edx
	jmp	.Lbpclip_second_link
.Lbpclip_second_back:
	movl	BPC_SIDE1(%ebp),%edx
.Lbpclip_second_link:
	movl	%edx,8(%edi)
	testl	%eax,%eax
	jne	.Lbpclip_second_set_back
	movl	%edi,BPC_SIDE0(%ebp)
	jmp	.Lbpclip_second_head_ready
.Lbpclip_second_set_back:
	movl	%edi,BPC_SIDE1(%ebp)
.Lbpclip_second_head_ready:
	movl	BPC_PTVERT(%ebp),%edx
	movl	%edx,0(%edi)
	movl	BPC_PVERT(%ebp),%edx
	movl	%edx,4(%edi)
	addl	$2,C(numbedges)

	cmpl	$0,BPC_SIDE(%ebp)
	jne	.Lbpclip_cross_back
	movl	BPC_PTVERT(%ebp),%eax
	movl	%eax,C(pfrontenter)
	jmp	.Lbpclip_mark_clipped
.Lbpclip_cross_back:
	movl	BPC_PTVERT(%ebp),%eax
	movl	%eax,C(pfrontexit)
.Lbpclip_mark_clipped:
	movl	$1,C(makeclippededge)
	jmp	.Lbpclip_edge_next

.Lbpclip_keep_edge:
	movl	BPC_SIDE(%ebp),%eax
	movl	BPC_EDGE(%ebp),%edx
	testl	%eax,%eax
	jne	.Lbpclip_keep_back
	movl	BPC_SIDE0(%ebp),%ecx
	movl	%ecx,8(%edx)
	movl	%edx,BPC_SIDE0(%ebp)
	jmp	.Lbpclip_edge_next
.Lbpclip_keep_back:
	movl	BPC_SIDE1(%ebp),%ecx
	movl	%ecx,8(%edx)
	movl	%edx,BPC_SIDE1(%ebp)

.Lbpclip_edge_next:
	movl	BPC_NEXT(%ebp),%eax
	movl	%eax,BPC_EDGE(%ebp)
	jmp	.Lbpclip_edge_loop

.Lbpclip_edges_done:
	cmpl	$0,C(makeclippededge)
	je	.Lbpclip_visit_children
	cmpl	$998,C(numbedges)
	jae	.Lbpclip_edges_overflow
	movl	C(numbedges),%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	C(pbedges),%edi
	leal	(%edi,%eax),%edi
	movl	%edi,BPC_PTEDGE(%ebp)
	movl	BPC_SIDE0(%ebp),%eax
	movl	%eax,8(%edi)
	movl	C(pfrontexit),%eax
	movl	%eax,0(%edi)
	movl	C(pfrontenter),%eax
	movl	%eax,4(%edi)
	movl	%edi,BPC_SIDE0(%ebp)

	leal	12(%edi),%edi
	movl	BPC_SIDE1(%ebp),%eax
	movl	%eax,8(%edi)
	movl	C(pfrontenter),%eax
	movl	%eax,0(%edi)
	movl	C(pfrontexit),%eax
	movl	%eax,4(%edi)
	movl	%edi,BPC_SIDE1(%ebp)
	addl	$2,C(numbedges)

.Lbpclip_visit_children:
	movl	$0,BPC_I(%ebp)
.Lbpclip_child_loop:
	movl	BPC_I(%ebp),%eax
	cmpl	$2,%eax
	jae	.Lbpclip_return
	cmpl	$0,%eax
	jne	.Lbpclip_child_back
	movl	BPC_SIDE0(%ebp),%edx
	jmp	.Lbpclip_child_edges_ready
.Lbpclip_child_back:
	movl	BPC_SIDE1(%ebp),%edx
.Lbpclip_child_edges_ready:
	testl	%edx,%edx
	je	.Lbpclip_child_next
	movl	12(%ebp),%ecx
	movl	28(%ecx,%eax,4),%ecx
	movl	%ecx,BPC_CHILD(%ebp)
	movl	C(r_visframecount),%eax
	cmpl	%eax,4(%ecx)
	jne	.Lbpclip_child_next
	cmpl	$0,0(%ecx)
	jl	.Lbpclip_child_leaf
	movl	BPC_SIDE0(%ebp),%eax
	cmpl	$0,BPC_I(%ebp)
	jne	.Lbpclip_recurse_back
	jmp	.Lbpclip_recurse_call
.Lbpclip_recurse_back:
	movl	BPC_SIDE1(%ebp),%eax
.Lbpclip_recurse_call:
	pushl	16(%ebp)
	pushl	BPC_CHILD(%ebp)
	pushl	%eax
	call	C(R_RecursiveClipBPoly_asm486)
	addl	$12,%esp
	jmp	.Lbpclip_child_next

.Lbpclip_child_leaf:
	cmpl	$-2,0(%ecx)
	je	.Lbpclip_child_next
	movl	40(%ecx),%eax
	movl	%eax,C(r_currentbkey)
	cmpl	$0,BPC_I(%ebp)
	jne	.Lbpclip_draw_back
	movl	BPC_SIDE0(%ebp),%eax
	jmp	.Lbpclip_draw_call
.Lbpclip_draw_back:
	movl	BPC_SIDE1(%ebp),%eax
.Lbpclip_draw_call:
	pushl	16(%ebp)
	pushl	%eax
	call	C(R_RenderBmodelFace)
	addl	$8,%esp

.Lbpclip_child_next:
	incl	BPC_I(%ebp)
	jmp	.Lbpclip_child_loop

.Lbpclip_edges_overflow:
	pushl	$.Lbpc_out_of_edges
	call	C(Con_Printf)
	addl	$4,%esp
.Lbpclip_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif

#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
	.extern C(pbverts)
	.extern C(pbedges)
	.extern C(numbverts)
	.extern C(numbedges)
	.extern C(modelorg)
	.extern C(currententity)
	.extern C(r_pcurrentvertbase)
	.extern C(R_RecursiveClipBPoly)
	.extern C(Sys_Error)

	.section .rodata
	.p2align 3
.Lsolid_bmodel_backface_negative_epsilon:
	.double -0.01
.Lsolid_bmodel_backface_positive_epsilon:
	.double 0.01
.Lsolid_bmodel_no_edges:
	.asciz "no edges in bmodel"

	.text
	.p2align 4,,15
	.set SBCSP_I,          -16
	.set SBCSP_J,          -20
	.set SBCSP_LINDEX,     -24
	.set SBCSP_DOT,        -28
	.set SBCSP_SURF,       -32
	.set SBCSP_NUMSURFS,   -36
	.set SBCSP_PEDGES,     -40
	.set SBCSP_PPLANE,     -44
	.set SBCSP_PBEDGE,     -48
	.set SBCSP_PSURFEDGES, -52
	.set SBCSP_EDGEBASE,   -56
	.set SBCSP_VERTBASE,   -60
	.set SBCSP_PEDGE,      -64
	.set SBCSP_NUMEDGES,   -68

	.globl C(R_DrawSolidClippedSubmodelPolygons_asm486)
C(R_DrawSolidClippedSubmodelPolygons_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/*
	 * C keeps bedges[1000] (12000 bytes) and bverts[500] (6000 bytes)
	 * in this function's frame. Keep the edge records at the low end of this
	 * reservation and vertices above them; locals remain above -68(%ebp).
	 */
	subl	$18064,%esp

	movl	8(%ebp),%ebx			// model
	movl	116(%ebx),%eax		// model->nummodelsurfaces
	movl	%eax,SBCSP_NUMSURFS(%ebp)
	movl	180(%ebx),%eax		// model->surfaces
	movl	112(%ebx),%edx		// model->firstmodelsurface
	shll	$6,%edx				// sizeof(msurface_t) == 64
	addl	%edx,%eax
	movl	%eax,SBCSP_SURF(%ebp)
	movl	156(%ebx),%eax		// model->edges
	movl	%eax,SBCSP_PEDGES(%ebp)

	leal	-18076(%ebp),%eax	// 1000 bedge_t records, 12 bytes each
	movl	%eax,SBCSP_EDGEBASE(%ebp)
	leal	12000(%eax),%edx	// 500 mvertex_t records, 12 bytes each
	movl	%edx,SBCSP_VERTBASE(%ebp)
	movl	$0,SBCSP_I(%ebp)

.Lsolid_bmodel_surface_loop:
	movl	SBCSP_I(%ebp),%eax
	cmpl	SBCSP_NUMSURFS(%ebp),%eax
	jae	.Lsolid_bmodel_return
	movl	SBCSP_SURF(%ebp),%esi
	movl	12(%esi),%edi			// msurface_t::plane
	movl	%edi,SBCSP_PPLANE(%ebp)

	/* dot = DotProduct(modelorg, plane.normal) - plane.dist; */
	leal	C(modelorg),%esi
	flds	0(%esi)
	fmuls	0(%edi)
	flds	4(%esi)
	fmuls	4(%edi)
	faddp	%st(0),%st(1)
	flds	8(%esi)
	fmuls	8(%edi)
	faddp	%st(0),%st(1)
	fsubs	12(%edi)
	fstps	SBCSP_DOT(%ebp)

	movl	SBCSP_SURF(%ebp),%esi
	testl	$2,16(%esi)			// SURF_PLANEBACK
	je	.Lsolid_bmodel_test_front
	fldl	.Lsolid_bmodel_backface_negative_epsilon
	flds	SBCSP_DOT(%ebp)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lsolid_bmodel_next_surface	// C comparison is false for NaN
	jb	.Lsolid_bmodel_visible		// dot < -BACKFACE_EPSILON
	jmp	.Lsolid_bmodel_next_surface

.Lsolid_bmodel_test_front:
	fldl	.Lsolid_bmodel_backface_positive_epsilon
	flds	SBCSP_DOT(%ebp)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lsolid_bmodel_next_surface
	ja	.Lsolid_bmodel_visible		// dot > BACKFACE_EPSILON
	jmp	.Lsolid_bmodel_next_surface

.Lsolid_bmodel_visible:
	/* Each visible surface starts with private 500-vertex/1000-edge buffers. */
	movl	SBCSP_VERTBASE(%ebp),%eax
	movl	%eax,C(pbverts)
	movl	SBCSP_EDGEBASE(%ebp),%eax
	movl	%eax,C(pbedges)
	movl	$0,C(numbverts)
	movl	$0,C(numbedges)

	movl	SBCSP_SURF(%ebp),%esi
	movl	24(%esi),%ecx			// msurface_t::numedges
	testl	%ecx,%ecx
	jle	.Lsolid_bmodel_no_edges_error
	movl	%ecx,SBCSP_NUMEDGES(%ebp)
	movl	%ecx,C(numbedges)
	movl	SBCSP_EDGEBASE(%ebp),%eax
	movl	%eax,SBCSP_PBEDGE(%ebp)

	movl	8(%ebp),%ebx
	movl	188(%ebx),%eax		// model->surfedges
	movl	20(%esi),%edx		// msurface_t::firstedge
	leal	(%eax,%edx,4),%eax
	movl	%eax,SBCSP_PSURFEDGES(%ebp)
	movl	$0,SBCSP_J(%ebp)

.Lsolid_bmodel_edge_loop:
	movl	SBCSP_J(%ebp),%eax
	cmpl	SBCSP_NUMEDGES(%ebp),%eax
	jae	.Lsolid_bmodel_edges_done
	movl	SBCSP_PSURFEDGES(%ebp),%edx
	movl	(%edx,%eax,4),%ecx
	movl	%ecx,SBCSP_LINDEX(%ebp)
	testl	%ecx,%ecx
	jg	.Lsolid_bmodel_edge_forward
	negl	%ecx				// reverse surfedge indexes its source medge
.Lsolid_bmodel_load_medge:
	movl	SBCSP_PEDGES(%ebp),%esi
	leal	(,%ecx,8),%edx		// sizeof(medge_t) == 8
	addl	%edx,%esi
	movl	%esi,SBCSP_PEDGE(%ebp)

	movl	SBCSP_J(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax				// j * sizeof(bedge_t), 12 bytes
	movl	SBCSP_PBEDGE(%ebp),%edi
	addl	%eax,%edi

	cmpl	$0,SBCSP_LINDEX(%ebp)
	jle	.Lsolid_bmodel_edge_reverse
	/* Positive surfedges preserve medge.v[0], then medge.v[1]. */
	movzwl	0(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,0(%edi)
	movzwl	2(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,4(%edi)
	jmp	.Lsolid_bmodel_edge_link

.Lsolid_bmodel_edge_reverse:
	/* Negative or zero surfedges reverse the source medge winding. */
	movzwl	2(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,0(%edi)
	movzwl	0(%esi),%eax
	leal	(%eax,%eax,2),%eax
	movl	C(r_pcurrentvertbase),%edx
	leal	(%edx,%eax,4),%eax
	movl	%eax,4(%edi)

.Lsolid_bmodel_edge_link:
	leal	12(%edi),%eax
	movl	%eax,8(%edi)
	incl	SBCSP_J(%ebp)
	jmp	.Lsolid_bmodel_edge_loop

.Lsolid_bmodel_edge_forward:
	jmp	.Lsolid_bmodel_load_medge

.Lsolid_bmodel_edges_done:
	movl	SBCSP_J(%ebp),%eax
	decl	%eax
	leal	(%eax,%eax,2),%eax
	shll	$2,%eax
	movl	SBCSP_PBEDGE(%ebp),%edi
	addl	%eax,%edi
	movl	$0,8(%edi)			// mark the input edge list end

	movl	C(currententity),%eax
	movl	176(%eax),%edx		// entity_t::topnode
	pushl	SBCSP_SURF(%ebp)
	pushl	%edx
	pushl	SBCSP_PBEDGE(%ebp)
	call	C(R_RecursiveClipBPoly)
	addl	$12,%esp
	jmp	.Lsolid_bmodel_next_surface

.Lsolid_bmodel_no_edges_error:
	pushl	$.Lsolid_bmodel_no_edges
	call	C(Sys_Error)
	addl	$4,%esp

.Lsolid_bmodel_next_surface:
	incl	SBCSP_I(%ebp)
	addl	$64,SBCSP_SURF(%ebp)
	jmp	.Lsolid_bmodel_surface_loop

.Lsolid_bmodel_return:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret
#endif
