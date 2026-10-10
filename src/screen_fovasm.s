// i486 x87 translation of screen.c:CalcFov (the selected GCC 12.2 -O3 path).
// Keep the binary32 constants and operation order used by the C reference:
// fov * (1/360f) * pi, FPTAN, width/tan, height/x, FPATAN, *360f, *(1/pi).
// The x87 stack retains intermediates just as the reference does; no newer
// instructions, C math helpers, or caller control-word changes are used.
#include "asm_i386.h"

#if defined(ASM486_VIEW_CONTROL)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(CalcFov_asm486)
C(CalcFov_asm486):
    // Match the reference's 12-byte local area, which leaves cdecl inputs at
    // 16/20/24(%esp) and keeps the same stack shape through the error call.
    subl    $12,%esp
    flds    16(%esp)
    fcoms   .Lcalc_fov_one
    fnstsw  %ax
    testb   $1,%ah
    jne     .Lcalc_fov_error
    fcoms   .Lcalc_fov_max
    fnstsw  %ax
    testb   $69,%ah
    jne     .Lcalc_fov_valid

.Lcalc_fov_error:
    // Sys_Error is normally non-returning. Preserve the reference's promoted
    // double argument and its reload if a BENCH486 capture hook returns.
    subl    $12,%esp
    fld     %st(0)
    fstps   28(%esp)
    fstpl   (%esp)
    pushl   $.Lcalc_fov_bad_message
#ifdef BENCH486
    call    C(Bench486CalcFovSysError)
#else
    call    C(Sys_Error)
#endif
    addl    $16,%esp
    flds    16(%esp)

.Lcalc_fov_valid:
    fmuls   .Lcalc_fov_recip_360
    fldl    .Lcalc_fov_pi
    fmulp   %st,%st(1)
    fptan
    fxch    %st(1)
    fdivrs  20(%esp)
    fdivrs  24(%esp)
    fxch    %st(1)
    fpatan
    fmuls   .Lcalc_fov_360
    fldl    .Lcalc_fov_recip_pi
    fmulp   %st,%st(1)
    addl    $12,%esp
    ret

.section .rodata
.p2align 3
.Lcalc_fov_pi:
    .long   1413754136
    .long   1074340347
.Lcalc_fov_recip_pi:
    .long   1841940611
    .long   1070882608
.p2align 2
.Lcalc_fov_one:
    .long   1065353216
.Lcalc_fov_max:
    .long   1127415808
.Lcalc_fov_recip_360:
    .long   993397601
.Lcalc_fov_360:
    .long   1135869952
.Lcalc_fov_bad_message:
    .asciz  "Bad fov: %f"
#endif
