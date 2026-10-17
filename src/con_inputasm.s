// Con_DrawInput from console.c, expressed as auditable i486 assembly.
//
// 32-bit DJGPP cdecl, no arguments or return value. Preserve EBX/ESI/EDI/EBP;
// EAX/ECX/EDX and x87 are scratch. The row stride and key_console enum value
// are pinned by asm_consoleinput.h. Draw_Character remains the selected
// drawing backend, so this module owns console input orchestration only.
//
// The cursor conversion follows the pinned GCC -march=i486 object exactly:
// load float con_cursorspeed, multiply by double realtime in x87 extended
// precision using the incoming rounding mode, then temporarily select
// round-toward-zero for FISTP and restore the caller's x87 control word.
// No FISTTP or post-486 instruction is used. Original C source:
// console.c:Con_DrawInput. GPL-2.0-or-later.
#include "asm_i386.h"
#include "asm_consoleinput.h"

#if defined(ASM486_CONSOLE_INPUT) || defined(BENCH486)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(Con_DrawInput_asm486)
#ifdef ASM486_CONSOLE_INPUT
.globl C(Con_DrawInput)
C(Con_DrawInput):
#endif
C(Con_DrawInput_asm486):
// The reference returns before touching input or framebuffer state when the
// game/menu owns the keyboard and the console is not forced up.
    cmpl    $ci_key_console,C(key_dest)
    je      .Lcon_input_visible
    cmpl    $0,C(con_forcedup)
    je      .Lcon_input_return

.Lcon_input_visible:
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $16,%esp
// Locals: cursor result -16; old/new x87 CW -18/-20; width -24; y -28.
    movl    C(edit_line),%eax
    shll    $8,%eax
    leal    C(key_lines)(%eax),%ebx
    movl    C(key_linepos),%esi

// Mirror the compiler-emitted C cast. Multiplication precedes the temporary
// truncation mode, preserving the caller's rounding mode for the product.
    flds    C(con_cursorspeed)
    fmull   C(realtime)
    fnstcw  -18(%ebp)
    movw    -18(%ebp),%ax
    orw     $0x0c00,%ax
    movw    %ax,-20(%ebp)
    fldcw   -20(%ebp)
    fistpl  -16(%ebp)
    fldcw   -18(%ebp)
    movl    -16(%ebp),%eax
    andl    $1,%eax
    addl    $10,%eax
    movb    %al,(%ebx,%esi)

// Leave the spaces written by C and use its signed int loop bounds.
    movl    C(con_linewidth),%eax
    movl    %eax,-24(%ebp)
    leal    1(%esi),%ecx
.Lcon_input_blank:
    cmpl    -24(%ebp),%ecx
    jge     .Lcon_input_blank_done
    movb    $32,(%ebx,%ecx)
    incl    %ecx
    jmp     .Lcon_input_blank

.Lcon_input_blank_done:
// Horizontal scroll starts at 1 + key_linepos - con_linewidth when needed.
    movl    %ebx,%edi
    movl    %esi,%eax
    cmpl    -24(%ebp),%eax
    jl      .Lcon_input_unscrolled
    subl    -24(%ebp),%eax
    incl    %eax
    addl    %eax,%edi
.Lcon_input_unscrolled:
    movl    C(con_vislines),%eax
    subl    $16,%eax
    movl    %eax,-28(%ebp)
    xorl    %esi,%esi
.Lcon_input_draw:
    cmpl    -24(%ebp),%esi
    jge     .Lcon_input_draw_done
// C char is signed in this DJGPP build; Draw_Character masks to 8 bits.
    movsbl  (%edi,%esi),%eax
    pushl   %eax
    pushl   -28(%ebp)
    leal    8(,%esi,8),%eax
    pushl   %eax
    call    C(Draw_Character)
    addl    $12,%esp
    incl    %esi
    jmp     .Lcon_input_draw

.Lcon_input_draw_done:
// C clears the original cursor cell but retains the blanked tail.
    movl    C(key_linepos),%eax
    movb    $0,(%ebx,%eax)
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

.Lcon_input_return:
    ret

// Con_DrawConsole from console.c, with the C body retained as the BENCH oracle.
// The public selector is paired with ConsoleImplementation so the entire
// console draw orchestration follows the same C/assembly profile choice.
#if defined(ASM486_CONSOLE_DRAW) || defined(BENCH486)
.globl C(Con_DrawConsole_asm486)
#ifdef ASM486_CONSOLE_DRAW
.globl C(Con_DrawConsole)
C(Con_DrawConsole):
#endif
C(Con_DrawConsole_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $8,%esp
// Locals: x -16; text -20. Callee-saved registers hold rows, y and i.
    cmpl    $0,8(%ebp)
    jle     .Lcon_drawconsole_done

// Draw_ConsoleBackground(lines).
    pushl   8(%ebp)
    call    C(Draw_ConsoleBackground)
    addl    $4,%esp

// con_vislines = lines;
    movl    8(%ebp),%eax
    movl    %eax,C(con_vislines)

// rows = (lines - 16) >> 3; y = lines - 16 - (rows << 3).
    subl    $16,%eax
    movl    %eax,%esi
    sarl    $3,%eax
    movl    %eax,%ebx
    sall    $3,%eax
    subl    %eax,%esi

// i = con_current - rows + 1.
    movl    C(con_current),%edi
    subl    %ebx,%edi
    incl    %edi

.Lcon_drawconsole_outer:
    cmpl    C(con_current),%edi
    jg      .Lcon_drawconsole_input

// j = max(i - con_backscroll, 0); use C's signed remainder for the ring row.
    movl    %edi,%eax
    subl    C(con_backscroll),%eax
    testl   %eax,%eax
    jge     .Lcon_drawconsole_nonnegative
    xorl    %eax,%eax
.Lcon_drawconsole_nonnegative:
    cdq
    idivl   C(con_totallines)
    imull   C(con_linewidth),%edx
    addl    C(con_text),%edx
    movl    %edx,-20(%ebp)
    movl    $0,-16(%ebp)

.Lcon_drawconsole_inner:
    movl    -16(%ebp),%eax
    cmpl    C(con_linewidth),%eax
    jge     .Lcon_drawconsole_inner_done

// Draw_Character((x + 1) << 3, y, text[x]); DJGPP treats plain char as signed.
    movl    -20(%ebp),%eax
    movl    -16(%ebp),%ecx
    movsbl  (%eax,%ecx),%eax
    pushl   %eax
    pushl   %esi
    leal    8(,%ecx,8),%eax
    pushl   %eax
    call    C(Draw_Character)
    addl    $12,%esp
    incl    -16(%ebp)
    jmp     .Lcon_drawconsole_inner

.Lcon_drawconsole_inner_done:
    addl    $8,%esi
    incl    %edi
    jmp     .Lcon_drawconsole_outer

.Lcon_drawconsole_input:
    cmpl    $0,12(%ebp)
    je      .Lcon_drawconsole_done
    call    C(Con_DrawInput)

.Lcon_drawconsole_done:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret
#endif
#endif
