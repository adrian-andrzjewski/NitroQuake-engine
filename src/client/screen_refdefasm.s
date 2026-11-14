// SCR_CalcRefdef from screen.c, expressed as auditable i486 + 387 code.
// The operation order follows the original scalar C routine. Renderer calls
// remain explicit so their separately verified implementations stay visible.
// BENCH486 hooks are enabled only while the direct fixture sets its active flag.
#include "asm_i386.h"
#include "client/asm_screenrefdef.h"

#if defined(ASM486_SCREEN_REFDEF)
.arch i486
.arch .387
.code32

.text
.p2align 4,,15
.globl C(SCR_CalcRefdef_asm486)
C(SCR_CalcRefdef_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$24,%esp

	// Force the full background redraw and mark the current refdef consumed.
	movl	$0,C(scr_fullupdate)
	movl	$0,C(vid)+SR_VID_RECALC_REFDEF

#ifdef BENCH486
	cmpl	$0,C(bench486_screen_refdef_fixture_active)
	je	.Lsr_sbar_live
	call	C(Bench486ScreenRefdefSbarChanged)
	jmp	.Lsr_sbar_done
.Lsr_sbar_live:
	call	C(Sbar_Changed)
.Lsr_sbar_done:
#else
	call	C(Sbar_Changed)
#endif

	// Bound viewsize exactly as the C routine: the second test observes a
	// value changed by the first Cvar_Set call.
	flds	C(scr_viewsize)+SR_CVAR_VALUE
	fcoms	.Lsr_30
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsr_viewsize_upper
	jb	.Lsr_viewsize_set_30
	 jmp	.Lsr_viewsize_upper
.Lsr_viewsize_set_30:
	pushl	$.Lsr_text_30
	pushl	$.Lsr_name_viewsize
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_refdef_fixture_active)
	je	.Lsr_viewsize_live_30
	call	C(Bench486ScreenRefdefCvarSet)
	jmp	.Lsr_viewsize_done_30
.Lsr_viewsize_live_30:
	call	C(Cvar_Set)
.Lsr_viewsize_done_30:
#else
	call	C(Cvar_Set)
#endif
	addl	$8,%esp
.Lsr_viewsize_upper:
	flds	C(scr_viewsize)+SR_CVAR_VALUE
	fcoms	.Lsr_120
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsr_fov_lower
	ja	.Lsr_viewsize_set_120
	 jmp	.Lsr_fov_lower
.Lsr_viewsize_set_120:
	pushl	$.Lsr_text_120
	pushl	$.Lsr_name_viewsize
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_refdef_fixture_active)
	je	.Lsr_viewsize_live_120
	call	C(Bench486ScreenRefdefCvarSet)
	jmp	.Lsr_viewsize_done_120
.Lsr_viewsize_live_120:
	call	C(Cvar_Set)
.Lsr_viewsize_done_120:
#else
	call	C(Cvar_Set)
#endif
	addl	$8,%esp

	// Bound field of view, preserving Cvar_Set order and spelling.
.Lsr_fov_lower:
	flds	C(scr_fov)+SR_CVAR_VALUE
	fcoms	.Lsr_10
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsr_fov_upper
	jb	.Lsr_fov_set_10
	 jmp	.Lsr_fov_upper
.Lsr_fov_set_10:
	pushl	$.Lsr_text_10
	pushl	$.Lsr_name_fov
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_refdef_fixture_active)
	je	.Lsr_fov_live_10
	call	C(Bench486ScreenRefdefCvarSet)
	jmp	.Lsr_fov_done_10
.Lsr_fov_live_10:
	call	C(Cvar_Set)
.Lsr_fov_done_10:
#else
	call	C(Cvar_Set)
#endif
	addl	$8,%esp
.Lsr_fov_upper:
	flds	C(scr_fov)+SR_CVAR_VALUE
	fcoms	.Lsr_170
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsr_fov_done
	ja	.Lsr_fov_set_170
	 jmp	.Lsr_fov_done
.Lsr_fov_set_170:
	pushl	$.Lsr_text_170
	pushl	$.Lsr_name_fov
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_refdef_fixture_active)
	je	.Lsr_fov_live_170
	call	C(Bench486ScreenRefdefCvarSet)
	jmp	.Lsr_fov_done_170
.Lsr_fov_live_170:
	call	C(Cvar_Set)
.Lsr_fov_done_170:
#else
	call	C(Cvar_Set)
#endif
	addl	$8,%esp

.Lsr_fov_done:
	// Calculate the vertical FOV using the same public helper selected by the
	// existing view-control selector; its x87 behavior is independently tested.
	movl	C(scr_fov)+SR_CVAR_VALUE,%eax
	movl	%eax,C(r_refdef)+SR_REFDEF_FOV_X
	pushl	C(r_refdef)+SR_VRECT_HEIGHT
	pushl	C(r_refdef)+SR_VRECT_WIDTH
	pushl	C(r_refdef)+SR_REFDEF_FOV_X
#ifdef ASM486_VIEW_CONTROL
	call	C(CalcFov_asm486)
#else
	call	C(CalcFov)
#endif
	addl	$12,%esp
	fstps	C(r_refdef)+SR_REFDEF_FOV_Y

	// The intermission forces a full-screen size regardless of viewsize.
	cmpl	$0,C(cl)+SR_CLIENT_INTERMISSION
	je	.Lsr_use_viewsize
	flds	.Lsr_120
	fstps	-24(%ebp)
	jmp	.Lsr_choose_status_lines
.Lsr_use_viewsize:
	movl	C(scr_viewsize)+SR_CVAR_VALUE,%eax
	movl	%eax,-24(%ebp)

.Lsr_choose_status_lines:
	flds	-24(%ebp)
	fcoms	.Lsr_120
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsr_check_110
	jae	.Lsr_hide_status
.Lsr_check_110:
	flds	-24(%ebp)
	fcoms	.Lsr_110
	fnstsw	%ax
	sahf
	fstp	%st(0)
	jp	.Lsr_full_status
	jae	.Lsr_no_inventory
	jmp	.Lsr_full_status
.Lsr_hide_status:
	movl	$0,C(sb_lines)
	jmp	.Lsr_make_vrect
.Lsr_no_inventory:
	movl	$24,C(sb_lines)
	jmp	.Lsr_make_vrect
.Lsr_full_status:
	movl	$48,C(sb_lines)

.Lsr_make_vrect:
	// Local vrect_t vrect = {0,0,vid.width,vid.height,NULL}.
	movl	$0,-20(%ebp)
	movl	$0,-16(%ebp)
	movl	C(vid)+SR_VID_WIDTH,%eax
	movl	%eax,-12(%ebp)
	movl	C(vid)+SR_VID_HEIGHT,%eax
	movl	%eax,-8(%ebp)
	movl	$0,-4(%ebp)

	pushl	C(sb_lines)
	leal	C(scr_vrect),%eax
	pushl	%eax
	leal	-20(%ebp),%eax
	pushl	%eax
	call	C(R_SetVrect)
	addl	$12,%esp

	// C compares the float console height with vid.height converted to float.
	fildl	C(vid)+SR_VID_HEIGHT
	flds	C(scr_con_current)
	fcompp
	fnstsw	%ax
	sahf
	jp	.Lsr_console_done
	jbe	.Lsr_console_done
	fildl	C(vid)+SR_VID_HEIGHT
	fstps	C(scr_con_current)
.Lsr_console_done:
	pushl	C(vid)+SR_VID_ASPECT
	pushl	C(sb_lines)
	leal	-20(%ebp),%eax
	pushl	%eax
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_refdef_fixture_active)
	je	.Lsr_view_changed_live
	call	C(Bench486ScreenRefdefViewChanged)
	jmp	.Lsr_view_changed_done
.Lsr_view_changed_live:
	call	C(R_ViewChanged)
.Lsr_view_changed_done:
#else
	call	C(R_ViewChanged)
#endif
	addl	$12,%esp

	leave
	ret

.section .rodata
.p2align 2
.Lsr_10:
	.float	10.0
.Lsr_30:
	.float	30.0
.Lsr_110:
	.float	110.0
.Lsr_120:
	.float	120.0
.Lsr_170:
	.float	170.0
.Lsr_name_viewsize:
	.asciz	"viewsize"
.Lsr_name_fov:
	.asciz	"fov"
.Lsr_text_10:
	.asciz	"10"
.Lsr_text_30:
	.asciz	"30"
.Lsr_text_120:
	.asciz	"120"
.Lsr_text_170:
	.asciz	"170"
#endif
