/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// Complete top-level sprite orientation and dispatch: r_sprite.c:R_DrawSprite.
// 32-bit cdecl, no parameters; reads the same renderer/entity globals as C.
// EBP is the frame pointer; EBX owns psprite; ESI/EDI are copy scratch.
// Callee-saved registers restored on every path. Local -24..-16 is tvec[3].
// x87 starts and ends empty; control word/rounding mode is never modified.
// GPL-2.0-or-later, following the original Quake sprite algorithms.
#include "asm_i386.h"
#include "renderer/asm_sprite.h"

#if defined(ASM486_SPRITE_FRAME) || defined(BENCH486)
        .data
.Lsprite_bad_frame: .asciz "R_DrawSprite: no such frame %d\n"
        .text
        .p2align 4,,15
        .globl C(R_GetSpriteframePublic_asm486)
#ifdef ASM486_SPRITE_FRAME
        .globl C(R_GetSpriteframe)
C(R_GetSpriteframe):
#endif
C(R_GetSpriteframePublic_asm486):
        pushl   %ebx
        movl    8(%esp),%ebx
        movl    C(currententity),%edx
        movl    so_entity_frame(%edx),%eax
        testl   %eax,%eax
        js      .Lsprite_frame_fallback
        cmpl    so_sprite_numframes(%ebx),%eax
        jge     .Lsprite_frame_fallback
        jmp     .Lsprite_frame_dispatch
.Lsprite_frame_fallback:
        pushl   %eax
        pushl   $.Lsprite_bad_frame
        call    C(Con_Printf)
        addl    $8,%esp
        movl    C(currententity),%edx
        xorl    %eax,%eax
.Lsprite_frame_dispatch:
        pushl   so_entity_syncbase(%edx)
        pushl   C(cl)+so_client_time+4
        pushl   C(cl)+so_client_time
        pushl   %eax
        pushl   %ebx
        call    C(R_GetSpriteframe_asm486)
        addl    $20,%esp
        popl    %ebx
        ret
#endif

#if defined(ASM486_SPRITE_ORIENTATION) || defined(BENCH486)
        .data
        .p2align 3
.Lsprite_pole_positive: .double 0.999848
.Lsprite_pole_negative: .double -0.999848
.Lsprite_radians:       .double 0.017453292519943295
.Lsprite_bad_type:      .asciz "R_DrawSprite: Bad sprite type %d"
        .text
        .p2align 4,,15
        .globl C(R_DrawSprite_asm486)
#ifdef ASM486_SPRITE_ORIENTATION
        .globl C(R_DrawSprite)
C(R_DrawSprite):
#endif
C(R_DrawSprite_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi
        subl    $12,%esp
        movl    C(currententity),%eax
        movl    so_entity_model(%eax),%eax
        movl    so_model_cache(%eax),%ebx
        pushl   %ebx
        call    C(R_GetSpriteframe)
        addl    $4,%esp
        movl    %eax,C(r_spritedesc)+so_desc_frame
        movl    (%eax),%edx
        movl    %edx,C(sprite_width)
        movl    4(%eax),%edx
        movl    %edx,C(sprite_height)
        movl    so_sprite_type(%ebx),%eax
        cmpl    $so_facing_upright,%eax
        je      .Lsprite_facing
        cmpl    $so_parallel,%eax
        je      .Lsprite_parallel
        cmpl    $so_parallel_upright,%eax
        je      .Lsprite_parallel_upright
        cmpl    $so_oriented,%eax
        je      .Lsprite_oriented
        cmpl    $so_parallel_oriented,%eax
        je      .Lsprite_roll
        pushl   %eax
        pushl   $.Lsprite_bad_type
        call    C(Sys_Error)
        addl    $8,%esp
        jmp     .Lsprite_dispatch

.Lsprite_facing:
        flds    C(modelorg)
        fchs
        fstps   -24(%ebp)
        flds    C(modelorg)+4
        fchs
        fstps   -20(%ebp)
        flds    C(modelorg)+8
        fchs
        fstps   -16(%ebp)
        leal    -24(%ebp),%eax
        pushl   %eax
        call    C(VectorNormalize_asm486)
        addl    $4,%esp
        fstp    %st(0)                  // discarded length
        flds    -16(%ebp)
        jmp     .Lsprite_pole_test
.Lsprite_parallel_upright:
        flds    C(vpn)+8
.Lsprite_pole_test:
        // Preserve double threshold and strict inequalities from the C oracle.
        fcoml   .Lsprite_pole_positive
        fnstsw  %ax
        testb   $0x45,%ah
        jz      .Lsprite_reject_pop
        fcompl  .Lsprite_pole_negative
        fnstsw  %ax
        testb   $1,%ah
        jnz     .Lsprite_return
        movl    $0,C(r_spritedesc)+so_desc_up
        movl    $0,C(r_spritedesc)+so_desc_up+4
        movl    $0x3f800000,C(r_spritedesc)+so_desc_up+8
        cmpl    $so_facing_upright,so_sprite_type(%ebx)
        jne     .Lsprite_upright_view_axes
        flds    -20(%ebp)
        fstps   C(r_spritedesc)+so_desc_right
        flds    -24(%ebp)
        jmp     .Lsprite_upright_right
.Lsprite_upright_view_axes:
        flds    C(vpn)+4
        fstps   C(r_spritedesc)+so_desc_right
        flds    C(vpn)
.Lsprite_upright_right:
        fchs
        fstps   C(r_spritedesc)+so_desc_right+4
        movl    $0,C(r_spritedesc)+so_desc_right+8
        pushl   $C(r_spritedesc)+so_desc_right
        call    C(VectorNormalize_asm486)
        addl    $4,%esp
        fstp    %st(0)
        flds    C(r_spritedesc)+so_desc_right+4
        fchs
        fstps   C(r_spritedesc)+so_desc_normal
        movl    C(r_spritedesc)+so_desc_right,%eax
        movl    %eax,C(r_spritedesc)+so_desc_normal+4
        movl    $0,C(r_spritedesc)+so_desc_normal+8
        jmp     .Lsprite_dispatch

.Lsprite_parallel:
        movl    $C(vup),%esi
        movl    $C(r_spritedesc)+so_desc_up,%edi
        movl    $3,%ecx
        rep movsl
        movl    $C(vright),%esi
        movl    $3,%ecx
        rep movsl
        movl    $C(vpn),%esi
        movl    $3,%ecx
        rep movsl
        jmp     .Lsprite_dispatch
.Lsprite_oriented:
        pushl   $C(r_spritedesc)+so_desc_up
        pushl   $C(r_spritedesc)+so_desc_right
        pushl   $C(r_spritedesc)+so_desc_normal
        movl    C(currententity),%eax
        addl    $so_entity_angles,%eax
        pushl   %eax
        call    C(AngleVectors_asm486)
        addl    $16,%esp
        jmp     .Lsprite_dispatch

.Lsprite_roll:
        movl    C(currententity),%eax
        fldl    .Lsprite_radians
        fmuls   so_entity_angles+8(%eax)
        fld     %st(0)
        fsin
        fxch    %st(1)
        fcos                            // cr,sr retained extended for all axes
        xorl    %ecx,%ecx
.Lsprite_roll_axis:
        movl    C(vpn)(,%ecx,4),%eax
        movl    %eax,C(r_spritedesc)+so_desc_normal(,%ecx,4)
        flds    C(vright)(,%ecx,4)       // right,cr,sr
        flds    C(vup)(,%ecx,4)          // up,right,cr,sr
        fld     %st(1)
        fmul    %st(3),%st(0)
        fld     %st(1)
        fmul    %st(5),%st(0)
        faddp   %st(0),%st(1)
        fstps   C(r_spritedesc)+so_desc_right(,%ecx,4)
        fmul    %st(2),%st(0)            // up*cr,right,cr,sr
        fxch    %st(1)
        fmul    %st(3),%st(0)            // right*sr,up*cr,cr,sr
        fsubrp  %st(0),%st(1)           // emits up*cr-right*sr (GAS pop reversal)
        fstps   C(r_spritedesc)+so_desc_up(,%ecx,4)
        incl    %ecx
        cmpl    $3,%ecx
        jne     .Lsprite_roll_axis
        fstp    %st(0)
        fstp    %st(0)
.Lsprite_dispatch:
        pushl   so_sprite_beamlength(%ebx)
        call    C(R_RotateSprite)
        addl    $4,%esp
        call    C(R_SetupAndDrawSprite)
        jmp     .Lsprite_return
.Lsprite_reject_pop:
        fstp    %st(0)
.Lsprite_return:
        addl    $12,%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret
#endif
