// Palette/gamma algorithms from view.c, kept in a separate auditable module.
// i486 DJGPP cdecl. Preserve EBX/ESI/EDI/EBP; scratch EAX/ECX/EDX, x87.
// Every entry leaves the x87 stack empty and preserves the control word.
// Original integer blend order and the C object's actual x87 store boundaries
// are retained. No alternate gamma approximation or added color clamp.
// pow is the same mechanically audited DJGPP runtime dependency as the oracle.
// GPL-2.0-or-later, following the original Quake implementation.
#include "asm_i386.h"
#include "asm_palette.h"
#if defined(ASM486_PALETTE) || defined(BENCH486)
        .bss
        .p2align 2
.Lpalette_oldgamma: .space 4
#ifdef BENCH486
        .globl C(bench486_palette_stack_failures)
C(bench486_palette_stack_failures): .space 4
        .globl C(bench486_gamma_before),C(gammatable),C(bench486_gamma_after)
C(bench486_gamma_before): .space 32
C(gammatable): .space 256
C(bench486_gamma_after): .space 32
#endif
        .data
        .p2align 2
.Lpalette_one:       .float 1
.Lpalette_half_f:    .float 0.5
.Lpalette_scale:     .float 255
.Lpalette_damage:    .float 150
.Lpalette_bonus:     .float 100
        .p2align 3
// Exact binary64 reciprocal used by the pinned C object for (i+.5)/255.5.
.Lpalette_recip:     .long 0x02010080,0x3f700804
.Lpalette_half_d:    .double 0.5
        .text
        .p2align 4,,15
        .globl C(BuildGammaTable_asm486)
#ifdef ASM486_PALETTE
        .globl C(BuildGammaTable)
C(BuildGammaTable):
#endif
C(BuildGammaTable_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        subl    $28,%esp
// Locals: exponent binary64 -16, index -20, integer result -24,
// truncate/original CW -28/-26. EBX is the palette index throughout.
        flds    8(%ebp)
        fcoms   .Lpalette_one
        fnstsw  %ax
        testb   $0x40,%ah                // C oracle tests C3 (including unordered)
        jnz     .Lgamma_identity
        fstpl   -16(%ebp)               // original exponent argument store
        xorl    %ebx,%ebx
.Lgamma_entry:
        subl    $16,%esp                // pow(binary64 base, binary64 exponent)
        movl    -16(%ebp),%eax
        movl    %eax,8(%esp)
        movl    -12(%ebp),%eax
        movl    %eax,12(%esp)
        movl    %ebx,-20(%ebp)
        flds    .Lpalette_half_f
        fiaddl  -20(%ebp)
        fmull   .Lpalette_recip
        fstpl   (%esp)                  // actual C binary64 argument boundary
        call    C(pow)
        addl    $16,%esp
        fmuls   .Lpalette_scale
        fldl    .Lpalette_half_d
        faddp   %st,%st(1)
        fnstcw  -26(%ebp)
        movw    -26(%ebp),%ax
        orw     $0x0c00,%ax
        movw    %ax,-28(%ebp)
        fldcw   -28(%ebp)
        fistpl  -24(%ebp)               // original truncate-to-int, no FISTTP
        fldcw   -26(%ebp)
        movl    -24(%ebp),%eax
        testl   %eax,%eax
        jns     .Lgamma_upper
        xorl    %eax,%eax
.Lgamma_upper:
        cmpl    $255,%eax
        jle     .Lgamma_store
        movl    $255,%eax
.Lgamma_store:
        movb    %al,C(gammatable)(%ebx)
        incl    %ebx
        cmpl    $256,%ebx
        jne     .Lgamma_entry
        jmp     .Lgamma_return
.Lgamma_identity:
        fstp    %st(0)
        xorl    %ebx,%ebx
.Lgamma_identity_entry:
        movb    %bl,C(gammatable)(%ebx)
        incl    %ebx
        cmpl    $256,%ebx
        jne     .Lgamma_identity_entry
.Lgamma_return:
        addl    $28,%esp
        popl    %ebx
        popl    %ebp
        ret

        .p2align 4,,15
        .globl C(V_CheckGamma_asm486)
#ifdef ASM486_PALETTE
        .globl C(V_CheckGamma)
C(V_CheckGamma):
#endif
C(V_CheckGamma_asm486):
        flds    C(v_gamma)+p_cvar_value
        fcoms   .Lpalette_oldgamma
        fnstsw  %ax
        testb   $0x40,%ah
        jnz     .Lgamma_unchanged
        fsts    .Lpalette_oldgamma
        subl    $4,%esp
        fstps   (%esp)
        call    C(BuildGammaTable_asm486)
        addl    $4,%esp
        movl    $1,C(vid)+p_vid_recalc
        movl    $1,%eax
        ret
.Lgamma_unchanged:
        fstp    %st(0)
        xorl    %eax,%eax
        ret

        .p2align 4,,15
        .globl C(V_SetContentsColor_asm486)
#ifdef ASM486_PALETTE
        .globl C(V_SetContentsColor)
C(V_SetContentsColor):
#endif
C(V_SetContentsColor_asm486):
        movl    4(%esp),%edx
        movl    $C(cshift_empty),%eax
        cmpl    $-1,%edx                // CONTENTS_EMPTY
        je      .Lcontents_copy
        cmpl    $-2,%edx                // CONTENTS_SOLID
        je      .Lcontents_copy
        movl    $C(cshift_lava),%eax
        cmpl    $-5,%edx
        je      .Lcontents_copy
        movl    $C(cshift_slime),%eax
        cmpl    $-4,%edx
        je      .Lcontents_copy
        movl    $C(cshift_water),%eax    // every other contents value
.Lcontents_copy:
        xorl    %ecx,%ecx
.Lcontents_word:
        movl    (%eax,%ecx),%edx
        movl    %edx,C(cl)+p_client_shifts(%ecx)
        addl    $4,%ecx
        cmpl    $p_shift_bytes,%ecx
        jne     .Lcontents_word
        ret

        .p2align 4,,15
        .globl C(V_CalcPowerupCshift_asm486)
#ifdef ASM486_PALETTE
        .globl C(V_CalcPowerupCshift)
C(V_CalcPowerupCshift):
#endif
C(V_CalcPowerupCshift_asm486):
        movl    C(cl)+p_client_items,%eax
        testl   $p_item_quad,%eax
        jz      .Lpowerup_suit
        movl    $0,C(cl)+p_client_shifts+48
        movl    $0,C(cl)+p_client_shifts+52
        movl    $255,C(cl)+p_client_shifts+56
        movl    $30,C(cl)+p_client_shifts+60
        ret
.Lpowerup_suit:
        testl   $p_item_suit,%eax
        jz      .Lpowerup_invisible
        movl    $0,C(cl)+p_client_shifts+48
        movl    $255,C(cl)+p_client_shifts+52
        movl    $0,C(cl)+p_client_shifts+56
        movl    $20,C(cl)+p_client_shifts+60
        ret
.Lpowerup_invisible:
        testl   $p_item_invisibility,%eax
        jz      .Lpowerup_invulnerable
        movl    $100,C(cl)+p_client_shifts+48
        movl    $100,C(cl)+p_client_shifts+52
        movl    $100,C(cl)+p_client_shifts+56
        movl    $100,C(cl)+p_client_shifts+60
        ret
.Lpowerup_invulnerable:
        testl   $p_item_invulnerability,%eax
        jz      .Lpowerup_none
        movl    $255,C(cl)+p_client_shifts+48
        movl    $255,C(cl)+p_client_shifts+52
        movl    $0,C(cl)+p_client_shifts+56
        movl    $30,C(cl)+p_client_shifts+60
        ret
.Lpowerup_none:
        movl    $0,C(cl)+p_client_shifts+60 // retain the old RGB values
        ret

        .p2align 4,,15
        .globl C(V_cshift_f_asm486)
#ifdef ASM486_PALETTE
        .globl C(V_cshift_f)
C(V_cshift_f):
#endif
C(V_cshift_f_asm486):
// V_cshift_f: store the same four atoi(Cmd_Argv(n)) results, in source order.
// Each helper call is cdecl; only caller-scratch EAX is used, preserving callee-saved registers.
        pushl   $1
        call    C(Cmd_Argv)
        addl    $4,%esp
        pushl   %eax
        call    C(atoi)
        addl    $4,%esp
        movl    %eax,C(cshift_empty)+p_shift_destcolor

        pushl   $2
        call    C(Cmd_Argv)
        addl    $4,%esp
        pushl   %eax
        call    C(atoi)
        addl    $4,%esp
        movl    %eax,C(cshift_empty)+p_shift_destcolor+4

        pushl   $3
        call    C(Cmd_Argv)
        addl    $4,%esp
        pushl   %eax
        call    C(atoi)
        addl    $4,%esp
        movl    %eax,C(cshift_empty)+p_shift_destcolor+8

        pushl   $4
        call    C(Cmd_Argv)
        addl    $4,%esp
        pushl   %eax
        call    C(atoi)
        addl    $4,%esp
        movl    %eax,C(cshift_empty)+p_shift_percent
        ret

        .p2align 4,,15
        .globl C(V_BonusFlash_asm486)
#ifdef ASM486_PALETTE
        .globl C(V_BonusFlash_f)
C(V_BonusFlash_f):
#endif
C(V_BonusFlash_asm486):
// V_BonusFlash_f: install the original pickup/bonus shift in cl.cshifts.
// Four integer stores preserve the exact C field values and touch no other state.
        movl    $215,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_destcolor
        movl    $186,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_destcolor+4
        movl    $69,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_destcolor+8
        movl    $50,C(cl)+p_client_shifts+p_shift_bonus*p_shift_bytes+p_shift_percent
        ret

        .p2align 4,,15
        .globl C(V_UpdatePalette_asm486)
#ifdef ASM486_PALETTE
        .globl C(V_UpdatePalette)
C(V_UpdatePalette):
#endif
C(V_UpdatePalette_asm486):
        pushl   %ebp
        movl    %esp,%ebp
        pushl   %ebx
        pushl   %esi
        pushl   %edi
        subl    $792,%esp
// Locals: changed -16; truncate/original CW -22/-24; channel offset -804.
// Palette is exactly 768 bytes at -796..-29; BENCH redzones -800 and -28.
#ifdef BENCH486
        movl    $0x486a1357,-800(%ebp)
        movl    $0x486b2468,-28(%ebp)
#endif
        call    C(V_CalcPowerupCshift_asm486)
        movl    $0,-16(%ebp)
        xorl    %ecx,%ecx
.Lpalette_compare_state:
        movl    C(cl)+p_client_shifts(%ecx),%eax
        cmpl    C(cl)+p_client_previous(%ecx),%eax
        je      .Lpalette_same_word
        movl    %eax,C(cl)+p_client_previous(%ecx)
        movl    $1,-16(%ebp)
.Lpalette_same_word:
        addl    $4,%ecx
        cmpl    $p_shift_count*p_shift_bytes,%ecx
        jne     .Lpalette_compare_state

// Compare/update previous state before the two decay conversions, as in C.
        fnstcw  -24(%ebp)
        movw    -24(%ebp),%ax
        orw     $0x0c00,%ax
        movw    %ax,-22(%ebp)
        fldl    C(host_frametime)
        fld     %st(0)
        fmuls   .Lpalette_damage
        fisubrl C(cl)+p_client_shifts+28
        fldcw   -22(%ebp)
        fistpl  C(cl)+p_client_shifts+28
        fldcw   -24(%ebp)
        cmpl    $0,C(cl)+p_client_shifts+28
        jge     .Lpalette_damage_done
        movl    $0,C(cl)+p_client_shifts+28
.Lpalette_damage_done:
        fmuls   .Lpalette_bonus
        fisubrl C(cl)+p_client_shifts+44
        fldcw   -22(%ebp)
        fistpl  C(cl)+p_client_shifts+44
        fldcw   -24(%ebp)
        cmpl    $0,C(cl)+p_client_shifts+44
        jge     .Lpalette_bonus_done
        movl    $0,C(cl)+p_client_shifts+44
.Lpalette_bonus_done:
        call    C(V_CheckGamma_asm486)
        orl     -16(%ebp),%eax
        jz      .Lpalette_return

        movl    C(host_basepal),%esi
        leal    -796(%ebp),%edi
        movl    $768,%ebx
        movl    $0,-804(%ebp)            // RGB field offsets 0,4,8 in each shift
.Lpalette_channel:
        movzbl  (%esi),%eax
        movl    $C(cl)+p_client_shifts,%edx
.Lpalette_blend:
        movl    -804(%ebp),%ecx
        movl    (%edx,%ecx),%ecx
        subl    %eax,%ecx
        imull   p_shift_percent(%edx),%ecx
        sarl    $8,%ecx                  // signed >>8, original 32-bit product
        addl    %ecx,%eax
        addl    $p_shift_bytes,%edx
        cmpl    $C(cl)+p_client_shifts+p_shift_count*p_shift_bytes,%edx
        jne     .Lpalette_blend
        movb    C(gammatable)(%eax),%al
        movb    %al,(%edi)
        incl    %esi
        incl    %edi
        addl    $4,-804(%ebp)
        cmpl    $12,-804(%ebp)
        jne     .Lpalette_next
        movl    $0,-804(%ebp)
.Lpalette_next:
        decl    %ebx
        jnz     .Lpalette_channel
        leal    -796(%ebp),%eax
        pushl   %eax
#ifdef BENCH486
        call    C(Bench486PaletteDispatch)
#else
        call    C(VID_ShiftPalette)
#endif
        addl    $4,%esp
.Lpalette_return:
#ifdef BENCH486
        cmpl    $0x486a1357,-800(%ebp)
        jne     .Lpalette_stack_bad
        cmpl    $0x486b2468,-28(%ebp)
        je      .Lpalette_stack_good
.Lpalette_stack_bad:
        incl    C(bench486_palette_stack_failures)
.Lpalette_stack_good:
#endif
        addl    $792,%esp
        popl    %edi
        popl    %esi
        popl    %ebx
        popl    %ebp
        ret

#ifdef BENCH486
// Exchange the independent persistent old-gamma word for oracle/soak fixtures.
        .p2align 4,,15
        .globl C(Bench486GammaState_asm486)
C(Bench486GammaState_asm486):
        movl    4(%esp),%edx
        cmpl    $0,8(%esp)
        jne     .Lgamma_state_restore
        movl    .Lpalette_oldgamma,%eax
        movl    %eax,(%edx)
        ret
.Lgamma_state_restore:
        movl    (%edx),%eax
        movl    %eax,.Lpalette_oldgamma
        ret
#endif
#endif
