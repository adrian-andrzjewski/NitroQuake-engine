// SCR_UpdateScreen orchestration, kept in source order and 486 instruction set.
// The rendering algorithms remain in their independently selected routines.
#include "asm_i386.h"
#include "client/asm_screenupdate.h"

#if defined(ASM486_SCREEN_UPDATE)
.arch i486
.arch .387
.code32

// Calls in the direct differential fixture record the same call boundary and
// skip the callee.  The optional stack byte count is cleaned in either branch.
.macro SU_CALL event, target, stackbytes=0
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_update_fixture_active)
	je	.Lsu_real_\@
	pushl	$\event
	call	C(Bench486ScreenUpdateRecordCall)
	addl	$4,%esp
	.if \stackbytes
		addl	$\stackbytes,%esp
	.endif
	jmp	.Lsu_done_\@
.Lsu_real_\@:
	call	\target
	.if \stackbytes
		addl	$\stackbytes,%esp
	.endif
.Lsu_done_\@:
#else
	call	\target
	.if \stackbytes
		addl	$\stackbytes,%esp
	.endif
#endif
.endm

// VID_LockBuffer and VID_UnlockBuffer are no-op macros for this DOS build;
// keep their source-order fixture events without inventing runtime calls.
.macro SU_HOOK event
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_update_fixture_active)
	je	.Lsu_hook_done_\@
	pushl	$\event
	call	C(Bench486ScreenUpdateRecordCall)
	addl	$4,%esp
.Lsu_hook_done_\@:
#endif
.endm

// The update rectangle is copied into the fixture result so the differential
// test can compare the exact x/y/width/height/link fields.
.macro SU_VID_UPDATE
#ifdef BENCH486
	cmpl	$0,C(bench486_screen_update_fixture_active)
	je	.Lsu_vid_update_real_\@
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(Bench486ScreenUpdateRecordVidRect)
	addl	$4,%esp
	jmp	.Lsu_vid_update_done_\@
.Lsu_vid_update_real_\@:
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(VID_Update)
	addl	$4,%esp
.Lsu_vid_update_done_\@:
#else
	leal	-24(%ebp),%eax
	pushl	%eax
	call	C(VID_Update)
	addl	$4,%esp
#endif
.endm

.macro SU_TRACE phase
	pushl	$0
	pushl	$0
	pushl	-28(%ebp)
	pushl	$\phase
	call	C(Bench486ScreenCenterTraceGlyph)
	addl	$16,%esp
.endm

.text
.p2align 4,,15
.globl C(SCR_UpdateScreen_asm486)
#ifdef ASM486_SCREEN_UPDATE
.globl C(SCR_UpdateScreen)
C(SCR_UpdateScreen):
#endif
C(SCR_UpdateScreen_asm486):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	subl	$40,%esp
// Locals: vrect at -24..-5, trace update at -28, trace flag at -32,
// profile start time at -40.  Saved EBX remains at -4(%ebp).

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	movl	$0,-28(%ebp)
	movl	$0,-32(%ebp)
	cmpl	$0,C(bench486_screen_center_trace_active)
	je	.Lsu_trace_ready
	cmpl	$0,C(cls)+SU_CLIENT_DEMOPLAYBACK
	je	.Lsu_trace_ready
	cmpl	$0,C(scr_disabled_for_loading)
	jne	.Lsu_trace_ready
	cmpl	$0,C(scr_skipupdate)
	jne	.Lsu_trace_ready
	cmpl	$0,C(block_drawing)
	jne	.Lsu_trace_ready
	cmpl	$8,C(bench486_screen_update_trace_update_count)
	jge	.Lsu_trace_ready
	incl	C(bench486_screen_update_trace_update_count)
	movl	C(bench486_screen_update_trace_update_count),%eax
	movl	%eax,-28(%ebp)
	movl	$1,-32(%ebp)
	SU_TRACE 5
.Lsu_trace_ready:
#endif

	cmpl	$0,C(scr_skipupdate)
	jne	.Lsu_return
	cmpl	$0,C(block_drawing)
	jne	.Lsu_return

	movl	$0,C(scr_copytop)
	movl	$0,C(scr_copyeverything)

	cmpl	$0,C(scr_disabled_for_loading)
	je	.Lsu_not_disabled
	fldl	C(realtime)
	fsubs	C(scr_disabled_time)
	fcompl	.Lsu_sixty
	fnstsw	%ax
	sahf
	jp	.Lsu_loading_wait
	ja	.Lsu_loading_expired
.Lsu_loading_wait:
	jmp	.Lsu_return
.Lsu_loading_expired:
	movl	$0,C(scr_disabled_for_loading)
	pushl	$.Lsu_load_failed
	SU_CALL SU_EVENT_CON_PRINT,C(Con_Printf),4
.Lsu_not_disabled:

	cmpl	$SU_CA_DEDICATED,C(cls)+SU_CLIENT_STATE
	je	.Lsu_return
	cmpl	$0,C(scr_initialized)
	je	.Lsu_return
	cmpl	$0,C(con_initialized)
	je	.Lsu_return

// Match the current GCC i486 C oracle built with -ffast-math: after SAHF,
// it branches on C3/ZF alone, so an unordered FCOM result follows the same
// no-change path as equality. Signed zero also follows the no-change path.
	flds	C(scr_viewsize)+SU_CVAR_VALUE
	fcomps	C(scr_update_old_viewsize)
	fnstsw	%ax
	sahf
	jne	.Lsu_viewsize_changed
	jmp	.Lsu_check_fov
.Lsu_viewsize_changed:
	movl	C(scr_viewsize)+SU_CVAR_VALUE,%eax
	movl	%eax,C(scr_update_old_viewsize)
	movl	$1,C(vid)+SU_VID_RECALC_REFDEF
.Lsu_check_fov:
	flds	C(scr_fov)+SU_CVAR_VALUE
	fcomps	C(oldfov)
	fnstsw	%ax
	sahf
	jne	.Lsu_fov_changed
	jmp	.Lsu_check_lcd
.Lsu_fov_changed:
	movl	C(scr_fov)+SU_CVAR_VALUE,%eax
	movl	%eax,C(oldfov)
	movl	$1,C(vid)+SU_VID_RECALC_REFDEF
.Lsu_check_lcd:
	flds	C(lcd_x)+SU_CVAR_VALUE
	fcomps	C(scr_update_old_lcd_x)
	fnstsw	%ax
	sahf
	jne	.Lsu_lcd_changed
	jmp	.Lsu_check_screensize
.Lsu_lcd_changed:
	movl	C(lcd_x)+SU_CVAR_VALUE,%eax
	movl	%eax,C(scr_update_old_lcd_x)
	movl	$1,C(vid)+SU_VID_RECALC_REFDEF
.Lsu_check_screensize:
	flds	C(scr_viewsize)+SU_CVAR_VALUE
	fcomps	C(oldscreensize)
	fnstsw	%ax
	sahf
	jne	.Lsu_screensize_changed
	jmp	.Lsu_check_refdef
.Lsu_screensize_changed:
	movl	C(scr_viewsize)+SU_CVAR_VALUE,%eax
	movl	%eax,C(oldscreensize)
	movl	$1,C(vid)+SU_VID_RECALC_REFDEF
.Lsu_check_refdef:
	cmpl	$0,C(vid)+SU_VID_RECALC_REFDEF
	je	.Lsu_refdef_done
#ifdef ASM486_SCREEN_REFDEF
	SU_CALL SU_EVENT_CALC_REFDEF,C(SCR_CalcRefdef_asm486),0
#else
	SU_CALL SU_EVENT_CALC_REFDEF,C(SCR_CalcRefdef),0
#endif
.Lsu_refdef_done:

	SU_CALL SU_EVENT_ENABLE_BACKBUFFER,C(D_EnableBackBufferAccess),0
	movl	C(scr_fullupdate),%eax
	incl	C(scr_fullupdate)
	cmpl	C(vid)+SU_VID_NUMPAGES,%eax
	jge	.Lsu_no_full_clear
	movl	$1,C(scr_copyeverything)
	pushl	C(vid)+SU_VID_HEIGHT
	pushl	C(vid)+SU_VID_WIDTH
	pushl	$0
	pushl	$0
	SU_CALL SU_EVENT_TILE_CLEAR,C(Draw_TileClear),16
	SU_CALL SU_EVENT_SBAR_CHANGED,C(Sbar_Changed),0
.Lsu_no_full_clear:
	movl	$0,C(pconupdate)
	SU_CALL SU_EVENT_SETUP_CONSOLE,C(SCR_SetUpToDrawConsole),0
	SU_CALL SU_EVENT_ERASE_CENTER,C(SCR_EraseCenterString),0
	SU_CALL SU_EVENT_DISABLE_BACKBUFFER,C(D_DisableBackBufferAccess),0
	SU_HOOK SU_EVENT_LOCK_BUFFER

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lsu_no_profile_start_time
	call	C(Sys_FloatTime)
	fstpl	-40(%ebp)
.Lsu_no_profile_start_time:
	pushl	$4
	call	C(Bench486ProfileEnter)
	addl	$4,%esp
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,-32(%ebp)
	je	.Lsu_no_trace_pre_render
	SU_TRACE 6
.Lsu_no_trace_pre_render:
#endif
	SU_CALL SU_EVENT_RENDER_VIEW,C(V_RenderView),0
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,-32(%ebp)
	je	.Lsu_no_trace_post_render
	SU_TRACE 7
.Lsu_no_trace_post_render:
#endif
#ifdef PROFILE486
	call	C(Bench486ProfileLeave)
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lsu_no_profile_end_time
	call	C(Sys_FloatTime)
	fsubl	-40(%ebp)
	fldl	C(bench486_render_seconds)
	faddp	%st(0),%st(1)
	fstpl	C(bench486_render_seconds)
.Lsu_no_profile_end_time:
#endif
	SU_HOOK SU_EVENT_UNLOCK_BUFFER
	SU_CALL SU_EVENT_ENABLE_BACKBUFFER,C(D_EnableBackBufferAccess),0

#ifdef PROFILE486
	pushl	$39
	call	C(Bench486ProfileEnter)
	addl	$4,%esp
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,-32(%ebp)
	je	.Lsu_no_trace_pre_overlay
	SU_TRACE 8
.Lsu_no_trace_pre_overlay:
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	movl	-32(%ebp),%eax
	pushl	%eax
	movl	-28(%ebp),%eax
	pushl	%eax
#else
	pushl	$0
	pushl	$0
#endif
#ifdef ASM486_SCREEN_OVERLAYS
	SU_CALL SU_EVENT_OVERLAYS,C(SCR_DrawScreenOverlays_asm486),8
#else
	SU_CALL SU_EVENT_OVERLAYS,C(SCR_DrawScreenOverlays),8
#endif
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,-32(%ebp)
	je	.Lsu_no_trace_post_overlay
	SU_TRACE 11
.Lsu_no_trace_post_overlay:
#endif
	SU_CALL SU_EVENT_DISABLE_BACKBUFFER,C(D_DisableBackBufferAccess),0
	cmpl	$0,C(pconupdate)
	je	.Lsu_no_console_rect
	pushl	C(pconupdate)
	SU_CALL SU_EVENT_UPDATE_RECTS,C(D_UpdateRects),4
.Lsu_no_console_rect:
#ifdef PROFILE486
	call	C(Bench486ProfileLeave)
	pushl	$40
	call	C(Bench486ProfileEnter)
	addl	$4,%esp
#endif
	SU_CALL SU_EVENT_UPDATE_PALETTE,C(V_UpdatePalette),0
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,-32(%ebp)
	je	.Lsu_no_trace_post_palette
	SU_TRACE 12
.Lsu_no_trace_post_palette:
#endif
#ifdef PROFILE486
	call	C(Bench486ProfileLeave)
#endif

	cmpl	$0,C(scr_copyeverything)
	je	.Lsu_copy_top_check
	movl	$0,-24(%ebp)
	movl	$0,-20(%ebp)
	movl	C(vid)+SU_VID_WIDTH,%eax
	movl	%eax,-16(%ebp)
	movl	C(vid)+SU_VID_HEIGHT,%eax
	movl	%eax,-12(%ebp)
	movl	$0,-8(%ebp)
	jmp	.Lsu_vid_update
.Lsu_copy_top_check:
	cmpl	$0,C(scr_copytop)
	je	.Lsu_copy_view_rect
	movl	$0,-24(%ebp)
	movl	$0,-20(%ebp)
	movl	C(vid)+SU_VID_WIDTH,%eax
	movl	%eax,-16(%ebp)
	movl	C(vid)+SU_VID_HEIGHT,%eax
	subl	C(sb_lines),%eax
	movl	%eax,-12(%ebp)
	movl	$0,-8(%ebp)
	jmp	.Lsu_vid_update
.Lsu_copy_view_rect:
	movl	C(scr_vrect)+SU_VRECT_X,%eax
	movl	%eax,-24(%ebp)
	movl	C(scr_vrect)+SU_VRECT_Y,%eax
	movl	%eax,-20(%ebp)
	movl	C(scr_vrect)+SU_VRECT_WIDTH,%eax
	movl	%eax,-16(%ebp)
	movl	C(scr_vrect)+SU_VRECT_HEIGHT,%eax
	movl	%eax,-12(%ebp)
	movl	$0,-8(%ebp)
.Lsu_vid_update:
	SU_VID_UPDATE
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	cmpl	$0,-32(%ebp)
	je	.Lsu_no_trace_post_update
	SU_TRACE 13
.Lsu_no_trace_post_update:
#endif
.Lsu_return:
	addl	$40,%esp
	popl	%ebx
	leave
	ret

.section .rodata
.align 8
.Lsu_sixty:
	.double 60.0
.Lsu_load_failed:
	.asciz "load failed.\n"
#endif
