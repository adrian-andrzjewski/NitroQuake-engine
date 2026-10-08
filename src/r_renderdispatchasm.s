/*
Copyright (C) 1996-1997 Id Software, Inc.
GPL-2.0-or-later; without warranty. See COPYING.

Maintained 32-bit cdecl adapters from renderer globals to independently tested
assembly kernels. Every argument retains its original type and stored bits;
only the particle time argument performs the original double-to-float cast.
EBX/ESI/EDI/EBP are preserved. x87 is empty on entry/return, with the caller's
control word unchanged. BENCH-only hooks observe outgoing argument words and
phase order; release code calls the real kernels directly.
*/
#include "asm_i386.h"
#include "asm_renderdispatch.h"
#undef i386
.arch i386
.arch .387
.code32
.text
#ifdef ASM486_RENDER_DISPATCH

#ifdef BENCH486
.data
.p2align 2
.globl C(bench486_dispatch_probe)
C(bench486_dispatch_probe): .long 0
.globl C(bench486_dispatch_timer)
C(bench486_dispatch_timer): .long 0
.text
#endif

/* Arguments are already on the stack, in the real callee's cdecl order.
   The benchmark observer receives (phase, word_count, argument_words). */
.macro DISPATCH_CALL phase,words,target
#ifdef BENCH486
    cmpl $0,C(bench486_dispatch_probe)
    je .Ldispatch_real\@
    movl %esp,%eax
    pushl %eax
    pushl $\words
    pushl $\phase
    call *C(bench486_dispatch_probe)
    addl $12,%esp
    jmp .Ldispatch_done\@
.Ldispatch_real\@:
#endif
    call \target
#ifdef BENCH486
.Ldispatch_done\@:
#endif
.endm

#ifdef PROFILE486
.macro DISPATCH_TIME
#ifdef BENCH486
    cmpl $0,C(bench486_dispatch_timer)
    je .Ldispatch_real_time\@
    call *C(bench486_dispatch_timer)
    jmp .Ldispatch_time_done\@
.Ldispatch_real_time\@:
#endif
    call C(Sys_FloatTime)
#ifdef BENCH486
.Ldispatch_time_done\@:
#endif
.endm
#endif

#ifdef ASM486_SPRITE_SCAN_LEFT
.p2align 2
.globl C(D_SpriteScanLeftEdge)
C(D_SpriteScanLeftEdge):
    pushl C(r_spritedesc)+rd_desc_vertices
    pushl C(r_spritedesc)+rd_desc_nump
    pushl C(maxindex)
    pushl C(minindex)
    pushl C(sprite_spans)
    DISPATCH_CALL 1,5,C(D_SpriteScanLeftEdge_asm486)
    addl $20,%esp
    ret
#endif

#ifdef ASM486_SPRITE_SCAN_RIGHT
.p2align 2
.globl C(D_SpriteScanRightEdge)
C(D_SpriteScanRightEdge):
    pushl C(r_refdef)+rd_ref_bottom
    pushl C(r_refdef)+rd_ref_top
    pushl C(r_refdef)+rd_ref_right
    pushl C(r_refdef)+rd_ref_left
    pushl C(r_spritedesc)+rd_desc_vertices
    pushl C(r_spritedesc)+rd_desc_nump
    pushl C(maxindex)
    pushl C(minindex)
    pushl C(sprite_spans)
    DISPATCH_CALL 2,9,C(D_SpriteScanRightEdge_asm486)
    addl $36,%esp
    ret
#endif

#ifdef ASM486_SPRITE_GRADIENTS
.p2align 2
.globl C(D_SpriteCalculateGradients)
C(D_SpriteCalculateGradients):
    pushl C(sprite_height)
    DISPATCH_CALL 3,1,C(D_SpriteCalculateGradients_asm486)
    addl $4,%esp
    ret
#endif

#ifdef ASM486_SPRITE_DRAW
.p2align 2
.globl C(D_DrawSprite)
C(D_DrawSprite):
#ifdef BENCH486
    cmpl $0,C(bench486_sprite_project_hook)
    je .Ldispatch_sprite_no_project_hook
    pushl $C(r_spritedesc)
    call *C(bench486_sprite_project_hook)
    addl $4,%esp
.Ldispatch_sprite_no_project_hook:
#endif
    movl C(r_spritedesc)+rd_desc_frame,%eax
    leal rd_frame_pixels(%eax),%edx
    pushl %edx
    pushl rd_frame_height(%eax)
    pushl rd_frame_width(%eax)
    pushl C(r_spritedesc)+rd_desc_vertices
    pushl C(r_spritedesc)+rd_desc_nump
    DISPATCH_CALL 4,5,C(D_DrawSprite_asm486)
    addl $20,%esp
    ret
#endif

#ifdef ASM486_ALIAS_MATRIX_COMPOSE_ASM
.p2align 2
.globl C(R_AliasSetViewMatrix)
C(R_AliasSetViewMatrix):
    pushl $C(r_dispatch_alias_viewmatrix)
    pushl $C(vpn)
    pushl $C(vup)
    pushl $C(vright)
    DISPATCH_CALL 5,4,C(R_AliasSetViewMatrix_asm486)
    addl $16,%esp
    ret
#endif

#ifdef ASM486_MARK_LIGHTS
.p2align 2
.globl C(R_MarkLights)
.globl C(R_MarkLights_asm486)
C(R_MarkLights):
C(R_MarkLights_asm486):
    movl C(cl)+rd_client_worldmodel,%eax
    pushl rd_model_surfaces(%eax)
    /* Each push moves the next original argument to the same ESP+16 slot. */
    pushl 16(%esp)
    pushl 16(%esp)
    pushl 16(%esp)
    DISPATCH_CALL 6,4,C(R_MarkLightsTree_asm486)
    addl $16,%esp
    ret
#endif

#ifdef ASM486_DYNAMIC_LIGHT_PUSH
.p2align 2
.globl C(R_PushDlights)
C(R_PushDlights):
    movl C(cl)+rd_client_worldmodel,%eax
    testl %eax,%eax
    je .Ldispatch_push_null_world
    movl rd_model_nodes(%eax),%eax
.Ldispatch_push_null_world:
    pushl %eax
    pushl $C(cl_dlights)
    pushl C(r_framecount)
    pushl C(cl)+rd_client_time+4
    pushl C(cl)+rd_client_time
    DISPATCH_CALL 8,5,C(R_PushDlights_asm486)
    addl $20,%esp
    ret
#endif

#ifdef ASM486_RENDER_FACE
.p2align 2
.globl C(R_RenderFace)
C(R_RenderFace):
    movl 4(%esp),%eax
    movl C(currententity),%edx
    movl rd_entity_model(%edx),%edx
    movl rd_surface_firstedge(%eax),%ecx
    shll $2,%ecx
    addl rd_model_surfedges(%edx),%ecx
    pushl %ecx
    pushl rd_model_edges(%edx)
    pushl 16(%esp)
    pushl %eax
    DISPATCH_CALL 9,4,C(R_RenderFace_asm486)
    addl $16,%esp
    ret
#endif

/* These gradient seams retain the separately selected Z-gradient backend,
   including the C benchmark oracle when that backend was not selected. */
.macro DISPATCH_GRADIENT entry,phase
.p2align 2
.globl \entry
\entry:
#ifdef BENCH486
    cmpl $0,C(bench486_dispatch_probe)
    je .Ldispatch_gradient_real\@
    pushl 4(%esp)
    DISPATCH_CALL \phase,1,C(R_SetSurfaceZGradients)
    addl $4,%esp
    ret
.Ldispatch_gradient_real\@:
#if !defined(ASM486_SURFACE_ZGRADIENTS)
    jmp C(R_SetSurfaceZGradients_C)
#else
    jmp C(R_SetSurfaceZGradients)
#endif
#else
    jmp C(R_SetSurfaceZGradients)
#endif
.endm
#ifdef ASM486_RENDER_FACE
    DISPATCH_GRADIENT C(R_RenderFaceGradient_asm486),10
#endif
#ifdef ASM486_RENDER_BMODEL_FACE
    DISPATCH_GRADIENT C(R_RenderBmodelFaceGradient_asm486),11
#endif

#ifdef ASM486_PARTICLE_UPDATE
.p2align 2
.globl C(R_DrawParticles)
C(R_DrawParticles):
    pushl %ebp
    movl %esp,%ebp
#ifdef PROFILE486
    /* -4 particle count; -8 gib count; -12 entry active flag;
       -24..-17 start time. The active flag is latched before starting particles. */
    subl $24,%esp
    movl $0,-4(%ebp)
    movl $0,-8(%ebp)
    movl C(bench486_profile_frame_active),%eax
    movl %eax,-12(%ebp)
    testl %eax,%eax
    je .Ldispatch_particle_no_start_time
    DISPATCH_TIME
    fstpl -24(%ebp)
.Ldispatch_particle_no_start_time:
#endif
    DISPATCH_CALL 13,0,C(D_StartParticles)
#ifdef PROFILE486
    leal -8(%ebp),%eax
    pushl %eax
    leal -4(%ebp),%eax
    pushl %eax
#endif
    pushl C(sv_gravity)+rd_cvar_value
    pushl C(cl)+rd_client_oldtime+4
    pushl C(cl)+rd_client_oldtime
    subl $4,%esp
    fldl C(cl)+rd_client_time
    fstps (%esp)
#ifdef PROFILE486
    DISPATCH_CALL 12,6,C(R_DrawParticles_asm486)
    addl $24,%esp
#else
    DISPATCH_CALL 12,4,C(R_DrawParticles_asm486)
    addl $16,%esp
#endif
    DISPATCH_CALL 14,0,C(D_EndParticles)
#ifdef PROFILE486
    cmpl $0,-12(%ebp)
    je .Ldispatch_particle_return
    movl -4(%ebp),%eax
    addl %eax,C(bench486_particle_count)
    movl -8(%ebp),%eax
    addl %eax,C(bench486_gib_trail_particles)
    DISPATCH_TIME
    fsubl -24(%ebp)
    faddl C(bench486_particle_seconds)
    fstpl C(bench486_particle_seconds)
.Ldispatch_particle_return:
#endif
    leave
    ret
#endif
#endif
