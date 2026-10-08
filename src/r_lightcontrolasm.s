// r_light.c light-style state and BSP point-light sampling.
// i486 32-bit cdecl; preserve EBX/ESI/EDI/EBP, scratch EAX/ECX/EDX and x87.
// x87 enters/leaves empty and the caller's control word is restored exactly.
// Extended spills retain the pinned C renderer's arithmetic before its actual
// float stores. Integer conversion temporarily selects truncate, never FISTTP.
// GPL-2.0-or-later, following the original Quake algorithms.
#include "asm_i386.h"
#include "asm_light.h"
#include "asm_lightcontrol.h"

#if defined(ASM486_ANIMATED_LIGHT) || defined(BENCH486)
        .bss
        .p2align 2
.Lstyle_state:
.Lstyle_last:    .space 4
.Lstyle_inited:  .space 4
.Lstyle_cur:     .space 256
.Lstyle_len:     .space 256
        .data
        .p2align 2
.Lstyle_ten:     .float 10
        .text
        .p2align 4,,15
        .globl C(R_AnimateLight_asm486)
#ifdef ASM486_ANIMATED_LIGHT
        .globl C(R_AnimateLight)
C(R_AnimateLight):
#endif
C(R_AnimateLight_asm486):
        pushl   %ebx
        pushl   %esi
        pushl   %edi
        subl    $8,%esp                 // i, truncate CW, original CW
        flds    .Lstyle_ten
        fmull   C(cl)+lc_client_time
        fnstcw  6(%esp)
        movw    6(%esp),%ax
        orw     $0x0c00,%ax
        movw    %ax,4(%esp)
        fldcw   4(%esp)
        fistpl  (%esp)
        fldcw   6(%esp)
        movl    (%esp),%esi             // i = truncate(cl.time*10)
        cmpl    $0,.Lstyle_inited
        jne     .Lstyle_initialized
        movl    $.Lstyle_len,%edi
        movl    $lc_style_count,%ecx
        movl    $-1,%eax
        rep stosl
        movl    $.Lstyle_cur,%edi
        movl    $lc_style_count,%ecx
        xorl    %eax,%eax
        rep stosl
        movl    %esi,.Lstyle_last
        movl    $1,.Lstyle_inited
.Lstyle_initialized:
        movl    %esi,%edi
        subl    .Lstyle_last,%edi        // delta, reference's 32-bit arithmetic
        xorl    %ecx,%ecx               // light-style index j
.Lstyle_next:
        imull   $lc_style_size,%ecx,%eax
        movl    C(cl_lightstyle)+lc_style_length(%eax),%ebx
        testl   %ebx,%ebx
        jz      .Lstyle_empty
        cmpl    .Lstyle_len(,%ecx,4),%ebx
        jne     .Lstyle_changed
        movl    .Lstyle_cur(,%ecx,4),%edx
        testl   %edi,%edi
        jz      .Lstyle_value
        js      .Lstyle_backward
        cmpl    %ebx,%edi
        jge     .Lstyle_remainder
        addl    %edi,%edx
        cmpl    %ebx,%edx
        jl      .Lstyle_store
        subl    %ebx,%edx
        jmp     .Lstyle_store
.Lstyle_backward:
        movl    %ebx,%eax
        negl    %eax
        cmpl    %eax,%edi
        jle     .Lstyle_remainder
        addl    %edi,%edx
        jns     .Lstyle_store
        addl    %ebx,%edx
        jmp     .Lstyle_store
.Lstyle_changed:
        movl    %ebx,.Lstyle_len(,%ecx,4)
.Lstyle_remainder:
        movl    %esi,%eax
        cltd
        idivl   %ebx
        testl   %edx,%edx
        jns     .Lstyle_store
        addl    %ebx,%edx
.Lstyle_store:
        movl    %edx,.Lstyle_cur(,%ecx,4)
.Lstyle_value:
        imull   $lc_style_size,%ecx,%eax
        // DJGPP's char is signed: preserve the original map-byte conversion.
        movsbl  C(cl_lightstyle)+lc_style_map(%eax,%edx),%eax
        subl    $97,%eax
        imull   $22,%eax,%eax
        movl    %eax,C(d_lightstylevalue)(,%ecx,4)
        jmp     .Lstyle_advance
.Lstyle_empty:
        movl    $256,C(d_lightstylevalue)(,%ecx,4)
        movl    $0,.Lstyle_cur(,%ecx,4)
        movl    $0,.Lstyle_len(,%ecx,4)
.Lstyle_advance:
        incl    %ecx
        cmpl    $lc_style_count,%ecx
        jne     .Lstyle_next
        movl    %esi,.Lstyle_last
        addl    $8,%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        ret

#ifdef BENCH486
// void Bench486AnimateState_asm486(int *state,int restore): fixture-only state
// exchange lets long sequences start independently and preserve gameplay state.
        .globl C(Bench486AnimateState_asm486)
C(Bench486AnimateState_asm486):
        pushl   %esi
        pushl   %edi
        movl    12(%esp),%edi
        movl    $.Lstyle_state,%esi
        cmpl    $0,16(%esp)
        je      .Lstyle_exchange
        xchgl   %esi,%edi
.Lstyle_exchange:
        movl    $lc_animate_state_words,%ecx
        rep movsl
        popl    %edi
        popl    %esi
        ret
#endif
#endif

#if defined(ASM486_POINT_LIGHT) || defined(BENCH486)
        .data
        .p2align 2
.Lpoint_depth: .float 2048
        .text
        .p2align 4,,15
        .globl C(RecursiveLightPoint_asm486)
#ifdef ASM486_POINT_LIGHT
        .globl C(RecursiveLightPoint)
C(RecursiveLightPoint):
#endif
C(RecursiveLightPoint_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi
        subl    $76,%esp
        // Locals: mid[-24..-16], front[-36..-27], back[-48..-39],
        // frac[-60..-51] are explicit x87 extended spills; side -64,
        // integer s -68, original/truncate CW -70/-72, surface count -76,
        // lightmap stride -80, ds -84. Callee-save slots are -4/-8/-12.
        movl    8(%ebp),%ebx            // node
        movl    12(%ebp),%esi           // start
        movl    16(%ebp),%edi           // end
.Lpoint_node:
        cmpl    $0,ml_node_contents(%ebx)
        jl      .Lpoint_miss
        movl    ml_node_plane(%ebx),%edx
        flds    (%esi)
        fmuls   ml_plane_normal(%edx)
        flds    4(%esi)
        fmuls   ml_plane_normal+4(%edx)
        faddp   %st(0),%st(1)
        flds    8(%esi)
        fmuls   ml_plane_normal+8(%edx)
        faddp   %st(0),%st(1)
        fsubs   ml_plane_dist(%edx)
        ftst
        fnstsw  %ax
        xorl    %ecx,%ecx
        testb   $1,%ah
        setne   %cl
        movl    %ecx,-64(%ebp)
        fstpt   -36(%ebp)
        flds    (%edi)
        fmuls   ml_plane_normal(%edx)
        flds    4(%edi)
        fmuls   ml_plane_normal+4(%edx)
        faddp   %st(0),%st(1)
        flds    8(%edi)
        fmuls   ml_plane_normal+8(%edx)
        faddp   %st(0),%st(1)
        fsubs   ml_plane_dist(%edx)
        ftst
        fnstsw  %ax
        xorl    %ecx,%ecx
        testb   $1,%ah
        setne   %cl
        fstpt   -48(%ebp)
        cmpl    -64(%ebp),%ecx
        jne     .Lpoint_crossing
        movl    ml_node_children(%ebx,%ecx,4),%ebx
        jmp     .Lpoint_node             // equivalent tail recursion
.Lpoint_crossing:
        fldt    -36(%ebp)
        fldt    -48(%ebp)
        // GAS pop mnemonic reversal: these emit DE E9 and DE F1.
        fsubrp  %st(0),%st(1)           // front-back
        fldt    -36(%ebp)
        fdivp   %st(0),%st(1)           // front/(front-back)
        fstpt   -60(%ebp)
        xorl    %ecx,%ecx
.Lpoint_mid_axis:
        flds    (%edi,%ecx,4)
        fsubs   (%esi,%ecx,4)
        fldt    -60(%ebp)
        fmulp   %st(0),%st(1)
        fadds   (%esi,%ecx,4)
        fstps   -24(%ebp,%ecx,4)        // actual float store in the C algorithm
        incl    %ecx
        cmpl    $3,%ecx
        jne     .Lpoint_mid_axis
        leal    -24(%ebp),%eax
        pushl   %eax
        pushl   %esi
        movl    -64(%ebp),%ecx
        pushl   ml_node_children(%ebx,%ecx,4)
        call    C(RecursiveLightPoint_asm486)
        addl    $12,%esp
        testl   %eax,%eax
        jns     .Lpoint_return

        movzwl  ml_node_numsurfaces(%ebx),%eax
        movl    %eax,-76(%ebp)
        testl   %eax,%eax
        jz      .Lpoint_back_child
        movzwl  ml_node_firstsurface(%ebx),%eax
        shll    $6,%eax                 // msurface_t is 64 bytes
        movl    C(cl)+lc_client_worldmodel,%edx
        addl    lc_model_surfaces(%edx),%eax
        movl    %eax,%esi               // current surface
        fnstcw  -70(%ebp)
        movw    -70(%ebp),%ax
        orw     $0x0c00,%ax
        movw    %ax,-72(%ebp)
.Lpoint_surface:
        testl   $0x20,lc_surface_flags(%esi)
        jnz     .Lpoint_surface_next
        movl    ml_surface_texinfo(%esi),%edx
        // The pinned C object adds the texture offset before product 2.
        flds    -24(%ebp)
        fmuls   (%edx)
        flds    -20(%ebp)
        fmuls   4(%edx)
        faddp   %st(0),%st(1)
        fadds   12(%edx)
        flds    -16(%ebp)
        fmuls   8(%edx)
        faddp   %st(0),%st(1)
        fldcw   -72(%ebp)
        fistpl  -68(%ebp)
        fldcw   -70(%ebp)
        movl    -68(%ebp),%ecx
        movswl  ml_surface_texturemins(%esi),%eax
        cmpl    %eax,%ecx
        jl      .Lpoint_surface_next
        subl    %eax,%ecx
        movswl  ml_surface_extents(%esi),%eax
        cmpl    %eax,%ecx
        jg      .Lpoint_surface_next
        movl    %ecx,-84(%ebp)          // ds until t conversion completes
        flds    -24(%ebp)
        fmuls   16(%edx)
        flds    -20(%ebp)
        fmuls   20(%edx)
        faddp   %st(0),%st(1)
        fadds   28(%edx)
        flds    -16(%ebp)
        fmuls   24(%edx)
        faddp   %st(0),%st(1)
        fldcw   -72(%ebp)
        fistpl  -68(%ebp)
        fldcw   -70(%ebp)
        movl    -68(%ebp),%ecx
        movswl  ml_surface_texturemins+2(%esi),%eax
        cmpl    %eax,%ecx
        jl      .Lpoint_surface_next
        subl    %eax,%ecx
        movswl  ml_surface_extents+2(%esi),%eax
        cmpl    %eax,%ecx
        jg      .Lpoint_surface_next
        movl    lc_surface_samples(%esi),%edx
        testl   %edx,%edx
        jz      .Lpoint_black
        sarl    $4,%ecx                 // dt
        movswl  ml_surface_extents(%esi),%eax
        sarl    $4,%eax
        incl    %eax                    // lightmap width
        imull   %eax,%ecx
        addl    %ecx,%edx
        movl    -84(%ebp),%ecx
        sarl    $4,%ecx
        addl    %ecx,%edx               // sample at ds,dt
        movswl  ml_surface_extents+2(%esi),%ecx
        sarl    $4,%ecx
        incl    %ecx
        imull   %ecx,%eax
        movl    %eax,-80(%ebp)          // one style plane's byte stride
        xorl    %ecx,%ecx
        xorl    %eax,%eax               // 32-bit style accumulator r
.Lpoint_style:
        movzbl  lc_surface_styles(%esi,%ecx),%ebx
        cmpl    $255,%ebx
        je      .Lpoint_sample_done
        movl    C(d_lightstylevalue)(,%ebx,4),%ebx
        // Only EDI is needed as a preserved pointer after sample hit; no more
        // tree traversal occurs once a surface supplies a sample.
        movzbl  (%edx),%edi
        imull   %edi,%ebx
        addl    %ebx,%eax               // identical low-32-bit wrap as C
        addl    -80(%ebp),%edx
        incl    %ecx
        cmpl    $4,%ecx
        jne     .Lpoint_style
.Lpoint_sample_done:
        sarl    $8,%eax
        jmp     .Lpoint_return
.Lpoint_black:
        xorl    %eax,%eax
        jmp     .Lpoint_return
.Lpoint_surface_next:
        addl    $ml_surface_size,%esi
        decl    -76(%ebp)
        jnz     .Lpoint_surface
.Lpoint_back_child:
        movl    -64(%ebp),%ecx
        xorl    $1,%ecx
        pushl   %edi
        leal    -24(%ebp),%eax
        pushl   %eax
        pushl   ml_node_children(%ebx,%ecx,4)
        call    C(RecursiveLightPoint_asm486)
        addl    $12,%esp
        jmp     .Lpoint_return
.Lpoint_miss:
        movl    $-1,%eax
.Lpoint_return:
        addl    $76,%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret

        .p2align 4,,15
        .globl C(R_LightPoint_asm486)
#ifdef ASM486_POINT_LIGHT
        .globl C(R_LightPoint)
C(R_LightPoint):
#endif
C(R_LightPoint_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        subl    $12,%esp               // end[3], live through recursion
        movl    C(cl)+lc_client_worldmodel,%edx
        cmpl    $0,lc_model_lightdata(%edx)
        je      .Llightpoint_fullbright
        movl    8(%ebp),%eax
        movl    (%eax),%ecx
        movl    %ecx,-12(%ebp)
        movl    4(%eax),%ecx
        movl    %ecx,-8(%ebp)
        flds    .Lpoint_depth
        fsubrs  8(%eax)
        fstps   -4(%ebp)
        leal    -12(%ebp),%ecx
        pushl   %ecx
        pushl   %eax
        pushl   lc_model_nodes(%edx)
        call    C(RecursiveLightPoint_asm486)
        addl    $12,%esp
        cmpl    $-1,%eax
        jne     .Llightpoint_ambient
        xorl    %eax,%eax
.Llightpoint_ambient:
        movl    C(r_refdef)+lc_refdef_ambient,%edx
        cmpl    %edx,%eax
        jge     .Llightpoint_return
        movl    %edx,%eax
        jmp     .Llightpoint_return
.Llightpoint_fullbright:
        movl    $255,%eax
.Llightpoint_return:
        leave
        ret
#endif
