// SCR_SetUpToDrawConsole from screen.c, expressed as auditable i486 + 387 code.
//
// 32-bit DJGPP cdecl, no arguments or return value. The C-compatible public
// entry first checks console sizing and the loading plaque, then updates the
// animated console height and the two page-clear counters. FISTP is used only
// with RC temporarily set to chop so (int)scr_con_current remains truncation
// toward zero under every caller rounding mode. The full CW is restored.
// Original behavior: screen.c:SCR_SetUpToDrawConsole.
#include "asm_i386.h"
#include "asm_screenconsolesetup.h"

#if defined(ASM486_SCREEN_CONSOLE_SETUP)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(SCR_SetUpToDrawConsole)
.globl C(SCR_SetUpToDrawConsole_asm486)
C(SCR_SetUpToDrawConsole):
C(SCR_SetUpToDrawConsole_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$16,%esp
// Locals: unsigned height widened to qword -8..-1, caller CW -10,
// truncate CW -12, and the converted tile Y -16.
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_console_setup_fixture_active)
	je	.Lscreen_console_setup_real_resize
	call	C(Bench486ScreenConsoleSetupCheckResize)
	jmp	.Lscreen_console_setup_resize_done
.Lscreen_console_setup_real_resize:
	call	C(Con_CheckResize)
.Lscreen_console_setup_resize_done:
#else
	call	C(Con_CheckResize)
#endif
	cmpl	$0,C(scr_drawloading)
	jne	.Lscreen_console_setup_done

// con_forcedup = !cl.worldmodel || cls.signon != SIGNONS.
	cmpl	$0,C(cl)+scs_cl_worldmodel_offset
	je	.Lscreen_console_setup_forced
	cmpl	$scs_signons,C(cls)+scs_cls_signon_offset
	jne	.Lscreen_console_setup_forced
	movl	$0,C(con_forcedup)
	jmp	.Lscreen_console_setup_choose_height

.Lscreen_console_setup_forced:
	movl	$1,C(con_forcedup)

.Lscreen_console_setup_choose_height:
	cmpl	$0,C(con_forcedup)
	je	.Lscreen_console_setup_not_forced

// vid.height is unsigned; zero-extend to a signed qword for FILDQ.
	movl	C(vid)+scs_vid_height_offset,%eax
	movl	%eax,-8(%ebp)
	movl	$0,-4(%ebp)
	fildq	-8(%ebp)
	fstps	C(scr_conlines)
	movl	C(scr_conlines),%eax
	movl	%eax,C(scr_con_current)
	jmp	.Lscreen_console_setup_clear_pages

.Lscreen_console_setup_not_forced:
	cmpl	$scs_key_console,C(key_dest)
	jne	.Lscreen_console_setup_closed

// C evaluates unsigned vid.height / 2 before converting that integer to float.
	movl	C(vid)+scs_vid_height_offset,%eax
	shrl	$1,%eax
	movl	%eax,-8(%ebp)
	movl	$0,-4(%ebp)
	fildq	-8(%ebp)
	fstps	C(scr_conlines)
	jmp	.Lscreen_console_setup_animate

.Lscreen_console_setup_closed:
	movl	$0,C(scr_conlines)

.Lscreen_console_setup_animate:
// Compare lines against current. FCOMPP plus SAHF is available on a 486;
// check PF first so unordered values do not become a false less-than.
	flds	C(scr_con_current)
	flds	C(scr_conlines)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lscreen_console_setup_check_rising
	jb	.Lscreen_console_setup_falling

.Lscreen_console_setup_check_rising:
	flds	C(scr_con_current)
	flds	C(scr_conlines)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lscreen_console_setup_clear_pages
	ja	.Lscreen_console_setup_rising
	jmp	.Lscreen_console_setup_clear_pages

.Lscreen_console_setup_falling:
// Match the C compound assignment: current - speed * frame time, stored to float.
	flds	C(scr_con_current)
	fldl	C(host_frametime)
	fmuls	C(scr_conspeed)+scs_scr_conspeed_value_offset
	fchs
	faddp	%st,%st(1)
	fstps	C(scr_con_current)

// Clamp a downward step when the old target is now above the new current.
	flds	C(scr_con_current)
	flds	C(scr_conlines)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lscreen_console_setup_clear_pages
	ja	.Lscreen_console_setup_clamp
	jmp	.Lscreen_console_setup_clear_pages

.Lscreen_console_setup_rising:
// Match current + speed * frame time, retaining the original x87 intermediates.
	flds	C(scr_con_current)
	fldl	C(host_frametime)
	fmuls	C(scr_conspeed)+scs_scr_conspeed_value_offset
	faddp	%st,%st(1)
	fstps	C(scr_con_current)

// Clamp an upward step when the new current has crossed the target.
	flds	C(scr_con_current)
	flds	C(scr_conlines)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lscreen_console_setup_clear_pages
	jb	.Lscreen_console_setup_clamp
	jmp	.Lscreen_console_setup_clear_pages

.Lscreen_console_setup_clamp:
	movl	C(scr_conlines),%eax
	movl	%eax,C(scr_con_current)

.Lscreen_console_setup_clear_pages:
// Preserve the old post-increment values and strict signed comparisons.
	movl	C(clearconsole),%eax
	incl	C(clearconsole)
	cmpl	C(vid)+scs_vid_numpages_offset,%eax
	jl	.Lscreen_console_setup_clear_bottom

	movl	C(clearnotify),%eax
	incl	C(clearnotify)
	cmpl	C(vid)+scs_vid_numpages_offset,%eax
	jl	.Lscreen_console_setup_clear_notify
	movl	$0,C(con_notifylines)
	jmp	.Lscreen_console_setup_done

.Lscreen_console_setup_clear_bottom:
	movl	$1,C(scr_copytop)

// C converts the float to int by truncation toward zero regardless of RC.
	fnstcw	-10(%ebp)
	movw	-10(%ebp),%ax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax
	movw	%ax,-12(%ebp)
	fldcw	-12(%ebp)
	flds	C(scr_con_current)
	fistpl	-16(%ebp)
	fldcw	-10(%ebp)

	movl	C(vid)+scs_vid_height_offset,%ecx
	subl	-16(%ebp),%ecx
	pushl	%ecx
	pushl	C(vid)+scs_vid_width_offset
	pushl	-16(%ebp)
	pushl	$0
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_console_setup_fixture_active)
	je	.Lscreen_console_setup_real_bottom_clear
	call	C(Bench486ScreenConsoleSetupTileClear)
	jmp	.Lscreen_console_setup_bottom_clear_done
.Lscreen_console_setup_real_bottom_clear:
	call	C(Draw_TileClear)
.Lscreen_console_setup_bottom_clear_done:
#else
	call	C(Draw_TileClear)
#endif
	addl	$16,%esp
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_console_setup_fixture_active)
	je	.Lscreen_console_setup_real_sbar_changed
	call	C(Bench486ScreenConsoleSetupSbarChanged)
	jmp	.Lscreen_console_setup_sbar_changed_done
.Lscreen_console_setup_real_sbar_changed:
	call	C(Sbar_Changed)
.Lscreen_console_setup_sbar_changed_done:
#else
	call	C(Sbar_Changed)
#endif
	jmp	.Lscreen_console_setup_done

.Lscreen_console_setup_clear_notify:
	movl	$1,C(scr_copytop)
	pushl	C(con_notifylines)
	pushl	C(vid)+scs_vid_width_offset
	pushl	$0
	pushl	$0
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_console_setup_fixture_active)
	je	.Lscreen_console_setup_real_notify_clear
	call	C(Bench486ScreenConsoleSetupTileClear)
	jmp	.Lscreen_console_setup_notify_clear_done
.Lscreen_console_setup_real_notify_clear:
	call	C(Draw_TileClear)
.Lscreen_console_setup_notify_clear_done:
#else
	call	C(Draw_TileClear)
#endif
	addl	$16,%esp

.Lscreen_console_setup_done:
	leave
	ret
#endif
