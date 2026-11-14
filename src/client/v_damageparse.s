/*
 * V_ParseDamage, translated from view.c for the i486/387 renderer profile.
 *
 * Keep the statement order of the C reference: read the message, derive and
 * clamp the damage count, update the damage color shift, then derive the view
 * kick from the normalized damage direction and the player's current basis.
 * The MSG_Read* and math entry points remain explicit cdecl helpers.  Every
 * x87 value returned by a helper is consumed here, and the x87 stack is empty
 * at return.  EBX/ESI/EDI/EBP are preserved; EAX/ECX/EDX are scratch.
 *
 * The structure offsets below are deliberately named here.  The root task
 * will add C-side offsetof/sizeof assertions for every VDP_* structure
 * constant; do not silently change these when client/entity layouts move.
 * VDP_LOCAL_* names describe only this routine's private EBP stack frame.
 *
 * Only 386 integer instructions and 387 floating-point instructions are used.
 * In particular, float-to-int conversion uses FISTP with a temporary
 * round-toward-zero control word because C casts truncate on every caller
 * rounding mode.  The original control word is restored immediately.
 *
 * GPL-2.0-or-later, following the original Quake view.c implementation.
 */
#include "asm_i386.h"
#include "client/asm_vdamage.h"

#if defined(ASM486_V_PARSE_DAMAGE) || defined(BENCH486)

        .arch i486
        .arch .387
        .code32

/* EBP-relative locals. The frame reserves bytes through EBP-80. */
#define VDP_LOCAL_ARMOR               -16
#define VDP_LOCAL_BLOOD               -20
#define VDP_LOCAL_FROM                -32
#define VDP_LOCAL_COUNT               -36
#define VDP_LOCAL_CW_ORIGINAL         -42
#define VDP_LOCAL_CW_TRUNCATE         -44
#define VDP_LOCAL_FORWARD             -56
#define VDP_LOCAL_RIGHT               -68
#define VDP_LOCAL_UP                  -80

        .extern C(cl)
        .extern C(cl_entities)
        .extern C(v_kickroll)
        .extern C(v_kickpitch)
        .extern C(v_kicktime)
        .extern C(v_dmg_roll)
        .extern C(v_dmg_pitch)
        .extern C(v_dmg_time)
        .extern C(MSG_ReadByte)
        .extern C(MSG_ReadCoord)
        .extern C(VectorNormalize)
        .extern C(AngleVectors)

        .section .rodata
        .p2align 3
.Lvdp_half:     .double 0.5
.Lvdp_face_t:   .double 0.2
        .p2align 2
.Lvdp_ten:      .float 10.0
.Lvdp_three:    .float 3.0

        .text
        .p2align 4,,15
        .globl C(V_ParseDamage_asm486)
C(V_ParseDamage_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi
        subl    $68,%esp

/* Preserve the exact message helper order and its signed -1 error result. */
        call    C(MSG_ReadByte)
        movl    %eax,VDP_LOCAL_ARMOR(%ebp)
        call    C(MSG_ReadByte)
        movl    %eax,VDP_LOCAL_BLOOD(%ebp)
        call    C(MSG_ReadCoord)
        fstps   VDP_LOCAL_FROM(%ebp)
        call    C(MSG_ReadCoord)
        fstps   VDP_LOCAL_FROM+4(%ebp)
        call    C(MSG_ReadCoord)
        fstps   VDP_LOCAL_FROM+8(%ebp)

/* count = blood*0.5 + armor*0.5; assignment to float is the store below. */
        fildl   VDP_LOCAL_BLOOD(%ebp)
        fmull   .Lvdp_half
        fildl   VDP_LOCAL_ARMOR(%ebp)
        fmull   .Lvdp_half
        faddp   %st(0),%st(1)
        fstps   VDP_LOCAL_COUNT(%ebp)

/* C's ordered comparison is false for unordered values, as is this sequence. */
        flds    VDP_LOCAL_COUNT(%ebp)
        fcomps  .Lvdp_ten
        fnstsw  %ax
        sahf
        jp      .Lvdp_count_ready
        jnb     .Lvdp_count_ready
        flds    .Lvdp_ten
        fstps   VDP_LOCAL_COUNT(%ebp)
.Lvdp_count_ready:

/* cl.time is double; match C's double addition before the float assignment. */
        fldl    C(cl)+VDP_CLIENT_TIME
        fldl    .Lvdp_face_t
        faddp   %st(0),%st(1)
        fstps   C(cl)+VDP_CLIENT_FACEANIMTIME

/*
 * The C compound assignment converts percent to float, computes 3*count,
 * adds, then converts the result back to int.  FISTP's temporary CW makes the
 * final conversion obey C truncation even if the caller selected another x87
 * rounding mode; its original CW is restored before any following work.
 */
        fildl   C(cl)+VDP_CLIENT_DAMAGE_PERCENT
        flds    VDP_LOCAL_COUNT(%ebp)
        fmuls   .Lvdp_three
        faddp   %st(0),%st(1)
        fnstcw  VDP_LOCAL_CW_ORIGINAL(%ebp)
        movw    VDP_LOCAL_CW_ORIGINAL(%ebp),%ax
        andw    $0xf3ff,%ax
        orw     $0x0c00,%ax
        movw    %ax,VDP_LOCAL_CW_TRUNCATE(%ebp)
        fldcw   VDP_LOCAL_CW_TRUNCATE(%ebp)
        fistpl  C(cl)+VDP_CLIENT_DAMAGE_PERCENT
        fldcw   VDP_LOCAL_CW_ORIGINAL(%ebp)

        cmpl    $0,C(cl)+VDP_CLIENT_DAMAGE_PERCENT
        jge     .Lvdp_percent_nonnegative
        movl    $0,C(cl)+VDP_CLIENT_DAMAGE_PERCENT
.Lvdp_percent_nonnegative:
        cmpl    $150,C(cl)+VDP_CLIENT_DAMAGE_PERCENT
        jle     .Lvdp_percent_ready
        movl    $150,C(cl)+VDP_CLIENT_DAMAGE_PERCENT
.Lvdp_percent_ready:

/* Retain all three integer palette channels and the original branch order. */
        movl    VDP_LOCAL_ARMOR(%ebp),%eax
        cmpl    VDP_LOCAL_BLOOD(%ebp),%eax
        jg      .Lvdp_armor_dominates
        testl   %eax,%eax
        jne     .Lvdp_mixed_damage
        movl    $255,C(cl)+VDP_CLIENT_DAMAGE_COLOR
        movl    $0,C(cl)+VDP_CLIENT_DAMAGE_COLOR+4
        movl    $0,C(cl)+VDP_CLIENT_DAMAGE_COLOR+8
        jmp     .Lvdp_color_ready
.Lvdp_mixed_damage:
        movl    $220,C(cl)+VDP_CLIENT_DAMAGE_COLOR
        movl    $50,C(cl)+VDP_CLIENT_DAMAGE_COLOR+4
        movl    $50,C(cl)+VDP_CLIENT_DAMAGE_COLOR+8
        jmp     .Lvdp_color_ready
.Lvdp_armor_dominates:
        movl    $200,C(cl)+VDP_CLIENT_DAMAGE_COLOR
        movl    $100,C(cl)+VDP_CLIENT_DAMAGE_COLOR+4
        movl    $100,C(cl)+VDP_CLIENT_DAMAGE_COLOR+8
.Lvdp_color_ready:

/* ent = &cl_entities[cl.viewentity]; preserve C's unchecked array indexing. */
        movl    C(cl)+VDP_CLIENT_VIEWENTITY,%eax
        imull   $VDP_ENTITY_SIZE,%eax,%eax
        leal    C(cl_entities)(%eax),%edi

/* from -= ent->origin, storing each vec3_t result as a C float assignment. */
        flds    VDP_LOCAL_FROM(%ebp)
        fsubs   VDP_ENTITY_ORIGIN(%edi)
        fstps   VDP_LOCAL_FROM(%ebp)
        flds    VDP_LOCAL_FROM+4(%ebp)
        fsubs   VDP_ENTITY_ORIGIN+4(%edi)
        fstps   VDP_LOCAL_FROM+4(%ebp)
        flds    VDP_LOCAL_FROM+8(%ebp)
        fsubs   VDP_ENTITY_ORIGIN+8(%edi)
        fstps   VDP_LOCAL_FROM+8(%ebp)

/* VectorNormalize returns the original length in ST(0); C discards it. */
        leal    VDP_LOCAL_FROM(%ebp),%eax
        pushl   %eax
        call    C(VectorNormalize)
        addl    $4,%esp
        fstp    %st(0)

/* C uses three local vectors here; keep those results private to this call. */
        leal    VDP_LOCAL_UP(%ebp),%eax
        pushl   %eax
        leal    VDP_LOCAL_RIGHT(%ebp),%eax
        pushl   %eax
        leal    VDP_LOCAL_FORWARD(%ebp),%eax
        pushl   %eax
        leal    VDP_ENTITY_ANGLES(%edi),%eax
        pushl   %eax
        call    C(AngleVectors)
        addl    $16,%esp

/* DotProduct(from,right), left-to-right; keep GCC's extended x87 value live. */
        flds    VDP_LOCAL_FROM(%ebp)
        fmuls   VDP_LOCAL_RIGHT(%ebp)
        flds    VDP_LOCAL_FROM+4(%ebp)
        fmuls   VDP_LOCAL_RIGHT+4(%ebp)
        faddp   %st(0),%st(1)
        flds    VDP_LOCAL_FROM+8(%ebp)
        fmuls   VDP_LOCAL_RIGHT+8(%ebp)
        faddp   %st(0),%st(1)

/* Match the current C x87 sequence: side*kickroll, then multiply by count. */
        fmuls   C(v_kickroll)+VDP_CVAR_VALUE
        fmuls   VDP_LOCAL_COUNT(%ebp)
        fstps   C(v_dmg_roll)

/* Recompute DotProduct(from,forward) with the same live x87 precision. */
        flds    VDP_LOCAL_FROM(%ebp)
        fmuls   VDP_LOCAL_FORWARD(%ebp)
        flds    VDP_LOCAL_FROM+4(%ebp)
        fmuls   VDP_LOCAL_FORWARD+4(%ebp)
        faddp   %st(0),%st(1)
        flds    VDP_LOCAL_FROM+8(%ebp)
        fmuls   VDP_LOCAL_FORWARD+8(%ebp)
        faddp   %st(0),%st(1)

/* Match C's pitch multiply order; time copies the cvar float unchanged. */
        fmuls   C(v_kickpitch)+VDP_CVAR_VALUE
        fmuls   VDP_LOCAL_COUNT(%ebp)
        fstps   C(v_dmg_pitch)
        movl    C(v_kicktime)+VDP_CVAR_VALUE,%eax
        movl    %eax,C(v_dmg_time)

        addl    $68,%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret

#endif /* ASM486_V_PARSE_DAMAGE || BENCH486 */
