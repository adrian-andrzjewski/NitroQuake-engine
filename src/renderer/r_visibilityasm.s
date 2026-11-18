/*
Copyright (C) 1996-1997 Id Software, Inc.
This program is free software; you can redistribute it and/or modify it under
the GNU General Public License, version 2 or (at your option) any later version.
This program is distributed without any warranty. See the accompanying license.
*/
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */

/* Runtime visibility support: model.c Mod_PointInLeaf, Mod_DecompressVis,
 * Mod_LeafPVS. C owns models, BSP nodes, planes and mod_novis; this module owns
 * the persistent decompression buffer and the three algorithm entry points.
 *
 * DJGPP 32-bit cdecl: entry ESP+4 first argument, ESP+8 second; EAX pointer
 * result. EBX/ESI/EDI/EBP preserved, EAX/ECX/EDX and arithmetic flags volatile.
 * The point walk retains p.z,p.y,p.x on the x87 stack exactly as the inspected
 * C reference does. Do not insert a binary32 store at the plane-distance test.
 * No control-word changes; every return restores the incoming x87 stack depth.
 *
 * RLE follows the original do/while, including its first packet for row == 0,
 * zero-count packets, and untouched bytes beyond the decoded row. Inputs are
 * the same valid BSP visibility streams as the C renderer; no new clamping or
 * altered run length is introduced. ABI offsets are checked in asm_visibility.h.
 */
#ifdef ASM486_VISIBILITY
.arch i486
.arch .387
.code32
.text
.p2align 3
.globl _Mod_PointInLeaf
_Mod_PointInLeaf:
    movl 8(%esp),%ecx                 /* model */
    testl %ecx,%ecx
    jz .Lvis_bad_model
    movl 164(%ecx),%edx               /* node = model->nodes */
    testl %edx,%edx
    jz .Lvis_bad_model
    cmpl $0,(%edx)
    js .Lvis_leaf_without_point      /* a leaf root never reads p */
    movl 4(%esp),%eax
    flds 0(%eax)
    flds 4(%eax)
    flds 8(%eax)                     /* ST: z,y,x */
.Lvis_point_node:
    movl 24(%edx),%ecx               /* plane = node->plane */
    flds 0(%ecx)
    fmul %st(3),%st(0)               /* normal.x * p.x */
    flds 4(%ecx)
    fmul %st(3),%st(0)               /* normal.y * p.y */
    faddp %st(0),%st(1)
    flds 8(%ecx)
    fmul %st(2),%st(0)               /* normal.z * p.z */
    faddp %st(0),%st(1)
    fsubs 12(%ecx)
    ftst
    fnstsw %ax
    fstp %st(0)                     /* discard d, retain input coordinates */
    testb $0x45,%ah                  /* strict positive: C0=C2=C3=0 */
    jz .Lvis_front_child
    movl 32(%edx),%edx
    jmp .Lvis_child_selected
.Lvis_front_child:
    movl 28(%edx),%edx
.Lvis_child_selected:
    cmpl $0,(%edx)
    jns .Lvis_point_node
    fstp %st(0)
    fstp %st(0)
    fstp %st(0)
.Lvis_leaf_without_point:
    movl %edx,%eax
    ret
.Lvis_bad_model:
    pushl $.Lvis_bad_model_message
    call _Sys_Error                 /* the existing terminating error boundary */
    addl $4,%esp
    jmp .Lvis_bad_model              /* Sys_Error never returns */

.p2align 3
.globl _Mod_DecompressVis
_Mod_DecompressVis:
    pushl %esi
    pushl %edi
    movl 12(%esp),%esi               /* compressed input */
    movl 16(%esp),%eax               /* model */
    movl 136(%eax),%ecx
    addl $7,%ecx
    sarl $3,%ecx                    /* row = (numleafs + 7) >> 3 */
    movl $_asm486_vis_decompressed,%edi
    testl %esi,%esi
    jnz .Lvis_packet
    testl %ecx,%ecx
    jz .Lvis_decoded
.Lvis_no_input:
    movb $0xff,(%edi)
    incl %edi
    decl %ecx
    jnz .Lvis_no_input
    jmp .Lvis_decoded
.Lvis_packet:
    movzbl (%esi),%eax
    testl %eax,%eax
    jz .Lvis_zero_packet
    movb %al,(%edi)
    incl %esi
    incl %edi
    jmp .Lvis_packet_end
.Lvis_zero_packet:
    movzbl 1(%esi),%eax
    addl $2,%esi
    testl %eax,%eax
    jz .Lvis_packet_end
.Lvis_zero_run:
    movb $0,(%edi)
    incl %edi
    decl %eax
    jnz .Lvis_zero_run
.Lvis_packet_end:
    movl %edi,%edx
    subl $_asm486_vis_decompressed,%edx
    cmpl %ecx,%edx
    jl .Lvis_packet                 /* original signed out-base < row */
.Lvis_decoded:
    movl $_asm486_vis_decompressed,%eax
    popl %edi
    popl %esi
    ret

.p2align 3
.globl _Mod_LeafPVS
_Mod_LeafPVS:
    movl 8(%esp),%ecx
    movl 4(%esp),%edx
    cmpl 140(%ecx),%edx
    je .Lvis_solid_leaf
    movl 24(%edx),%edx
    pushl %ecx
    pushl %edx
    call _Mod_DecompressVis
    addl $8,%esp
    ret
.Lvis_solid_leaf:
    movl $_mod_novis,%eax            /* canonical pointer, not a copied buffer */
    ret

.data
.Lvis_bad_model_message:
    .asciz "Mod_PointInLeaf: bad model"
.bss
.p2align 3
#ifdef BENCH486
.globl _bench486_vis_before
_bench486_vis_before: .space 32
#endif
.globl _asm486_vis_decompressed
_asm486_vis_decompressed: .space 1024
#ifdef BENCH486
.globl _bench486_vis_after
_bench486_vis_after: .space 32
#endif
#endif
