/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
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
#include "client/asm_consoleinput.h"
#include "client/asm_consoleoutput.h"

#if defined(ASM486_CONSOLE_INPUT) || defined(BENCH486)
.arch i486
.arch .387
.code32

#if defined(BENCH486)
#define CON_PRINT_LOCAL_SOUND C(Bench486ConPrintSound)
#define CON_OUTPUT_OPEN C(Bench486ConsoleOutputOpen)
#define CON_OUTPUT_WRITE C(Bench486ConsoleOutputWrite)
#define CON_OUTPUT_CLOSE C(Bench486ConsoleOutputClose)
#define CON_OUTPUT_SYS_PRINTF C(Bench486ConsoleOutputSysPrintf)
#define CON_OUTPUT_UPDATE_SCREEN C(Bench486ConsoleOutputUpdateScreen)
#ifdef ASM486_CONSOLE_INPUT
#define CON_OUTPUT_CON_PRINT C(Con_Print_asm486)
#else
#define CON_OUTPUT_CON_PRINT C(Con_Print)
#endif
#else
#define CON_PRINT_LOCAL_SOUND C(S_LocalSound)
#define CON_OUTPUT_OPEN C(open)
#define CON_OUTPUT_WRITE C(write)
#define CON_OUTPUT_CLOSE C(close)
#define CON_OUTPUT_SYS_PRINTF C(Sys_Printf)
#define CON_OUTPUT_UPDATE_SCREEN C(SCR_UpdateScreen)
#define CON_OUTPUT_CON_PRINT C(Con_Print_asm486)
#endif

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

// Con_DrawNotify from console.c. Preserve its x87 comparisons and the cursor's
// truncating FISTP conversion while keeping all drawing calls on public paths.
#if defined(ASM486_CONSOLE_NOTIFY) || defined(BENCH486)
.globl C(Con_DrawNotify_asm486)
#ifdef ASM486_CONSOLE_NOTIFY
.globl C(Con_DrawNotify)
C(Con_DrawNotify):
#endif
C(Con_DrawNotify_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $12,%esp
// Locals: current notification index -16; cursor int -20; x87 CWs -22/-24.
    movl    C(con_current),%eax
    subl    $3,%eax
    movl    %eax,-16(%ebp)
    xorl    %esi,%esi

.Lcon_notify_outer:
    movl    -16(%ebp),%eax
    cmpl    C(con_current),%eax
    jg      .Lcon_notify_chat
    testl   %eax,%eax
    js      .Lcon_notify_advance

// The four-slot timestamp ring is indexed by i & 3. Discard the loaded zero
// timestamp exactly as the compiler's FTST path does.
    movl    %eax,%edx
    andl    $3,%edx
    flds    C(con_times)(,%edx,4)
    ftst
    fnstsw  %ax
    testb   $64,%ah
    jne     .Lcon_notify_zero_time

// Match the C expression realtime - float_timestamp and its float cvar compare.
    fldl    C(realtime)
    fsubp   %st,%st(1)
    fcomps  C(con_notifytime)+16
    fnstsw  %ax
// Only the greater-than condition skips; equal and unordered still draw.
    testb   $69,%ah
    je      .Lcon_notify_advance

    movl    C(con_text),%edi
    movl    -16(%ebp),%eax
    cdq
    idivl   C(con_totallines)
    imull   C(con_linewidth),%edx
    addl    %edx,%edi
    movl    $0,C(clearnotify)
    movl    $1,C(scr_copytop)
    xorl    %ebx,%ebx

.Lcon_notify_glyph:
    cmpl    C(con_linewidth),%ebx
    jge     .Lcon_notify_line_done
    movsbl  (%edi,%ebx),%eax
    pushl   %eax
    pushl   %esi
    leal    8(,%ebx,8),%eax
    pushl   %eax
    call    C(Draw_Character)
    addl    $12,%esp
    incl    %ebx
    jmp     .Lcon_notify_glyph

.Lcon_notify_zero_time:
    fstp    %st(0)
.Lcon_notify_advance:
    incl    -16(%ebp)
    jmp     .Lcon_notify_outer

.Lcon_notify_line_done:
    addl    $8,%esi
    incl    -16(%ebp)
    jmp     .Lcon_notify_outer

.Lcon_notify_chat:
    cmpl    $ci_key_message,C(key_dest)
    jne     .Lcon_notify_finish
    movl    $0,C(clearnotify)
    movl    $1,C(scr_copytop)
    pushl   $.Lcon_drawnotify_say
    pushl   %esi
    pushl   $8
    call    C(Draw_String)
    addl    $12,%esp
    xorl    %ebx,%ebx

.Lcon_notify_chat_glyph:
    movsbl  C(chat_buffer)(,%ebx),%eax
    testl   %eax,%eax
    je      .Lcon_notify_cursor
    pushl   %eax
    pushl   %esi
    leal    40(,%ebx,8),%eax
    pushl   %eax
    call    C(Draw_Character)
    addl    $12,%esp
    incl    %ebx
    jmp     .Lcon_notify_chat_glyph

.Lcon_notify_cursor:
// The product uses the caller's rounding mode; FISTP then truncates toward zero.
    flds    C(con_cursorspeed)
    fmull   C(realtime)
    fnstcw  -22(%ebp)
    movw    -22(%ebp),%ax
    orw     $0x0c00,%ax
    movw    %ax,-24(%ebp)
    fldcw   -24(%ebp)
    fistpl  -20(%ebp)
    fldcw   -22(%ebp)
    movl    -20(%ebp),%eax
    andl    $1,%eax
    addl    $10,%eax
    pushl   %eax
    pushl   %esi
    leal    40(,%ebx,8),%eax
    pushl   %eax
    call    C(Draw_Character)
    addl    $12,%esp
    addl    $8,%esi

.Lcon_notify_finish:
    cmpl    C(con_notifylines),%esi
    jle     .Lcon_notify_done
    movl    %esi,C(con_notifylines)

.Lcon_notify_done:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret
#endif

// Con_Linefeed and Con_Print from console.c, with the C paths retained for
// BENCH parity. Con_Print owns wrapping, carriage-return state, color markers,
// scrollback writes and notify timestamps; Con_Linefeed owns ring-row advance
// and clearing. Both use signed 32-bit C remainder semantics on i486.
#if defined(ASM486_CONSOLE_INPUT) || defined(BENCH486)
.text
.p2align 4,,15
.globl C(Con_Linefeed_asm486)
#ifdef ASM486_CONSOLE_INPUT
.globl C(Con_Linefeed)
C(Con_Linefeed):
#endif
C(Con_Linefeed_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    movl    $0,C(con_x)
    incl    C(con_current)
    movl    C(con_current),%eax
    cltd
    idivl   C(con_totallines)
    movl    C(con_text),%edi
    imull   C(con_linewidth),%edx
    leal    (%edi,%edx),%edi
    xorl    %esi,%esi
.Lcon_linefeed_clear:
    cmpl    C(con_linewidth),%esi
    jge     .Lcon_linefeed_done
    movb    $32,(%edi,%esi)
    incl    %esi
    jmp     .Lcon_linefeed_clear
.Lcon_linefeed_done:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

.p2align 4,,15
.globl C(Con_Print_asm486)
#ifdef ASM486_CONSOLE_INPUT
.globl C(Con_Print)
C(Con_Print):
#endif
C(Con_Print_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $8,%esp
    movl    8(%ebp),%esi
    movl    $0,C(con_backscroll)
    xorl    %ebx,%ebx
    movsbl  (%esi),%eax
    cmpl    $1,%eax
    je      .Lcon_print_talk
    cmpl    $2,%eax
    jne     .Lcon_print_loop
    movl    $128,%ebx
    incl    %esi
    jmp     .Lcon_print_loop
.Lcon_print_talk:
    movl    $128,%ebx
    pushl   $.Lcon_print_talk_sound
    call    CON_PRINT_LOCAL_SOUND
    addl    $4,%esp
    incl    %esi

.Lcon_print_loop:
    movsbl  (%esi),%edi
    testl   %edi,%edi
    je      .Lcon_print_done

    // l = first whitespace offset, capped at con_linewidth.
    xorl    %edx,%edx
    movl    C(con_linewidth),%ecx
.Lcon_print_word_length:
    cmpl    %ecx,%edx
    jge     .Lcon_print_word_length_done
    cmpb    $32,(%esi,%edx)
    jle     .Lcon_print_word_length_done
    incl    %edx
    jmp     .Lcon_print_word_length
.Lcon_print_word_length_done:
    cmpl    %ecx,%edx
    je      .Lcon_print_word_fits
    movl    C(con_x),%eax
    addl    %edx,%eax
    cmpl    %ecx,%eax
    jle     .Lcon_print_word_fits
    movl    $0,C(con_x)
.Lcon_print_word_fits:
    incl    %esi

    cmpl    $0,C(con_print_cr_asm486)
    je      .Lcon_print_carriage_done
    decl    C(con_current)
    movl    $0,C(con_print_cr_asm486)
.Lcon_print_carriage_done:
    cmpl    $0,C(con_x)
    jne     .Lcon_print_have_line
    call    C(Con_Linefeed)
    cmpl    $0,C(con_current)
    jl      .Lcon_print_have_line
    movl    C(con_current),%eax
    andl    $ci_num_con_times-1,%eax
    fldl    C(realtime)
    fstps   C(con_times)(,%eax,4)
.Lcon_print_have_line:
    cmpl    $10,%edi
    je      .Lcon_print_newline
    cmpl    $13,%edi
    je      .Lcon_print_carriage_return

    // y = con_current % con_totallines; store the low byte of c | mask.
    movl    C(con_current),%eax
    cltd
    idivl   C(con_totallines)
    imull   C(con_linewidth),%edx
    addl    C(con_x),%edx
    movl    C(con_text),%ecx
    movl    %edi,%eax
    orb     %bl,%al
    movb    %al,(%ecx,%edx)
    incl    C(con_x)
    movl    C(con_x),%eax
    cmpl    C(con_linewidth),%eax
    jl      .Lcon_print_loop
    movl    $0,C(con_x)
    jmp     .Lcon_print_loop

.Lcon_print_newline:
    movl    $0,C(con_x)
    jmp     .Lcon_print_loop
.Lcon_print_carriage_return:
    movl    $0,C(con_x)
    movl    $1,C(con_print_cr_asm486)
    jmp     .Lcon_print_loop

.Lcon_print_done:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

// Con_DebugLog from console.c. Keep its legacy static-buffer behavior and
// unchecked open/write/close sequence; BENCH substitutes event-capture I/O.
.p2align 4,,15
.globl C(Con_DebugLog_asm486)
#ifdef ASM486_CONSOLE_INPUT
.globl C(Con_DebugLog)
C(Con_DebugLog):
#if defined(BENCH486)
    jmp     C(Con_DebugLog_Console_C)
#endif
#endif
C(Con_DebugLog_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $8,%esp
    leal    16(%ebp),%eax
    pushl   %eax
    pushl   12(%ebp)
    pushl   $.Lcon_debuglog_data_asm486
    call    C(vsprintf)
    addl    $12,%esp

    pushl   $co_open_mode
    pushl   $co_open_flags
    pushl   8(%ebp)
    call    CON_OUTPUT_OPEN
    addl    $12,%esp
    movl    %eax,-16(%ebp)

    pushl   $.Lcon_debuglog_data_asm486
    call    C(strlen)
    addl    $4,%esp
    movl    %eax,-20(%ebp)
    pushl   -20(%ebp)
    pushl   $.Lcon_debuglog_data_asm486
    pushl   -16(%ebp)
    call    CON_OUTPUT_WRITE
    addl    $12,%esp
    pushl   -16(%ebp)
    call    CON_OUTPUT_CLOSE
    addl    $4,%esp
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

// Con_Printf from console.c. The formatted message remains on this call's
// stack, matching the C routine's 4096-byte local buffer lifetime.
.p2align 4,,15
.globl C(Con_Printf_asm486)
#ifdef ASM486_CONSOLE_INPUT
.globl C(Con_Printf)
C(Con_Printf):
#if defined(BENCH486)
    jmp     C(Con_Printf_Console_C)
#endif
#endif
C(Con_Printf_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $co_max_print_message,%esp
    leal    12(%ebp),%eax
    pushl   %eax
    pushl   8(%ebp)
    leal    -4108(%ebp),%eax
    pushl   %eax
    call    C(vsprintf)
    addl    $12,%esp
    leal    -4108(%ebp),%esi

    pushl   %esi
    pushl   $.Lcon_output_percent_s
    call    CON_OUTPUT_SYS_PRINTF
    addl    $8,%esp

    cmpl    $0,C(con_debuglog)
    je      .Lcon_printf_no_log
    pushl   $C(com_gamedir)
    pushl   $.Lcon_output_log_path_format
    call    C(va)
    addl    $8,%esp
    movl    %eax,%edi
    pushl   %esi
    pushl   $.Lcon_output_percent_s
    pushl   %edi
    call    C(Con_DebugLog_asm486)
    addl    $12,%esp

.Lcon_printf_no_log:
    cmpl    $0,C(con_initialized)
    je      .Lcon_printf_done
    cmpl    $co_dedicated_state,C(cls)+co_client_state_offset
    je      .Lcon_printf_done
    pushl   %esi
    call    CON_OUTPUT_CON_PRINT
    addl    $4,%esp

    cmpl    $co_signons,C(cls)+co_client_signon_offset
    je      .Lcon_printf_done
    cmpl    $0,C(scr_disabled_for_loading)
    jne     .Lcon_printf_done
    cmpl    $0,C(con_printf_inupdate_asm486)
    jne     .Lcon_printf_done
    movl    $1,C(con_printf_inupdate_asm486)
    call    CON_OUTPUT_UPDATE_SCREEN
    movl    $0,C(con_printf_inupdate_asm486)

.Lcon_printf_done:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

// Con_DPrintf from console.c. The retained GCC -ffast-math C object tests only
// ZF after its x87 compare, so unordered values take the same return path as
// zero. FTST plus SAHF reproduces that flag behavior; pop the x87 value first.
.p2align 4,,15
.globl C(Con_DPrintf_asm486)
#ifdef ASM486_CONSOLE_INPUT
.globl C(Con_DPrintf)
C(Con_DPrintf):
#if defined(BENCH486)
    jmp     C(Con_DPrintf_Console_C)
#endif
#endif
C(Con_DPrintf_asm486):
    pushl   %ebp
    movl    %esp,%ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi
    subl    $co_max_print_message,%esp
    flds    C(developer)+co_cvar_value_offset
    ftst
    fnstsw  %ax
    fstp    %st(0)
    sahf
    jz      .Lcon_dprintf_done
.Lcon_dprintf_enabled:
    leal    12(%ebp),%eax
    pushl   %eax
    pushl   8(%ebp)
    leal    -4108(%ebp),%eax
    pushl   %eax
    call    C(vsprintf)
    addl    $12,%esp
    leal    -4108(%ebp),%eax
    pushl   %eax
    pushl   $.Lcon_output_percent_s
    call    C(Con_Printf_asm486)
    addl    $8,%esp
.Lcon_dprintf_done:
    leal    -12(%ebp),%esp
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret

.bss
.p2align 2
.globl C(con_print_cr_asm486)
C(con_print_cr_asm486):
    .long   0
.Lcon_debuglog_data_asm486:
    .space  co_debuglog_buffer_size
.p2align 2
.globl C(con_printf_inupdate_asm486)
C(con_printf_inupdate_asm486):
    .long   0

#endif

.section .rodata
.Lcon_drawnotify_say:
    .asciz  "say:"
.Lcon_print_talk_sound:
    .asciz  "misc/talk.wav"
.Lcon_output_percent_s:
    .asciz  "%s"
.Lcon_output_log_path_format:
    .asciz  "%s/qconsole.log"
.text
#undef CON_PRINT_LOCAL_SOUND
#undef CON_OUTPUT_OPEN
#undef CON_OUTPUT_WRITE
#undef CON_OUTPUT_CLOSE
#undef CON_OUTPUT_SYS_PRINTF
#undef CON_OUTPUT_UPDATE_SCREEN
#endif
