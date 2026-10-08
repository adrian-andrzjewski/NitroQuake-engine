/*
Copyright (C) 1996-1997 Id Software, Inc.
GPL-2.0-or-later; without warranty. See COPYING.

Drawing-driver state, derived from the pinned original software algorithms.
32-bit cdecl: preserve EBX/ESI/EDI/EBP; EAX/ECX/EDX are caller-owned. Floating
operations retain the original x87 evaluation and store boundaries. Integer
casts temporarily select truncation and restore the complete caller control
word. Row tables and surface-cache objects remain canonical shared storage.
Normal builds assemble this maintained file; no C-to-assembly generation.
*/
#include "asm_i386.h"
#include "asm_drawingdriver.h"
#undef i386
.arch i386
.arch .387
.code32
#ifdef ASM486_DRAWING_DRIVER
.text
#ifdef BENCH486
.data
.p2align 2
.globl C(bench486_driver_probe)
C(bench486_driver_probe): .long 0
.text
#endif

/* Observe the same typed outgoing arguments as the C oracle. */
.macro DRIVER_CALL phase,words,target
#ifdef BENCH486
    cmpl $0,C(bench486_driver_probe)
    je .Ldriver_call_real\@
    movl %esp,%eax
    pushl %eax
    pushl $\words
    pushl $\phase
    call *C(bench486_driver_probe)
    addl $12,%esp
    jmp .Ldriver_call_done\@
.Ldriver_call_real\@:
#endif
    call \target
#ifdef BENCH486
.Ldriver_call_done\@:
#endif
.endm

.p2align 2
.globl C(D_Init)
C(D_Init):
    movl $1,C(r_skydirect)
    pushl $C(d_subdiv16)
    DRIVER_CALL 1,1,C(Cvar_RegisterVariable)
    addl $4,%esp
    pushl $C(d_mipcap)
    DRIVER_CALL 1,1,C(Cvar_RegisterVariable)
    addl $4,%esp
    pushl $C(d_mipscale)
    DRIVER_CALL 1,1,C(Cvar_RegisterVariable)
    addl $4,%esp
    movl $0,C(r_drawpolys)
    movl $0,C(r_worldpolysbacktofront)
    movl $1,C(r_recursiveaffinetriangles)
    movl $1,C(r_pixbytes)
    movl $0x3f800000,C(r_aliasuvscale)
    ret

/* These eight entry points are intentional original software-driver no-ops.
   VID_LockBuffer/UnlockBuffer expand to empty DOS macros in the reference. */
.macro DRIVER_NOOP name
.p2align 2
.globl \name
\name:
    ret
.endm
DRIVER_NOOP C(D_CopyRects)
DRIVER_NOOP C(D_EnableBackBufferAccess)
DRIVER_NOOP C(D_TurnZOn)
DRIVER_NOOP C(D_DisableBackBufferAccess)
DRIVER_NOOP C(D_UpdateRects)
DRIVER_NOOP C(D_EndParticles)
DRIVER_NOOP C(D_StartParticles)
DRIVER_NOOP C(D_DrawPoly)

.p2align 2
.globl C(D_SetupFrame)
C(D_SetupFrame):
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    subl $8,%esp /* -12 original CW; -14 truncating CW; four bytes padding */
    cmpl $0,C(r_dowarp)
    je .Ldriver_setup_video
    movl C(r_warpbuffer),%ecx
    movl $dd_WARP_WIDTH,%esi
    jmp .Ldriver_setup_buffer
.Ldriver_setup_video:
    movl C(vid)+dd_viddef_t_buffer,%ecx
    movl C(vid)+dd_viddef_t_rowbytes,%esi
.Ldriver_setup_buffer:
    movl %ecx,C(d_viewbuffer)
    movl %esi,C(screenwidth)
    cmpl C(d_driver_viewspan_base),%ecx
    jne .Ldriver_setup_rows
    cmpl C(d_driver_viewspan_stride),%esi
    je .Ldriver_setup_rows_done
.Ldriver_setup_rows:
    movl C(vid)+dd_viddef_t_height,%ebx
    xorl %eax,%eax
    testl %ebx,%ebx
    je .Ldriver_setup_cache
.Ldriver_setup_row:
    movl C(d_scantable)(,%eax,4),%edx
    addl %ecx,%edx
    movl %edx,C(viewspantable)(,%eax,4)
    incl %eax
    cmpl %eax,%ebx
    jne .Ldriver_setup_row
.Ldriver_setup_cache:
    movl %ecx,C(d_driver_viewspan_base)
    movl %esi,C(d_driver_viewspan_stride)
.Ldriver_setup_rows_done:
    movl $0,C(d_roverwrapped)
    movl C(sc_rover),%eax
    movl %eax,C(d_initial_rover)
    fnstcw -12(%ebp)
    movw -12(%ebp),%ax
    orw $0x0c00,%ax
    movw %ax,-14(%ebp)
    flds C(d_mipcap)+dd_cvar_t_value
    fldcw -14(%ebp)
    fistpl C(d_minmip)
    fldcw -12(%ebp)
    movl C(d_minmip),%eax
    testl %eax,%eax
    jns .Ldriver_setup_mip_nonnegative
    xorl %eax,%eax
.Ldriver_setup_mip_nonnegative:
    cmpl $3,%eax
    jle .Ldriver_setup_mip_clamped
    movl $3,%eax
.Ldriver_setup_mip_clamped:
    movl %eax,C(d_minmip)
    flds C(d_mipscale)+dd_cvar_t_value
    fsts C(d_scalemip)
    flds .Ldriver_mip_half
    fmul %st(1),%st
    fstps C(d_scalemip)+4
    fmuls .Ldriver_mip_quarter
    fstps C(d_scalemip)+8
    /* Preserve the reference comparison, including its unordered flag result. */
    fldz
    fcomps C(d_subdiv16)+dd_cvar_t_value
    fnstsw %ax
    testb $64,%ah
    jne .Ldriver_setup_eight_spans
    movl $C(D_DrawSpans16),%eax
    jmp .Ldriver_setup_span_entry
.Ldriver_setup_eight_spans:
    movl $C(D_DrawSpans8),%eax
.Ldriver_setup_span_entry:
    movl %eax,C(d_drawspans)
    movl $0,C(d_aflatcolor)
    addl $8,%esp
    popl %esi
    popl %ebx
    leave
    ret

.p2align 2
.globl C(D_Patch)
C(D_Patch):
    cmpl $0,C(d_driver_protectset8)
    jne .Ldriver_patch_done
    movl $C(D_PolysetAff8End),%eax
    subl $C(D_PolysetAff8Start),%eax
    pushl %eax
    pushl $C(D_PolysetAff8Start)
    DRIVER_CALL 2,2,C(Sys_MakeCodeWriteable)
    addl $8,%esp
    movl $1,C(d_driver_protectset8)
.Ldriver_patch_done:
    ret

.p2align 2
.globl C(D_ViewChanged)
C(D_ViewChanged):
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $8,%esp /* -16 integer temporary; -18 original CW; -20 truncating CW */
    movl $dd_WARP_WIDTH,%esi
    cmpl $0,C(r_dowarp)
    jne .Ldriver_view_stride
    movl C(vid)+dd_viddef_t_rowbytes,%esi
.Ldriver_view_stride:
    flds C(xscale)
    fsts C(scale_for_mip)
    flds C(yscale)
    fxch %st(1)
    fcomp %st(1)
    fnstsw %ax
    testb $1,%ah
    je .Ldriver_view_keep_xscale
    fstps C(scale_for_mip)
    jmp .Ldriver_view_scale_done
.Ldriver_view_keep_xscale:
    fstp %st(0)
.Ldriver_view_scale_done:
    movl C(vid)+dd_viddef_t_width,%eax
    movl %eax,C(d_zwidth)
    addl %eax,%eax
    movl %eax,C(d_zrowbytes)
    movl C(r_refdef)+dd_refdef_t_vrect+dd_vrect_t_width,%edi
    movl $1,%eax
    cmpl $319,%edi
    jle .Ldriver_view_min_pixel
    /* Straightforward signed division; this mode-change path is not hot. */
    movl %edi,%eax
    cltd
    movl $320,%ecx
    idivl %ecx
.Ldriver_view_min_pixel:
    movl %eax,C(d_pix_min)
    movl %edi,-16(%ebp)
    fildl -16(%ebp)
    fldl .Ldriver_one_over_eighty
    fmul %st(1),%st
    flds .Ldriver_half
    fadd %st,%st(1)
    fxch %st(1)
    fnstcw -18(%ebp)
    movw -18(%ebp),%ax
    orw $0x0c00,%ax
    movw %ax,-20(%ebp)
    fldcw -20(%ebp)
    fistpl C(d_pix_max)
    fldcw -18(%ebp)
    fldl .Ldriver_one_over_three_twenty
    fmulp %st,%st(2)
    faddp %st,%st(1)
    fldcw -20(%ebp)
    fistpl -16(%ebp)
    fldcw -18(%ebp)
    movl $8,%eax
    subl -16(%ebp),%eax
    movl %eax,C(d_pix_shift)
    movl C(d_pix_max),%edx
    testl %edx,%edx
    jg .Ldriver_view_max_pixel
    movl $1,%edx
    movl %edx,C(d_pix_max)
.Ldriver_view_max_pixel:
    flds C(pixelAspect)
    fcompl .Ldriver_aspect_threshold
    fnstsw %ax
    testb $69,%ah
    sete %cl
    movzbl %cl,%ecx
    movl %ecx,C(d_y_aspect_shift)
    movl C(r_refdef)+dd_refdef_t_vrect+dd_vrect_t_x,%eax
    movl %eax,C(d_vrectx)
    movl C(r_refdef)+dd_refdef_t_vrect+dd_vrect_t_y,%eax
    movl %eax,C(d_vrecty)
    movl C(r_refdef)+dd_refdef_t_vrectright,%eax
    subl %edx,%eax
    movl %eax,C(d_vrectright_particle)
    shll %cl,%edx
    movl C(r_refdef)+dd_refdef_t_vrectbottom,%eax
    subl %edx,%eax
    movl %eax,C(d_vrectbottom_particle)
    movl C(vid)+dd_viddef_t_height,%edi
    movl C(d_pzbuffer),%ecx
    movl C(d_zrowbytes),%ebx
    xorl %eax,%eax
    xorl %edx,%edx
    testl %edi,%edi
    je .Ldriver_view_rows_done
.Ldriver_view_row:
    movl %edx,C(d_scantable)(,%eax,4)
    movl %ecx,C(zspantable)(,%eax,4)
    addl %esi,%edx
    addl %ebx,%ecx
    incl %eax
    cmpl %eax,%edi
    jne .Ldriver_view_row
.Ldriver_view_rows_done:
    call C(D_Patch)
    addl $8,%esp
    popl %edi
    popl %esi
    popl %ebx
    leave
    ret

.p2align 2
.globl C(D_FlushCaches)
C(D_FlushCaches):
    movl C(sc_base),%eax
    testl %eax,%eax
    je .Ldriver_flush_return
.Ldriver_flush_owner:
    movl dd_surfcache_t_owner(%eax),%edx
    testl %edx,%edx
    je .Ldriver_flush_next
    movl $0,(%edx)
.Ldriver_flush_next:
    /* Read next after clearing the owner, preserving the original alias order. */
    movl dd_surfcache_t_next(%eax),%eax
    testl %eax,%eax
    jne .Ldriver_flush_owner
    movl C(sc_base),%eax
    movl %eax,C(sc_rover)
    movl $0,dd_surfcache_t_next(%eax)
    movl $0,dd_surfcache_t_owner(%eax)
    movl C(sc_size),%edx
    movl %edx,dd_surfcache_t_size(%eax)
.Ldriver_flush_return:
    ret

.data
.p2align 3
/* Bit-exact immutable factors from the pinned C compiler listing. */
.Ldriver_mip_half: .long 0x3ecccccd
.Ldriver_mip_quarter: .long 0x3e4ccccd
.Ldriver_half: .long 0x3f000000
.p2align 3
.Ldriver_one_over_eighty: .long 0x9999999a,0x3f899999
.Ldriver_one_over_three_twenty: .long 0x9999999a,0x3f699999
.Ldriver_aspect_threshold: .long 0x66666666,0x3ff66666
#endif
