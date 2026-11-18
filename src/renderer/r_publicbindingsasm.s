/*
Copyright (C) 1996-1997 Id Software, Inc.
This program is free software under the GNU General Public License, version 2
or (at your option) any later version; without warranty. See COPYING.

Assembly ownership of public entries for already-accepted renderer kernels.
These bindings preserve the original calling convention and caller arguments.
A tail jump shares the caller return address with the selected kernel; it uses
no stack storage and preserves every register/FPU value before delegation.
The BSP entry uses regparm(2), EAX=node and EDX=clipflags; its tail jump must
never convert these into cdecl arguments. Profiling and test hooks below retain
the original C entry behavior and are excluded from release builds.
Normal builds assemble this maintained source; no C-to-assembly generation.
*/
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "renderer/asm_publicbindings.h"
#undef i386 /* GCC's predefined macro must not rewrite the architecture name. */
.arch i386
.arch .387
.code32
.text
#ifdef ASM486_PUBLIC_BINDINGS

/* Public entries formerly owned by d_edge.c. */

#ifdef ASM486_SURFACE_GRADIENTS
.p2align 2
.globl _D_CalcGradients
_D_CalcGradients:
    jmp _D_CalcGradients_asm486
#endif

#ifdef ASM486_SURFACE_DISPATCH
.p2align 2
.globl _D_DrawSurfacesCalcGradients_asm486
_D_DrawSurfacesCalcGradients_asm486:
/* Follow the independently selected gradient entry, including its C
   benchmark alias when the dispatcher is assembly and gradients are C. */
#if defined(BENCH486) && !defined(ASM486_SURFACE_GRADIENTS)
    jmp _D_CalcGradients_C
#else
    jmp _D_CalcGradients
#endif
#endif

/* Public entries formerly owned by d_polyse.c. */

#ifdef ASM486_ALIAS_GRADIENTS
.p2align 2
.globl _D_PolysetCalcGradients
_D_PolysetCalcGradients:
    jmp _D_PolysetCalcGradients_asm486
#endif

#ifdef ASM486_ALIAS_SKIN_TABLE
.p2align 2
.globl _D_PolysetUpdateTables
_D_PolysetUpdateTables:
    jmp _D_PolysetUpdateTables_asm486
#endif

#ifdef ASM486_ALIAS_LINE_SCAN
.p2align 2
.globl _D_PolysetSetUpForLineScan
_D_PolysetSetUpForLineScan:
#ifdef PROFILE486
    cmpl $0, _bench486_profile_frame_active
    je .Lbindings_line_counter_done
    incl _bench486_line_setup_calls
.Lbindings_line_counter_done:
#endif
    jmp _D_PolysetSetUpForLineScan_asm486
#endif

#ifdef ASM486_ALIAS_RASTERIZE
.p2align 2
.globl _D_RasterizeAliasPolySmooth
_D_RasterizeAliasPolySmooth:
#ifdef PROFILE486
    pushl $ASM_PUBLIC_BINDINGS_ALIAS_GLUE_PROFILE
    call _Bench486ProfileEnter
    addl $4, %esp
    call _D_RasterizeAliasPolySmooth_asm486
    jmp _Bench486ProfileLeave
#else
    jmp _D_RasterizeAliasPolySmooth_asm486
#endif
#endif

#ifdef ASM486_ALIAS_EDGE_TABLE
.p2align 2
.globl _D_PolysetSetEdgeTable
_D_PolysetSetEdgeTable:
    jmp _D_PolysetSetEdgeTable_asm486
#endif

/* Public entries formerly owned by r_aclip.c. */

#ifdef ASM486_ALIAS_CLIP
.p2align 2
.globl _R_AliasClip
_R_AliasClip:
    jmp _R_AliasClip_asm486
#endif

#ifdef ASM486_ALIAS_CLIP
.p2align 2
.globl _R_AliasClipTriangle
_R_AliasClipTriangle:
    jmp _R_AliasClipTriangle_asm486
#endif

/* Public entries formerly owned by r_alias.c. */

#ifdef ASM486_BINDING_ALIAS_BBOX_PROJECT
.p2align 2
.globl _R_AliasTransformVector
_R_AliasTransformVector:
    jmp _R_AliasTransformVector_asm486
#endif

#ifdef ASM486_BINDING_ALIAS_TRANSFORM_FINAL
.p2align 2
.globl _R_AliasTransformFinalVert
_R_AliasTransformFinalVert:
    jmp _R_AliasTransformFinalVert_asm486
#endif

/* Public entries formerly owned by r_bsp.c. */

#ifdef ASM486_BMODEL_POLYGON_CLIP
.p2align 2
.globl _R_RecursiveClipBPoly
_R_RecursiveClipBPoly:
    jmp _R_RecursiveClipBPoly_asm486
#endif

#ifdef ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS
.p2align 2
.globl _R_DrawSolidClippedSubmodelPolygons
_R_DrawSolidClippedSubmodelPolygons:
    jmp _R_DrawSolidClippedSubmodelPolygons_asm486
#endif

#ifdef ASM486_DRAW_SUBMODEL_POLYGONS
.p2align 2
.globl _R_DrawSubmodelPolygons
_R_DrawSubmodelPolygons:
    jmp _R_DrawSubmodelPolygons_asm486
#endif

#ifdef ASM486_BSP_WALK
.p2align 2
.globl _R_RecursiveWorldNode
_R_RecursiveWorldNode:
    jmp _R_RecursiveWorldNode_asm486
#endif

#ifdef ASM486_RENDER_WORLD
.p2align 2
.globl _R_RenderWorld
_R_RenderWorld:
    jmp _R_RenderWorld_asm486
#endif

/* Public entries formerly owned by r_draw.c. */

#ifdef ASM486_EMIT_CACHED_EDGE
.p2align 2
.globl _R_EmitCachedEdge
_R_EmitCachedEdge:
    jmp _R_EmitCachedEdge_asm486
#endif

#ifdef ASM486_RENDER_BMODEL_FACE
.p2align 2
.globl _R_RenderBmodelFace
_R_RenderBmodelFace:
    jmp _R_RenderBmodelFace_asm486
#endif

#ifdef ASM486_RENDER_POLY
.p2align 2
.globl _R_RenderPoly
_R_RenderPoly:
    jmp _R_RenderPoly_asm486
#endif

#ifdef ASM486_DRAW_Z_SUBMODEL_POLYS
.p2align 2
.globl _R_ZDrawSubmodelPolys
_R_ZDrawSubmodelPolys:
    jmp _R_ZDrawSubmodelPolys_asm486
#endif

/* Public entries formerly owned by r_edge.c. */

#ifdef ASM486_BACKWARD_SPANS
.p2align 2
.globl _R_GenerateSpansBackward
_R_GenerateSpansBackward:
    jmp _R_GenerateSpansBackward_asm486
#endif

#ifdef ASM486_EDGE_LIST
.p2align 2
.globl _R_InsertNewEdges
_R_InsertNewEdges:
    jmp _R_InsertNewEdges_asm486
#endif

#ifdef ASM486_EDGE_LIST
.p2align 2
.globl _R_RemoveEdges
_R_RemoveEdges:
    jmp _R_RemoveEdges_asm486
#endif

#ifdef ASM486_EDGE_LIST
.p2align 2
.globl _R_StepActiveU
_R_StepActiveU:
    jmp _R_StepActiveU_asm486
#endif

#ifdef ASM486_BACKWARD_SPANS
.p2align 2
.globl _R_CleanupSpan
_R_CleanupSpan:
    jmp _R_CleanupSpan_asm486
#endif

#ifdef ASM486_BACKWARD_SPANS
.p2align 2
.globl _R_LeadingEdgeBackwards
_R_LeadingEdgeBackwards:
    jmp _R_LeadingEdgeBackwards_asm486
#endif

#ifdef ASM486_BACKWARD_SPANS
.p2align 2
.globl _R_TrailingEdge
_R_TrailingEdge:
    jmp _R_TrailingEdge_asm486
#endif

#ifdef ASM486_SCAN_EDGES
.p2align 2
.globl _R_ScanEdges
_R_ScanEdges:
    jmp _R_ScanEdges_asm486
#endif

/* Public entries formerly owned by r_efrag.c. */

#ifdef ASM486_EFRAG_STORE
.p2align 2
.globl _R_StoreEfrags
_R_StoreEfrags:
    jmp _R_StoreEfrags_asm486
#endif

/* Public entries formerly owned by r_sprite.c. */

#ifdef ASM486_SPRITE_BEAM
.p2align 2
.globl _R_RotateSprite
_R_RotateSprite:
    jmp _R_RotateSprite_asm486
#endif

#ifdef ASM486_SPRITE_CLIP
.p2align 2
.globl _R_ClipSpriteFace
_R_ClipSpriteFace:
    jmp _R_ClipSpriteFace_asm486
#endif

#ifdef ASM486_SPRITE_SETUP
.p2align 2
.globl _R_SetupAndDrawSprite
_R_SetupAndDrawSprite:
#ifdef BENCH486
    movl _bench486_sprite_setup_hook, %eax
    testl %eax, %eax
    jz .Lbindings_sprite_kernel
    jmp *%eax
.Lbindings_sprite_kernel:
#endif
    jmp _R_SetupAndDrawSprite_asm486
#endif

/* Public entries formerly owned by r_surf.c. */

#ifdef ASM486_TEXTURE_ANIMATION
.p2align 2
.globl _R_TextureAnimation
_R_TextureAnimation:
    jmp _R_TextureAnimation_asm486
#endif

#endif /* ASM486_PUBLIC_BINDINGS */
