// Renderer-visible math, equivalent to mathlib.c under the pinned i486 profile.
// 32-bit cdecl: EBX/ESI/EDI/EBP preserved; EAX/ECX/EDX and x87 scratch.
// x87 is empty on entry; VectorNormalize returns one extended value in ST(0).
// Neither routine changes the control word. No C math/runtime callees.
// GPL-2.0-or-later, following the original Quake mathlib.c algorithms.
#include "asm_i386.h"

#if defined(ASM486_RENDER_MATH) || defined(ASM486_SPRITE_ORIENTATION) || defined(BENCH486)
        .data
        .p2align 3
.Lmath_radians:
        .double 0.017453292519943295
        .text
        .p2align 4,,15
        .globl C(VectorNormalize_asm486)
#ifdef ASM486_RENDER_MATH
        .globl C(VectorNormalize)
C(VectorNormalize):
#endif
C(VectorNormalize_asm486):
        movl    4(%esp),%edx
        flds    (%edx)                  // z,y,x below accumulated length
        flds    4(%edx)
        flds    8(%edx)
        fld     %st(2)
        fmul    %st(3),%st(0)            // x*x
        fld     %st(2)
        fmul    %st(3),%st(0)            // y*y
        faddp   %st(0),%st(1)
        fld     %st(1)
        fmul    %st(2),%st(0)            // z*z
        faddp   %st(0),%st(1)
        fsqrt                           // length,z,y,x; keep extended length
        ftst
        fnstsw  %ax
        testb   $0x40,%ah
        jnz     .Lnormalize_zero
        fld1
        fdiv    %st(1),%st(0)            // inverse,length,z,y,x
        fmul    %st(0),%st(4)
        fxch    %st(4)
        fstps   (%edx)
        fxch    %st(2)
        fmul    %st(3),%st(0)
        fstps   4(%edx)
        fmulp   %st(0),%st(2)
        fxch    %st(1)
        fstps   8(%edx)                  // length remains as cdecl FP return
        ret
.Lnormalize_zero:
        fstp    %st(2)                  // discard input without altering zero v
        fstp    %st(0)
        fstp    %st(1)
        ret

        .p2align 4,,15
        .globl C(AngleVectors_asm486)
#ifdef ASM486_RENDER_MATH
        .globl C(AngleVectors)
C(AngleVectors):
#endif
C(AngleVectors_asm486):
        pushl   %ebx
        subl    $8,%esp                 // reference's two float spill boundaries
        movl    16(%esp),%ebx           // angles: pitch,yaw,roll
        movl    20(%esp),%ecx           // forward
        movl    24(%esp),%edx           // right
        movl    28(%esp),%eax           // up
        fldl    .Lmath_radians
        fld     %st(0)
        fmuls   4(%ebx)
        fld     %st(0)
        fsin
        fxch    %st(1)
        fcos
        fld     %st(2)
        fmuls   (%ebx)
        fld     %st(0)
        fsin
        fxch    %st(1)
        fcos
        fxch    %st(4)
        fmuls   8(%ebx)
        fld     %st(0)
        fsin
        fxch    %st(1)
        fcos                            // cr,sr,sp,cy,sy,cp

        fld     %st(3)
        fmul    %st(6),%st(0)            // cp*cy
        fstps   (%ecx)
        fld     %st(4)
        fmul    %st(6),%st(0)            // cp*sy
        fstps   4(%ecx)
        fld     %st(2)
        fchs
        fstps   8(%ecx)

        fxch    %st(1)                  // sr,cr,sp,cy,sy,cp
        fsts    4(%esp)                 // float sr used later in up[0]
        fchs                            // -sr,cr,sp,cy,sy,cp
        fld     %st(0)
        fmul    %st(3),%st(0)            // -sr*sp
        fsts    (%esp)                  // float product used by right[1]
        fmul    %st(4),%st(0)            // -sr*sp*cy
        fld     %st(5)
        fmul    %st(3),%st(0)            // sy*cr
        faddp   %st(0),%st(1)
        fstps   (%edx)
        flds    (%esp)
        fmul    %st(5),%st(0)
        fld     %st(4)
        fmul    %st(3),%st(0)
        // GAS's historical reversed pop mnemonic emits right[1]=a-b.
        fsubrp  %st(0),%st(1)
        fstps   4(%edx)
        fld     %st(0)
        fmul    %st(6),%st(0)
        fstps   8(%edx)

        fxch    %st(2)
        fmul    %st(1),%st(0)            // cr*sp,cr,-sr,cy,sy,cp
        fld     %st(0)
        fmul    %st(4),%st(0)
        flds    4(%esp)
        fmul    %st(6),%st(0)
        faddp   %st(0),%st(1)
        fstps   (%eax)
        fmulp   %st(0),%st(4)
        fxch    %st(2)
        fmulp   %st(0),%st(1)
        faddp   %st(0),%st(2)
        fxch    %st(1)
        fstps   4(%eax)
        fmulp   %st(0),%st(1)
        fstps   8(%eax)                  // x87 stack empty
        addl    $8,%esp
        popl    %ebx
        ret
#endif

#ifdef BENCH486
// Generic direct ABI probe; fixtures are serialized, never nested.
// unsigned Bench486Call_asm486(fn,nwords,args,float_return_or_null).
// Detect damaged callee-saved registers, ESP, CW, TOP/tags, local canary and DF.
// Recover ESP through private data so a broken candidate can report a failure.
        .data
        .p2align 2
.Lprobe_stack: .long 0
        .text
        .p2align 4,,15
        .globl C(Bench486Call_asm486)
C(Bench486Call_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi
        subl    $80,%esp
        movl    %esp,.Lprobe_stack
        movl    12(%ebp),%eax
        movl    %eax,-92(%ebp)           // base+0: stack argument word count
        movl    8(%ebp),%eax
        movl    %eax,-84(%ebp)           // base+8: function pointer
        movl    20(%ebp),%eax
        movl    %eax,-88(%ebp)           // base+4: optional FP return destination
        movl    $0x496486a5,-24(%ebp)
        fnstenv -52(%ebp)
        fldenv  -52(%ebp)               // undo FNSTENV's exception-mask change
        movl    12(%ebp),%ecx
        movl    16(%ebp),%edx
.Lprobe_push_args:
        testl   %ecx,%ecx
        jz      .Lprobe_call
        decl    %ecx
        pushl   (%edx,%ecx,4)
        jmp     .Lprobe_push_args
.Lprobe_call:
        movl    $0x486b0001,%ebx
        movl    $0x48650002,%esi
        movl    $0x486d0003,%edi
        movl    $0x486e0004,%ebp
        movl    .Lprobe_stack,%eax
        call    *8(%eax)
        xorl    %ecx,%ecx
        cmpl    $0x486b0001,%ebx
        je      .Lprobe_esi
        orl     $1,%ecx
.Lprobe_esi:
        cmpl    $0x48650002,%esi
        je      .Lprobe_edi
        orl     $2,%ecx
.Lprobe_edi:
        cmpl    $0x486d0003,%edi
        je      .Lprobe_ebp
        orl     $4,%ecx
.Lprobe_ebp:
        cmpl    $0x486e0004,%ebp
        je      .Lprobe_esp
        orl     $8,%ecx
.Lprobe_esp:
        movl    .Lprobe_stack,%edx
        movl    (%edx),%eax
        shll    $2,%eax
        negl    %eax
        addl    %edx,%eax
        cmpl    %eax,%esp
        je      .Lprobe_recover
        orl     $16,%ecx
.Lprobe_recover:
        movl    %edx,%esp
        movl    4(%esp),%ebx
        testl   %ebx,%ebx
        jz      .Lprobe_environment
        fstps   (%ebx)
.Lprobe_environment:
        fnstenv 12(%esp)
        fldenv  12(%esp)
        movw    12(%esp),%ax
        cmpw    40(%esp),%ax
        je      .Lprobe_top
        orl     $32,%ecx
.Lprobe_top:
        movw    16(%esp),%ax
        xorw    44(%esp),%ax
        testw   $0x3800,%ax
        jz      .Lprobe_tags
        orl     $64,%ecx
.Lprobe_tags:
        movw    20(%esp),%ax
        cmpw    48(%esp),%ax
        je      .Lprobe_canary
        orl     $128,%ecx
.Lprobe_canary:
        cmpl    $0x496486a5,68(%esp)
        je      .Lprobe_df
        orl     $256,%ecx
.Lprobe_df:
        pushfl
        popl    %eax
        testl   $0x400,%eax
        jz      .Lprobe_done
        orl     $512,%ecx
        cld
.Lprobe_done:
        testl   $224,%ecx               // restore caller env after a faulty test
        jz      .Lprobe_return
        fldenv  40(%esp)
.Lprobe_return:
        movl    %ecx,%eax
        addl    $80,%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret

// Deliberately broken 486 callees prove the probe fails for real ABI damage.
        .globl C(Bench486FaultEBX_asm486)
C(Bench486FaultEBX_asm486):
        xorl    %ebx,%ebx
        ret
        .globl C(Bench486FaultCW_asm486)
C(Bench486FaultCW_asm486):
        subl    $4,%esp
        fnstcw  (%esp)
        xorw    $0x400,(%esp)
        fldcw   (%esp)
        addl    $4,%esp
        ret
        .globl C(Bench486FaultESP_asm486)
C(Bench486FaultESP_asm486):
        ret     $4
        .globl C(Bench486FaultX87_asm486)
C(Bench486FaultX87_asm486):
        fld1
        ret
        .globl C(Bench486FaultDF_asm486)
C(Bench486FaultDF_asm486):
        std
        ret
#endif
