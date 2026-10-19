/* i486 per-frame video update state machine from vid_dos.c:VID_Update. */
#include "asm_i386.h"
#include "asm_vidupdate.h"
#include "asm_viddirectrect.h"
#include "asm_vidmode.h"
#undef i386
.arch i486
.arch .387
.code32

#ifdef ASM486_VID_UPDATE
#ifdef ASM486_VID_UPDATE_FIXTURE
#define VID_UPDATE_SET_MODE C(Bench486VidUpdateSetMode)
#define VID_UPDATE_DEFAULT_MODE C(Bench486VidUpdateDefaultMode)
#define VID_UPDATE_SET_CVAR C(Bench486VidUpdateSetValue)
#define VID_UPDATE_NO_VESA_MESSAGE C(Bench486VidUpdateNoVesaMessage)
#else
#define VID_UPDATE_SET_MODE C(VID_SetMode)
#define VID_UPDATE_DEFAULT_MODE C(VID_ExtraDefaultMode)
#define VID_UPDATE_SET_CVAR C(Cvar_SetValue)
#define VID_UPDATE_NO_VESA_MESSAGE C(Con_Printf)
#endif
#ifdef ASM486_VID_UPDATE_FIXTURE
#define VID_MODE_SET_VALUE C(Bench486VidModeSetValue)
#define VID_MODE_PRINTF C(Bench486VidModePrintf)
#define VID_MODE_ERROR C(Bench486VidModeError)
#define VID_MODE_RELEASE_EXTRA C(Bench486VidModeReleaseExtra)
#define VID_MODE_PALETTE_OK C(Bench486VidModePaletteOK)
#else
#define VID_MODE_SET_VALUE C(Cvar_SetValue)
#define VID_MODE_PRINTF C(Con_Printf)
#define VID_MODE_ERROR C(Sys_Error)
#define VID_MODE_RELEASE_EXTRA C(VID_ExtraReleaseMode)
#define VID_MODE_PALETTE_OK C(VID_ExtraPaletteOK)
#endif
.text
.p2align 2
.globl C(VID_GetModePtr)
C(VID_GetModePtr):
	pushl	%ebp
	movl	%esp,%ebp
	movl	C(pvidmodes),%eax
	testl	%eax,%eax
	jne	.Lvid_mode_ptr_list
	pushl	$.Lvid_mode_empty_list
	call	VID_MODE_ERROR
	addl	$4,%esp
	xorl	%eax,%eax
	leave
	ret
.Lvid_mode_ptr_list:
	movl	8(%ebp),%ecx
	testl	%ecx,%ecx
	js	.Lvid_mode_ptr_corrupt
.Lvid_mode_ptr_loop:
	testl	%ecx,%ecx
	je	.Lvid_mode_ptr_done
	movl	VM_MODE_NEXT_OFFSET(%eax),%eax
	testl	%eax,%eax
	je	.Lvid_mode_ptr_corrupt
	decl	%ecx
	jmp	.Lvid_mode_ptr_loop
.Lvid_mode_ptr_corrupt:
	pushl	$.Lvid_mode_corrupt_list
	call	VID_MODE_ERROR
	addl	$4,%esp
	xorl	%eax,%eax
.Lvid_mode_ptr_done:
	leave
	ret

.globl C(VID_ModeInfo)
C(VID_ModeInfo):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	8(%ebp)
	call	C(VID_GetModePtr)
	addl	$4,%esp
	testl	%eax,%eax
	jne	.Lvid_mode_info_valid
	movl	12(%ebp),%ecx
	testl	%ecx,%ecx
	je	.Lvid_mode_info_bad
	movl	$0,(%ecx)
.Lvid_mode_info_bad:
	movl	$.Lvid_bad_mode_name,%eax
	leave
	ret
.Lvid_mode_info_valid:
	movl	12(%ebp),%ecx
	testl	%ecx,%ecx
	je	.Lvid_mode_info_name
	movl	VM_MODE_HEADER_OFFSET(%eax),%edx
	movl	%edx,(%ecx)
.Lvid_mode_info_name:
	movl	VM_MODE_NAME_OFFSET(%eax),%eax
	leave
	ret

/* Mode lookup, callback dispatch, and the single VGA fallback attempt. */
.globl C(VID_SetMode)
C(VID_SetMode):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp
	movl	8(%ebp),%ebx
	movl	%ebx,-16(%ebp)		/* requested mode */
	movl	12(%ebp),%esi		/* palette */
	movl	C(scr_disabled_for_loading),%eax
	movl	%eax,-24(%ebp)		/* restore screen suppression */

	movl	C(numvidmodes),%eax
	cmpl	%eax,%ebx
	jge	.Lvid_setmode_invalid
	testl	%ebx,%ebx
	js	.Lvid_setmode_invalid
	jmp	.Lvid_setmode_lookup

.Lvid_setmode_invalid:
	fildl	C(vid_modenum)
	fstps	-28(%ebp)
	pushl	-28(%ebp)
	pushl	$.Lvid_mode_cvar_name
	call	VID_MODE_SET_VALUE
	addl	$8,%esp
	movl	$1,C(vid_nomodecheck)
	pushl	%ebx
	pushl	$.Lvid_mode_invalid_format
	call	VID_MODE_PRINTF
	addl	$8,%esp
	movl	$0,C(vid_nomodecheck)
	cmpl	$0,C(pcurrentmode)
	jne	.Lvid_setmode_return_false
	xorl	%ebx,%ebx

.Lvid_setmode_lookup:
	pushl	%ebx
	call	C(VID_GetModePtr)
	addl	$4,%esp
	cmpl	C(pcurrentmode),%eax
	jne	.Lvid_setmode_begin
	movl	$1,%eax
	jmp	.Lvid_setmode_return

.Lvid_setmode_begin:
	movl	$1,C(vid_nomodecheck)
	movl	$1,C(scr_disabled_for_loading)
	movl	$0,-20(%ebp)		/* attempt */
.Lvid_setmode_attempt:
	call	VID_MODE_RELEASE_EXTRA
	movl	$0,C(vid)+VM_VID_DIRECT_OFFSET
	pushl	%ebx
	call	C(VID_GetModePtr)
	addl	$4,%esp
	movl	%eax,C(pcurrentmode)
	movl	%eax,-32(%ebp)		/* current mode */
	movl	VM_MODE_WIDTH_OFFSET(%eax),%ecx
	movl	%ecx,C(vid)+VM_VID_WIDTH_OFFSET
	movl	VM_MODE_HEIGHT_OFFSET(%eax),%ecx
	movl	%ecx,C(vid)+VM_VID_HEIGHT_OFFSET
	movl	VM_MODE_ASPECT_OFFSET(%eax),%ecx
	movl	%ecx,C(vid)+VM_VID_ASPECT_OFFSET
	movl	VM_MODE_ROWBYTES_OFFSET(%eax),%ecx
	movl	%ecx,C(vid)+VM_VID_ROWBYTES_OFFSET
	movl	VM_MODE_SETMODE_OFFSET(%eax),%ecx
	pushl	%eax
	pushl	$C(vid)
	call	*%ecx
	addl	$8,%esp
	testl	%eax,%eax
	jle	.Lvid_setmode_failed

	movl	-32(%ebp),%eax
	movl	VM_MODE_SETPALETTE_OFFSET(%eax),%ecx
	pushl	%esi
	pushl	%eax
	pushl	$C(vid)
	call	*%ecx
	addl	$12,%esp
	call	VID_MODE_PALETTE_OK
	testl	%eax,%eax
	jne	.Lvid_setmode_success

.Lvid_setmode_failed:
	pushl	%ebx
	pushl	$.Lvid_mode_fallback_format
	call	VID_MODE_PRINTF
	addl	$8,%esp
	cmpl	$0,%ebx
	je	.Lvid_setmode_error
	cmpl	$1,-20(%ebp)
	jne	.Lvid_setmode_fallback
.Lvid_setmode_error:
	pushl	$.Lvid_mode_error_text
	call	VID_MODE_ERROR
	addl	$4,%esp
.Lvid_setmode_fallback:
	xorl	%ebx,%ebx
	incl	-20(%ebp)
	cmpl	$2,-20(%ebp)
	jl	.Lvid_setmode_attempt

.Lvid_setmode_success:
	pushl	$768
	pushl	%esi
	pushl	$C(vid_current_palette)
	call	C(Q_memcpy)
	addl	$12,%esp
	movl	%ebx,C(vid_modenum)
	fildl	C(vid_modenum)
	fstps	-28(%ebp)
	pushl	-28(%ebp)
	pushl	$.Lvid_mode_cvar_name
	call	VID_MODE_SET_VALUE
	addl	$8,%esp
	movl	$1,C(vid)+VM_VID_RECALC_REFDEF_OFFSET
	movl	$1,C(vid_nomodecheck)
	pushl	$0
	pushl	C(vid_modenum)
	call	C(VID_ModeInfo)
	addl	$8,%esp
	pushl	%eax
	pushl	C(vid_modenum)
	pushl	$.Lvid_mode_success_format
	call	VID_MODE_PRINTF
	addl	$12,%esp
	cmpl	$0,%ebx
	jne	.Lvid_setmode_restore
	pushl	$.Lvid_mode_vga_format
	call	VID_MODE_PRINTF
	addl	$4,%esp
.Lvid_setmode_restore:
	movl	$0,C(vid_nomodecheck)
	movl	-24(%ebp),%eax
	movl	%eax,C(scr_disabled_for_loading)
	cmpl	-16(%ebp),%ebx
	sete	%al
	movzbl	%al,%eax
	jmp	.Lvid_setmode_return

.Lvid_setmode_return_false:
	xorl	%eax,%eax
.Lvid_setmode_return:
	addl	$24,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

/* Palette copy, current-mode callback, and the VGA fallback on rejection. */
.globl C(VID_SetPalette)
C(VID_SetPalette):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	movl	8(%ebp),%esi
	cmpl	$C(vid_current_palette),%esi
	je	.Lvid_setpalette_ready
	pushl	$768
	pushl	%esi
	pushl	$C(vid_current_palette)
	call	C(Q_memcpy)
	addl	$12,%esp
.Lvid_setpalette_ready:
	movl	C(pcurrentmode),%ebx
	movl	VM_MODE_SETPALETTE_OFFSET(%ebx),%ecx
	pushl	$C(vid_current_palette)
	pushl	%ebx
	pushl	$C(vid)
	call	*%ecx
	addl	$12,%esp
	call	VID_MODE_PALETTE_OK
	testl	%eax,%eax
	jne	.Lvid_setpalette_done
	pushl	$C(vid_current_palette)
	pushl	$0
	call	C(VID_SetMode)
	addl	$8,%esp
.Lvid_setpalette_done:
	popl	%esi
	popl	%ebx
	leave
	ret

.globl C(VID_ShiftPalette)
C(VID_ShiftPalette):
	jmp	C(VID_SetPalette)

.section .rodata
.Lvid_mode_empty_list:
	.asciz "VID_GetModePtr: empty vid mode list"
.Lvid_mode_corrupt_list:
	.asciz "VID_GetModePtr: corrupt vid mode list"
.Lvid_bad_mode_name:
	.asciz "Bad mode number"
.Lvid_mode_cvar_name:
	.asciz "vid_mode"
.Lvid_mode_invalid_format:
	.asciz "No such video mode: %d\n"
.Lvid_mode_fallback_format:
	.asciz "Video: mode %d initialization failed; falling back to VGA mode 13h\n"
.Lvid_mode_error_text:
	.asciz "VID_SetMode: unable to initialize VGA mode 13h"
.Lvid_mode_success_format:
	.asciz "Video mode %d: %s\n"
.Lvid_mode_vga_format:
	.asciz "Video: VGA BIOS 0x13 pitch 320, 1 page, RAM copy\n"
.text
.p2align 2
.globl C(VID_Update)
C(VID_Update):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp
	movl	8(%ebp),%ebx		/* vrect_t *rects */

#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lvid_update_no_framebuffer_start
	call	C(Sys_FloatTime)
	fstpl	-20(%ebp)
.Lvid_update_no_framebuffer_start:
	pushl	$VU_PROFILE_PRESENT
	call	C(Bench486ProfileEnter)
	addl	$4,%esp
	 movl	$0,-24(%ebp)
	movl	$0,-28(%ebp)
	movl	%ebx,%esi
.Lvid_update_rect_profile_loop:
	testl	%esi,%esi
	je	.Lvid_update_rect_profile_done
	incl	-24(%ebp)
	movl	VU_RECT_WIDTH_OFFSET(%esi),%eax
	imull	VU_RECT_HEIGHT_OFFSET(%esi),%eax
	addl	%eax,-28(%ebp)
	movl	VU_RECT_NEXT_OFFSET(%esi),%esi
	jmp	.Lvid_update_rect_profile_loop
.Lvid_update_rect_profile_done:
#endif

	/* Defer automatic mode selection until startup commands have run. */
	cmpl	$0,C(vid_firstupdate)
	je	.Lvid_update_present
	cmpl	$0,C(host_framecount)
	jle	.Lvid_update_present
	cmpl	$0,C(vid_nomodecheck)
	jne	.Lvid_update_present
	movl	$0,C(vid_firstupdate)

	/* Reset an invalid saved default mode before consulting command-line mode. */
	flds	C(_vid_default_mode)+VU_CVAR_VALUE_OFFSET
	ftst
	fnstsw	%ax
	testb	$0x01,%ah		/* negative or unordered */
	jnz	.Lvid_update_default_bad_stack
	ficompl	C(numvidmodes)
	fnstsw	%ax
	testb	$0x05,%ah		/* below numvidmodes is valid */
	jnz	.Lvid_update_default_valid
	jmp	.Lvid_update_reset_default
.Lvid_update_default_bad_stack:
	fstp	%st(0)
.Lvid_update_reset_default:
	pushl	$0
	pushl	$.Lvid_update_default_mode_name
	call	VID_UPDATE_SET_CVAR
	addl	$8,%esp
.Lvid_update_default_valid:
	pushl	$.Lvid_update_stdvid_arg
	call	C(COM_CheckParm)
	addl	$4,%esp
	testl	%eax,%eax
	je	.Lvid_update_startup_default
	pushl	$0
	pushl	$.Lvid_update_vid_mode_name
	call	VID_UPDATE_SET_CVAR
	addl	$8,%esp
	jmp	.Lvid_update_present

.Lvid_update_startup_default:
	cmpl	$0,C(vid_startup_mode_requested)
	jne	.Lvid_update_present
	pushl	$.Lvid_update_vid_mode_arg
	call	C(COM_CheckParm)
	addl	$4,%esp
	testl	%eax,%eax
	jne	.Lvid_update_present
	flds	C(vid_mode)+VU_CVAR_VALUE_OFFSET
	ficompl	C(vid_modenum)
	fnstsw	%ax
	testb	$0x40,%ah		/* exact equality, as in the C source */
	je	.Lvid_update_present
	movl	C(_vid_default_mode)+VU_CVAR_VALUE_OFFSET,%eax
	andl	$0x7fffffff,%eax	/* both signed zero values are false */
	jne	.Lvid_update_use_saved_default
	call	VID_UPDATE_DEFAULT_MODE
	movl	%eax,-32(%ebp)
	fildl	-32(%ebp)
	fstps	-32(%ebp)
	pushl	-32(%ebp)
	pushl	$.Lvid_update_vid_mode_name
	call	VID_UPDATE_SET_CVAR
	addl	$8,%esp
	movl	C(vid_mode)+VU_CVAR_VALUE_OFFSET,%eax
	andl	$0x7fffffff,%eax
	jne	.Lvid_update_present
	pushl	$.Lvid_update_no_vesa_mode
	call	VID_UPDATE_NO_VESA_MESSAGE
	addl	$4,%esp
	jmp	.Lvid_update_present

.Lvid_update_use_saved_default:
	pushl	C(_vid_default_mode)+VU_CVAR_VALUE_OFFSET
	pushl	$.Lvid_update_vid_mode_name
	call	VID_UPDATE_SET_CVAR
	addl	$8,%esp

.Lvid_update_present:
	/* pcurrentmode->swapbuffers(&vid, pcurrentmode, rects). */
	movl	C(pcurrentmode),%eax
	pushl	%ebx
	pushl	%eax
	pushl	$C(vid)
	call	*VU_VMODE_SWAPBUFFERS_OFFSET(%eax)
	addl	$12,%esp

	/* Mode tests run after the current frame has been presented. */
	cmpl	$0,C(vid_nomodecheck)
	jne	.Lvid_update_profile_end
	cmpl	$0,C(vid_testingmode)
	je	.Lvid_update_check_requested_mode
	fldl	C(realtime)
	fcompl	C(vid_testendtime)
	fnstsw	%ax
	testb	$0x05,%ah		/* ordered realtime >= test end */
	jne	.Lvid_update_profile_end
	pushl	$C(vid_current_palette)
	pushl	C(vid_realmode)
	call	VID_UPDATE_SET_MODE
	addl	$8,%esp
	movl	$0,C(vid_testingmode)
	jmp	.Lvid_update_profile_end

.Lvid_update_check_requested_mode:
	fildl	C(vid_realmode)
	fcomps	C(vid_mode)+VU_CVAR_VALUE_OFFSET
	fnstsw	%ax
	testb	$0x40,%ah		/* match the C -ffast-math equality branch */
	jne	.Lvid_update_profile_end
	cmpl	$0,C(vid_firstupdate)
	je	.Lvid_update_convert_mode
	movl	$1,C(vid_startup_mode_requested)
.Lvid_update_convert_mode:
	flds	C(vid_mode)+VU_CVAR_VALUE_OFFSET
	fnstcw	-34(%ebp)
	movw	-34(%ebp),%dx
	orw	$0x0c00,%dx		/* C float-to-int conversion truncates toward zero */
	movw	%dx,-36(%ebp)
	fldcw	-36(%ebp)
	fistpl	-32(%ebp)
	fldcw	-34(%ebp)
	pushl	$C(vid_current_palette)
	pushl	-32(%ebp)
	call	VID_UPDATE_SET_MODE
	addl	$8,%esp
	fildl	C(vid_modenum)
	fstps	-32(%ebp)
	pushl	-32(%ebp)
	pushl	$.Lvid_update_vid_mode_name
	call	VID_UPDATE_SET_CVAR
	addl	$8,%esp
	movl	C(vid_modenum),%eax
	movl	%eax,C(vid_realmode)

.Lvid_update_profile_end:
#ifdef PROFILE486
	cmpl	$0,C(bench486_profile_frame_active)
	je	.Lvid_update_profile_work
	call	C(Sys_FloatTime)
	fstpl	-36(%ebp)
	fldl	-36(%ebp)
	fsubl	-20(%ebp)
	faddl	C(bench486_framebuffer_seconds)
	fstpl	C(bench486_framebuffer_seconds)
	movl	-24(%ebp),%eax
	addl	%eax,C(bench486_present_rects)
	movl	-28(%ebp),%eax
	addl	%eax,C(bench486_present_pixels)
.Lvid_update_profile_work:
	pushl	-28(%ebp)
	pushl	-24(%ebp)
	pushl	$VU_PROFILE_PRESENT
	call	C(Bench486ProfileWork)
	addl	$12,%esp
	call	C(Bench486ProfileLeave)
#endif
	addl	$24,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.section .rodata
.Lvid_update_default_mode_name:
	.asciz	"_vid_default_mode"
.Lvid_update_vid_mode_name:
	.asciz	"vid_mode"
.Lvid_update_stdvid_arg:
	.asciz	"-stdvid"
.Lvid_update_vid_mode_arg:
	.asciz	"+vid_mode"
.Lvid_update_no_vesa_mode:
	.asciz	"Video: no usable VESA 320x200x8 mode; using VGA mode 13h\n"

/* Direct rectangle dispatch and VGA save/restore are video update helpers. */
.text
.p2align 2
.globl C(D_BeginDirectRect)
C(D_BeginDirectRect):
	pushl	%ebp
	movl	%esp,%ebp
	cmpl	$0,C(vid)+VD_VID_DIRECT_OFFSET
	je	.Lvdrect_begin_return
	movl	C(pcurrentmode),%edx
	testl	%edx,%edx
	je	.Lvdrect_begin_return
	movl	20(%ebp),%eax		/* width */
	cmpl	$24,%eax
	jg	.Lvdrect_begin_return
	movl	24(%ebp),%ecx		/* height */
	cmpl	$24,%ecx
	jg	.Lvdrect_begin_return
	cmpl	$1,%eax
	jl	.Lvdrect_begin_return
	cmpl	$1,%ecx
	jl	.Lvdrect_begin_return
	testl	$3,%eax
	jne	.Lvdrect_begin_return
	movl	VD_MODE_BEGIN_DIRECTRECT_OFFSET(%edx),%eax
	pushl	24(%ebp)		/* height */
	pushl	20(%ebp)		/* width */
	pushl	16(%ebp)		/* pbitmap */
	pushl	12(%ebp)		/* y */
	pushl	8(%ebp)		/* x */
	pushl	%edx			/* pcurrentmode */
	pushl	$C(vid)
	call	*%eax
	addl	$28,%esp
.Lvdrect_begin_return:
	leave
	ret

.p2align 2
.globl C(D_EndDirectRect)
C(D_EndDirectRect):
	pushl	%ebp
	movl	%esp,%ebp
	cmpl	$0,C(vid)+VD_VID_DIRECT_OFFSET
	je	.Lvdrect_end_return
	movl	C(pcurrentmode),%edx
	testl	%edx,%edx
	je	.Lvdrect_end_return
	movl	16(%ebp),%eax		/* width */
	cmpl	$24,%eax
	jg	.Lvdrect_end_return
	movl	20(%ebp),%ecx		/* height */
	cmpl	$24,%ecx
	jg	.Lvdrect_end_return
	cmpl	$1,%eax
	jl	.Lvdrect_end_return
	cmpl	$1,%ecx
	jl	.Lvdrect_end_return
	testl	$3,%eax
	jne	.Lvdrect_end_return
	testl	$3,%ecx
	jne	.Lvdrect_end_return
	movl	VD_MODE_END_DIRECTRECT_OFFSET(%edx),%eax
	pushl	20(%ebp)		/* height */
	pushl	16(%ebp)		/* width */
	pushl	12(%ebp)		/* y */
	pushl	8(%ebp)		/* x */
	pushl	%edx			/* pcurrentmode */
	pushl	$C(vid)
	call	*%eax
	addl	$24,%esp
.Lvdrect_end_return:
	leave
	ret

/* VGA_BeginDirectRect(vid, mode, x, y, bitmap, width, height). */
.p2align 2
.globl C(VGA_BeginDirectRect)
C(VGA_BeginDirectRect):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$68,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi		/* lvid */
	movl	VD_VID_DIRECT_OFFSET(%esi),%eax
	testl	%eax,%eax
	je	.Lvdrect_vga_begin_return
	movl	%eax,-4(%ebp)		/* direct framebuffer */
	movl	24(%ebp),%eax
	movl	%eax,-8(%ebp)		/* pbitmap */
	movl	16(%ebp),%eax
	movl	%eax,-12(%ebp)		/* x */
	movl	20(%ebp),%eax
	movl	%eax,-16(%ebp)		/* y */
	movl	28(%ebp),%eax
	movl	%eax,-20(%ebp)		/* width */
	movl	32(%ebp),%eax
	movl	%eax,-24(%ebp)		/* height */
	flds	VD_VID_ASPECT_OFFSET(%esi)
	fcomps	.Lvdrect_aspect_1_5
	fnstsw	%ax
	sahf
	ja	.Lvdrect_vga_begin_double
	movl	$1,-28(%ebp)		/* reps */
	movl	$0,-32(%ebp)		/* repshift */
	jmp	.Lvdrect_vga_begin_rows
.Lvdrect_vga_begin_double:
	movl	$2,-28(%ebp)
	movl	$1,-32(%ebp)
.Lvdrect_vga_begin_rows:
	movl	-24(%ebp),%eax
	movl	-32(%ebp),%ecx
	shll	%cl,%eax
	movl	%eax,-36(%ebp)		/* output rows */
	movl	12(%ebp),%eax		/* mode */
	cmpl	$0,VD_MODE_PLANAR_OFFSET(%eax)
	jne	.Lvdrect_vga_begin_planar
	movl	$0,-40(%ebp)		/* i */
.Lvdrect_vga_begin_linear_i:
	movl	-40(%ebp),%eax
	cmpl	-36(%ebp),%eax
	jge	.Lvdrect_vga_begin_return
	movl	$0,-44(%ebp)		/* j */
.Lvdrect_vga_begin_linear_j:
	movl	-44(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lvdrect_vga_begin_linear_next_i
	movl	-40(%ebp),%eax
	addl	-44(%ebp),%eax
	movl	%eax,-68(%ebp)		/* output row */
	movl	-16(%ebp),%edx
	movl	-32(%ebp),%ecx
	shll	%cl,%edx
	addl	%eax,%edx
	imull	C(VGA_rowbytes),%edx
	addl	-12(%ebp),%edx
	movl	%edx,-56(%ebp)		/* direct byte offset */
	movl	-68(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	shll	$3,%eax
	movl	%eax,-60(%ebp)		/* backing byte offset */
	movl	-40(%ebp),%eax
	movl	-32(%ebp),%ecx
	shrl	%cl,%eax
	imull	-20(%ebp),%eax
	movl	%eax,-64(%ebp)		/* bitmap byte offset */
	movl	-4(%ebp),%esi
	addl	-56(%ebp),%esi
	movl	$C(VGA_directrect_backingbuf),%edi
	addl	-60(%ebp),%edi
	movl	-20(%ebp),%ecx
	cld
	rep	movsb
	movl	-8(%ebp),%esi
	addl	-64(%ebp),%esi
	movl	-4(%ebp),%edi
	addl	-56(%ebp),%edi
	movl	-20(%ebp),%ecx
	cld
	rep	movsb
	incl	-44(%ebp)
	jmp	.Lvdrect_vga_begin_linear_j
.Lvdrect_vga_begin_linear_next_i:
	movl	-28(%ebp),%eax
	addl	%eax,-40(%ebp)
	jmp	.Lvdrect_vga_begin_linear_i

.Lvdrect_vga_begin_planar:
	movl	$0,-52(%ebp)		/* plane */
.Lvdrect_vga_begin_plane:
	movw	$0x3c4,%dx		/* sequencer index */
	movb	$2,%al			/* MAP_MASK */
	outb	%al,%dx
	movw	$0x3c5,%dx
	movl	$1,%eax
	movl	-52(%ebp),%ecx
	shll	%cl,%eax
	outb	%al,%dx
	movw	$0x3ce,%dx		/* graphics controller index */
	movb	$4,%al			/* READ_MAP */
	outb	%al,%dx
	movw	$0x3cf,%dx
	movl	-52(%ebp),%eax
	outb	%al,%dx
	movl	$0,-40(%ebp)		/* i */
.Lvdrect_vga_begin_planar_i:
	movl	-40(%ebp),%eax
	cmpl	-36(%ebp),%eax
	jge	.Lvdrect_vga_begin_next_plane
	movl	$0,-48(%ebp)		/* k */
.Lvdrect_vga_begin_planar_k:
	movl	-48(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lvdrect_vga_begin_planar_next_i
	movl	$0,-44(%ebp)		/* j */
.Lvdrect_vga_begin_planar_j:
	movl	-20(%ebp),%eax
	sarl	$2,%eax
	cmpl	%eax,-44(%ebp)
	jge	.Lvdrect_vga_begin_planar_next_k
	movl	-40(%ebp),%ebx
	addl	-48(%ebp),%ebx		/* output row */
	movl	-16(%ebp),%edx
	addl	%ebx,%edx
	imull	C(VGA_rowbytes),%edx
	movl	-12(%ebp),%eax
	sarl	$2,%eax
	addl	%eax,%edx
	addl	-44(%ebp),%edx
	movl	%edx,-56(%ebp)		/* direct byte offset */
	movl	%ebx,%eax
	leal	(%eax,%eax,2),%eax
	shll	$3,%eax
	movl	-44(%ebp),%edx
	shll	$2,%edx
	addl	%edx,%eax
	addl	-52(%ebp),%eax
	movl	%eax,-60(%ebp)		/* backing byte offset */
	movl	-40(%ebp),%eax
	movl	-32(%ebp),%ecx
	shrl	%cl,%eax
	leal	(%eax,%eax,2),%eax
	shll	$3,%eax
	movl	-44(%ebp),%edx
	shll	$2,%edx
	addl	%edx,%eax
	addl	-52(%ebp),%eax
	movl	%eax,-64(%ebp)		/* bitmap byte offset */
	movl	-4(%ebp),%esi
	addl	-56(%ebp),%esi
	movb	(%esi),%al
	movl	$C(VGA_directrect_backingbuf),%edi
	addl	-60(%ebp),%edi
	movb	%al,(%edi)
	movl	-8(%ebp),%esi
	addl	-64(%ebp),%esi
	movb	(%esi),%al
	movl	-4(%ebp),%edi
	addl	-56(%ebp),%edi
	movb	%al,(%edi)
	incl	-44(%ebp)
	jmp	.Lvdrect_vga_begin_planar_j
.Lvdrect_vga_begin_planar_next_k:
	incl	-48(%ebp)
	jmp	.Lvdrect_vga_begin_planar_k
.Lvdrect_vga_begin_planar_next_i:
	movl	-28(%ebp),%eax
	addl	%eax,-40(%ebp)
	jmp	.Lvdrect_vga_begin_planar_i
.Lvdrect_vga_begin_next_plane:
	incl	-52(%ebp)
	cmpl	$4,-52(%ebp)
	jl	.Lvdrect_vga_begin_plane
.Lvdrect_vga_begin_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	addl	$68,%esp
	leave
	ret

.section .rodata
.Lvdrect_aspect_1_5:
	.float	1.5

/* VGA_EndDirectRect(vid, mode, x, y, width, height). */
.text
.p2align 2
.globl C(VGA_EndDirectRect)
C(VGA_EndDirectRect):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$68,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%esi		/* lvid */
	movl	VD_VID_DIRECT_OFFSET(%esi),%eax
	testl	%eax,%eax
	je	.Lvdrect_vga_end_return
	movl	%eax,-4(%ebp)		/* direct framebuffer */
	movl	16(%ebp),%eax
	movl	%eax,-12(%ebp)		/* x */
	movl	20(%ebp),%eax
	movl	%eax,-16(%ebp)		/* y */
	movl	24(%ebp),%eax
	movl	%eax,-20(%ebp)		/* width */
	movl	28(%ebp),%eax
	movl	%eax,-24(%ebp)		/* height */
	flds	VD_VID_ASPECT_OFFSET(%esi)
	fcomps	.Lvdrect_aspect_1_5
	fnstsw	%ax
	sahf
	ja	.Lvdrect_vga_end_double
	movl	$1,-28(%ebp)		/* reps */
	movl	$0,-32(%ebp)		/* repshift */
	jmp	.Lvdrect_vga_end_rows
.Lvdrect_vga_end_double:
	movl	$2,-28(%ebp)
	movl	$1,-32(%ebp)
.Lvdrect_vga_end_rows:
	movl	-24(%ebp),%eax
	movl	-32(%ebp),%ecx
	shll	%cl,%eax
	movl	%eax,-36(%ebp)		/* output rows */
	movl	12(%ebp),%eax		/* mode */
	cmpl	$0,VD_MODE_PLANAR_OFFSET(%eax)
	jne	.Lvdrect_vga_end_planar
	movl	$0,-40(%ebp)		/* i */
.Lvdrect_vga_end_linear_i:
	movl	-40(%ebp),%eax
	cmpl	-36(%ebp),%eax
	jge	.Lvdrect_vga_end_return
	movl	$0,-44(%ebp)		/* j */
.Lvdrect_vga_end_linear_j:
	movl	-44(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lvdrect_vga_end_linear_next_i
	movl	-40(%ebp),%eax
	addl	-44(%ebp),%eax
	movl	%eax,-68(%ebp)		/* output row */
	movl	-16(%ebp),%edx
	movl	-32(%ebp),%ecx
	shll	%cl,%edx
	addl	%eax,%edx
	imull	C(VGA_rowbytes),%edx
	addl	-12(%ebp),%edx
	movl	%edx,-56(%ebp)		/* direct byte offset */
	movl	-68(%ebp),%eax
	leal	(%eax,%eax,2),%eax
	shll	$3,%eax
	movl	%eax,-60(%ebp)		/* backing byte offset */
	movl	$C(VGA_directrect_backingbuf),%esi
	addl	-60(%ebp),%esi
	movl	-4(%ebp),%edi
	addl	-56(%ebp),%edi
	movl	-20(%ebp),%ecx
	cld
	rep	movsb
	incl	-44(%ebp)
	jmp	.Lvdrect_vga_end_linear_j
.Lvdrect_vga_end_linear_next_i:
	movl	-28(%ebp),%eax
	addl	%eax,-40(%ebp)
	jmp	.Lvdrect_vga_end_linear_i

.Lvdrect_vga_end_planar:
	movl	$0,-52(%ebp)		/* plane */
.Lvdrect_vga_end_plane:
	movw	$0x3c4,%dx		/* sequencer index */
	movb	$2,%al			/* MAP_MASK */
	outb	%al,%dx
	movw	$0x3c5,%dx
	movl	$1,%eax
	movl	-52(%ebp),%ecx
	shll	%cl,%eax
	outb	%al,%dx
	movl	$0,-40(%ebp)		/* i */
.Lvdrect_vga_end_planar_i:
	movl	-40(%ebp),%eax
	cmpl	-36(%ebp),%eax
	jge	.Lvdrect_vga_end_next_plane
	movl	$0,-48(%ebp)		/* k */
.Lvdrect_vga_end_planar_k:
	movl	-48(%ebp),%eax
	cmpl	-28(%ebp),%eax
	jge	.Lvdrect_vga_end_planar_next_i
	movl	$0,-44(%ebp)		/* j */
.Lvdrect_vga_end_planar_j:
	movl	-20(%ebp),%eax
	sarl	$2,%eax
	cmpl	%eax,-44(%ebp)
	jge	.Lvdrect_vga_end_planar_next_k
	movl	-40(%ebp),%ebx
	addl	-48(%ebp),%ebx		/* output row */
	movl	-16(%ebp),%edx
	addl	%ebx,%edx
	imull	C(VGA_rowbytes),%edx
	movl	-12(%ebp),%eax
	sarl	$2,%eax
	addl	%eax,%edx
	addl	-44(%ebp),%edx
	movl	%edx,-56(%ebp)		/* direct byte offset */
	movl	%ebx,%eax
	leal	(%eax,%eax,2),%eax
	shll	$3,%eax
	movl	-44(%ebp),%edx
	shll	$2,%edx
	addl	%edx,%eax
	addl	-52(%ebp),%eax
	movl	%eax,-60(%ebp)		/* backing byte offset */
	movl	-4(%ebp),%esi
	addl	-56(%ebp),%esi
	movl	$C(VGA_directrect_backingbuf),%edi
	addl	-60(%ebp),%edi
	movb	(%edi),%al
	movb	%al,(%esi)
	incl	-44(%ebp)
	jmp	.Lvdrect_vga_end_planar_j
.Lvdrect_vga_end_planar_next_k:
	incl	-48(%ebp)
	jmp	.Lvdrect_vga_end_planar_k
.Lvdrect_vga_end_planar_next_i:
	movl	-28(%ebp),%eax
	addl	%eax,-40(%ebp)
	jmp	.Lvdrect_vga_end_planar_i
.Lvdrect_vga_end_next_plane:
	incl	-52(%ebp)
	cmpl	$4,-52(%ebp)
	jl	.Lvdrect_vga_end_plane
.Lvdrect_vga_end_return:
	popl	%edi
	popl	%esi
	popl	%ebx
	addl	$68,%esp
	leave
	ret

#undef VID_UPDATE_SET_MODE
#undef VID_UPDATE_DEFAULT_MODE
#undef VID_UPDATE_SET_CVAR
#undef VID_UPDATE_NO_VESA_MESSAGE
#endif /* ASM486_VID_UPDATE */
