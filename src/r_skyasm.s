/*
Copyright (C) 1996-1997 Id Software, Inc.
GPL-2.0-or-later; without warranty. See COPYING.

Maintained i486 equivalents of r_sky.c's five sky routines. The canonical
arrays and renderer globals remain defined in C; C algorithm bodies are only
selected by the reference implementation or retained for benchmark comparison.
All entries use 32-bit cdecl. EBX, ESI, EDI and EBP are preserved when used.
x87 starts/ends empty and retains the caller's control word on every path.
The 131-byte bottom rows deliberately include three wrap pixels for unaligned
dword sampling. Palette index zero has the original transparent-mask behavior.
*/
#include "asm_i386.h"
#include "asm_sky.h"
#undef i486
.arch i486
.arch .387
.code32

#if defined(ASM486_SKY) || defined(BENCH486)
.data
.p2align 2
.globl C(r_sky_xlast_asm486)
C(r_sky_xlast_asm486): .long -1
.globl C(r_sky_ylast_asm486)
C(r_sky_ylast_asm486): .long -1
.text

/* Evaluate skytime*skyspeed under the original precision/rounding mode.
   Only the final integer conversion uses truncate mode, as in the C cast.
   EAX/EDX are scratch; result is an integer in the requested register. */
.macro SKY_SHIFT result
    subl $8,%esp
    flds C(skytime)
    fmuls C(skyspeed)
    fnstcw 6(%esp)
    movw 6(%esp),%ax
    orb $12,%ah
    movw %ax,4(%esp)
    fldcw 4(%esp)
    fistpl (%esp)
    fldcw 6(%esp)
    movl (%esp),\result
    addl $8,%esp
.endm

.p2align 2
.globl C(R_InitSky_asm486)
#ifdef ASM486_SKY
.globl C(R_InitSky)
C(R_InitSky):
#endif
C(R_InitSky_asm486):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    movl 20(%esp),%ebp
    addl sky_texture_mip_offsets(%ebp),%ebp
    leal 128(%ebp),%esi
    movl $C(newsky)+128,%edi
    movl $128,%ebx
.Lsky_init_top_row:
    /* Copy the immutable right half of each 256-byte source row. */
    movl $32,%ecx
    rep movsl
    addl $128,%esi
    addl $128,%edi
    decl %ebx
    jne .Lsky_init_top_row
    movl %ebp,%esi
    xorl %edi,%edi
    movl $128,%ebx
.Lsky_init_bottom_row:
    xorl %ecx,%ecx
.Lsky_init_bottom_pixel:
    movl %ecx,%eax
    andl $sky_mask,%eax
    movb (%esi,%eax),%dl
    movb %dl,C(bottomsky)(%edi)
    testb %dl,%dl
    sete %al
    negb %al                 /* zero pixel => ff mask, nonzero => 00 */
    movb %al,C(bottommask)(%edi)
    incl %edi
    incl %ecx
    cmpl $sky_bottom_stride,%ecx
    jne .Lsky_init_bottom_pixel
    addl $sky_texture_stride,%esi
    decl %ebx
    jne .Lsky_init_bottom_row
    movl $C(newsky),C(r_skysource)
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret

/* The two byte-indexed compositors share this direct translation of the
   original four-pixel inner loop. EBX=shift, ESI=left-half source pointer,
   EDI=destination, -16(EBP)=baseofs, -20(EBP)=y. For MakeSky the destination
   retains the 256-byte stride; a generated tile has a packed 128-byte stride. */
.macro SKY_COMPOSITE destination_stride
    movl $0,-20(%ebp)
.Lsky_row\@:
    movl -20(%ebp),%eax
    addl %ebx,%eax
    andl $sky_mask,%eax
    imull $sky_bottom_stride,%eax
    movl %eax,-16(%ebp)
    xorl %ecx,%ecx
.Lsky_pixel\@:
    leal (%ecx,%ebx),%eax
    andl $sky_mask,%eax
    addl -16(%ebp),%eax
    movl C(bottommask)(%eax),%edx
    andl 128(%esi),%edx
    orl C(bottomsky)(%eax),%edx
    movl %edx,(%edi)
    addl $4,%esi
    addl $4,%edi
    addl $4,%ecx
    cmpl $sky_size,%ecx
    jne .Lsky_pixel\@
    addl $128,%esi
.if \destination_stride == 256
    addl $128,%edi
.endif
    incl -20(%ebp)
    cmpl $sky_size,-20(%ebp)
    jne .Lsky_row\@
.endm

.p2align 2
.globl C(R_MakeSky_asm486)
#ifdef ASM486_SKY
.globl C(R_MakeSky)
C(R_MakeSky):
#endif
C(R_MakeSky_asm486):
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $8,%esp
    SKY_SHIFT %ebx
    cmpl %ebx,C(r_sky_xlast_asm486)
    jne .Lsky_make_changed
    cmpl %ebx,C(r_sky_ylast_asm486)
    je .Lsky_make_return
.Lsky_make_changed:
    /* Both original shifts use skyspeed. Preserve the cached early return,
       including its behavior when r_skymade was independently reset. */
    movl %ebx,C(r_sky_xlast_asm486)
    movl %ebx,C(r_sky_ylast_asm486)
    movl $C(newsky),%esi
    movl %esi,%edi
    SKY_COMPOSITE 256
    movl $1,C(r_skymade)
.Lsky_make_return:
    addl $8,%esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret

.p2align 2
.globl C(R_GenSkyTile_asm486)
#ifdef ASM486_SKY
.globl C(R_GenSkyTile)
C(R_GenSkyTile):
#endif
C(R_GenSkyTile_asm486):
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $8,%esp
    SKY_SHIFT %ebx
    movl $C(newsky),%esi
    movl 8(%ebp),%edi
    SKY_COMPOSITE 128
    addl $8,%esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret

.p2align 2
.globl C(R_GenSkyTile16_asm486)
#ifdef ASM486_SKY
.globl C(R_GenSkyTile16)
C(R_GenSkyTile16):
#endif
C(R_GenSkyTile16_asm486):
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    subl $8,%esp
    SKY_SHIFT %ebx
    movl $C(newsky),%esi
    movl 8(%ebp),%edi
    movl $0,-20(%ebp)
.Lsky_tile16_row:
    movl -20(%ebp),%eax
    addl %ebx,%eax
    andl $sky_mask,%eax
    imull $sky_bottom_stride,%eax
    movl %eax,-16(%ebp)
    xorl %ecx,%ecx
.Lsky_tile16_pixel:
    leal (%ecx,%ebx),%eax
    andl $sky_mask,%eax
    addl -16(%ebp),%eax
    movzbl C(bottommask)(%eax),%edx
    andb 128(%esi),%dl
    orb C(bottomsky)(%eax),%dl
    movw C(d_8to16table)(,%edx,2),%ax
    movw %ax,(%edi)
    incl %esi
    addl $2,%edi
    incl %ecx
    cmpl $sky_size,%ecx
    jne .Lsky_tile16_pixel
    addl $128,%esi
    incl -20(%ebp)
    cmpl $sky_size,-20(%ebp)
    jne .Lsky_tile16_row
    addl $8,%esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret

.p2align 2
.globl C(R_SetSkyFrame_asm486)
#ifdef ASM486_SKY
.globl C(R_SetSkyFrame)
C(R_SetSkyFrame):
#endif
C(R_SetSkyFrame_asm486):
    pushl %ebp
    movl %esp,%ebp
    pushl %ebx
    subl $12,%esp
    fildl C(iskyspeed)
    fstps C(skyspeed)
    fildl C(iskyspeed2)
    fstps C(skyspeed2)
    pushl C(iskyspeed2)
    pushl C(iskyspeed)
    call C(GreatestCommonDivisor)
    addl $8,%esp
    movl %eax,%ebx
    movl C(iskyspeed),%eax
    cltd
    idivl %ebx
    movl %eax,%ecx
    movl C(iskyspeed2),%eax
    cltd
    idivl %ebx
    imull %ecx,%eax
    shll $7,%eax
    movl %eax,-12(%ebp)
    /* The reference retains the integer period in an x87 register. An extra
       float store here would change large-time/large-period results. */
    fildl -12(%ebp)
    fldl C(cl)+sky_client_time
    fld %st(0)
    fdiv %st(2),%st(0)
    fnstcw -6(%ebp)
    movw -6(%ebp),%ax
    orb $12,%ah
    movw %ax,-8(%ebp)
    fldcw -8(%ebp)
    fistpl -12(%ebp)
    fldcw -6(%ebp)
    fxch %st(1)
    fimull -12(%ebp)
    fsubrp %st(0),%st(1)
    fstps C(skytime)
    movl $0,C(r_skymade)
    addl $12,%esp
    popl %ebx
    popl %ebp
    ret
#endif
