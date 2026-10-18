/* i486 per-frame video update state machine from vid_dos.c:VID_Update. */
#include "asm_i386.h"
#include "asm_vidupdate.h"
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
#undef VID_UPDATE_SET_MODE
#undef VID_UPDATE_DEFAULT_MODE
#undef VID_UPDATE_SET_CVAR
#undef VID_UPDATE_NO_VESA_MESSAGE
#endif /* ASM486_VID_UPDATE */
