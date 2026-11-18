/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// SCR_DrawNotifyString from screen.c, expressed as auditable i486 assembly.
//
// 32-bit DJGPP cdecl, no arguments or return value. The routine uses only
// i486 integer instructions and the original 387-compatible x87 path. It
// centers each line using the original unsigned vid.width arithmetic, scans
// at most 40 bytes for visible characters, then consumes the entire remainder
// of that source line before handling newline/NUL exactly as the C routine.
// Character bytes are sign-extended before Draw_Character, as in the pinned
// DJGPP C build. Original behavior: screen.c:SCR_DrawNotifyString.
#include "asm_i386.h"
#include "client/asm_screennotify.h"

#if defined(ASM486_SCREEN_NOTIFY)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(SCR_DrawNotifyString_asm486)
#ifdef ASM486_SCREEN_NOTIFY
.globl C(SCR_DrawNotifyString)
C(SCR_DrawNotifyString):
#endif
C(SCR_DrawNotifyString_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $16,%esp
// Locals: saved CW -14, truncate CW -16, y -20, visible line length -24.
    movl    C(scr_notifystring),%ebx

// C evaluates vid.height * 0.35 as an x87 product, then converts to int by
// truncating regardless of the incoming rounding mode. Keep multiplication
// under the caller's mode and change RC only for FISTP.
// FILD treats a 32-bit operand as signed. vid.height is unsigned, so add 2^32
// when its high bit is set. Temporarily select extended precision for that
// exact integer add, preserving caller RC; restore the full CW before multiply.
    movl    C(vid)+sn_vid_height_offset,%eax
    fildl   C(vid)+sn_vid_height_offset
    testl   %eax,%eax
    jns     .Lscreen_notify_height_unsigned
    fnstcw  -14(%ebp)
    movw    -14(%ebp),%ax
    orw     $0x0300,%ax
    movw    %ax,-16(%ebp)
    fldcw   -16(%ebp)
    faddl   .Lscreen_notify_two_32
    fldcw   -14(%ebp)
.Lscreen_notify_height_unsigned:
    fmull   .Lscreen_notify_point_35
    fnstcw  -14(%ebp)
    movw    -14(%ebp),%ax
    orw     $0x0c00,%ax
    movw    %ax,-16(%ebp)
    fldcw   -16(%ebp)
    fistpl  -20(%ebp)
    fldcw   -14(%ebp)

.Lscreen_notify_line:
// C scans no farther than 40 bytes for a rendered line segment.
    xorl    %esi,%esi
.Lscreen_notify_scan:
    cmpl    $40,%esi
    jge     .Lscreen_notify_scan_done
    movb    (%ebx,%esi),%al
    testb   %al,%al
    je      .Lscreen_notify_scan_done
    cmpb    $10,%al
    je      .Lscreen_notify_scan_done
    incl    %esi
    jmp     .Lscreen_notify_scan

.Lscreen_notify_scan_done:
    movl    %esi,-24(%ebp)
// vid.width is unsigned: preserve modulo-2^32 subtraction and logical divide
// by two, including the large positive x produced when text exceeds the view.
    movl    C(vid)+sn_vid_width_offset,%edi
    leal    (,%esi,8),%eax
    subl    %eax,%edi
    shrl    $1,%edi
    xorl    %esi,%esi

.Lscreen_notify_draw:
    cmpl    -24(%ebp),%esi
    jge     .Lscreen_notify_draw_done
// char is signed in the selected DJGPP C build; Draw_Character masks to 8 bits.
    movsbl  (%ebx,%esi),%eax
    pushl   %eax
    pushl   -20(%ebp)
    pushl   %edi
#ifdef BENCH486
    cmpl    $0,C(bench486_screen_notify_fixture_active)
    je      .Lscreen_notify_real_character
    call    C(Bench486ScreenNotifyCharacter)
    jmp     .Lscreen_notify_character_call_done
.Lscreen_notify_real_character:
    call    C(Draw_Character)
.Lscreen_notify_character_call_done:
#else
    call    C(Draw_Character)
#endif
    addl    $12,%esp
    addl    $8,%edi
    incl    %esi
    jmp     .Lscreen_notify_draw

.Lscreen_notify_draw_done:
    addl    $8,-20(%ebp)

// The source walk is intentionally not limited to 40 bytes: C skips the
// undrawn suffix of an overlong line up to its newline or terminating NUL.
.Lscreen_notify_skip:
    movb    (%ebx),%al
    testb   %al,%al
    je      .Lscreen_notify_return
    cmpb    $10,%al
    je      .Lscreen_notify_newline
    incl    %ebx
    jmp     .Lscreen_notify_skip

.Lscreen_notify_newline:
    incl    %ebx
    jmp     .Lscreen_notify_line

.Lscreen_notify_return:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

.section .rodata
.align 8
.Lscreen_notify_point_35:
    .double 0.35
.Lscreen_notify_two_32:
    .double 4294967296.0
#endif
