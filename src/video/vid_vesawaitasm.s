/* Per-frame VESA retrace gates and VGA status-port waits. */
#include "asm_i386.h"
#include "video/asm_vesawait.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_VESA_WAIT
	.text
	.p2align 2
	.globl C(VID_ExtraWaitDisplayIfRequested)
C(VID_ExtraWaitDisplayIfRequested):
	cmpl	$0x40000000,C(vid_wait)+VWA_CVAR_VALUE_OFFSET
	jne	.Lvesa_wait_display_done
	cmpl	$0,C(VID_extra_display_enable_exists)
	je	.Lvesa_wait_display_done
#ifdef ASM486_VESA_WAIT_FIXTURE
#ifdef ASM486_VESA_SWAP_BUFFERS_FIXTURE
	cmpl	$0,C(bench486_vesa_swap_fixture_active)
	jne	.Lvesa_wait_display_swap_fixture
#endif
	cmpl	$0,C(bench486_vesa_wait_fixture_active)
	jne	.Lvesa_wait_display_fixture_poll
#endif
	movw	$0x3da,%dx
.Lvesa_wait_display_poll:
	inb	%dx,%al
	testb	$1,%al
	jnz	.Lvesa_wait_display_poll
.Lvesa_wait_display_done:
	ret
#ifdef ASM486_VESA_WAIT_FIXTURE
	.p2align 2
.Lvesa_wait_display_fixture_poll:
	pushl	$0x3da
	call	C(Bench486VesaWaitReadStatus)
	addl	$4,%esp
	testb	$1,%al
	jnz	.Lvesa_wait_display_fixture_poll
	ret
#ifdef ASM486_VESA_SWAP_BUFFERS_FIXTURE
.Lvesa_wait_display_swap_fixture:
	call	C(Bench486VesaSwapWaitDisplayEnable)
	ret
#endif
#endif

	.p2align 2
	.globl C(VID_ExtraWaitVsyncIfRequested)
C(VID_ExtraWaitVsyncIfRequested):
	cmpl	$0x3f800000,C(vid_wait)+VWA_CVAR_VALUE_OFFSET
	jne	.Lvesa_wait_vsync_done
	cmpl	$0,C(VID_extra_vsync_exists)
	je	.Lvesa_wait_vsync_done
#ifdef ASM486_VESA_WAIT_FIXTURE
#ifdef ASM486_VESA_SWAP_BUFFERS_FIXTURE
	cmpl	$0,C(bench486_vesa_swap_fixture_active)
	jne	.Lvesa_wait_vsync_swap_fixture
#endif
	cmpl	$0,C(bench486_vesa_wait_fixture_active)
	jne	.Lvesa_wait_vsync_fixture_poll
#endif
	movw	$0x3da,%dx
.Lvesa_wait_vsync_poll:
	inb	%dx,%al
	testb	$8,%al
	jz	.Lvesa_wait_vsync_poll
.Lvesa_wait_vsync_done:
	ret
#ifdef ASM486_VESA_WAIT_FIXTURE
	.p2align 2
.Lvesa_wait_vsync_fixture_poll:
	pushl	$0x3da
	call	C(Bench486VesaWaitReadStatus)
	addl	$4,%esp
	testb	$8,%al
	jz	.Lvesa_wait_vsync_fixture_poll
	ret
#ifdef ASM486_VESA_SWAP_BUFFERS_FIXTURE
.Lvesa_wait_vsync_swap_fixture:
	call	C(Bench486VesaSwapWaitVsync)
	ret
#endif
#endif

	.p2align 2
	.globl C(VID_ExtraDisplayStartWaitFlags)
C(VID_ExtraDisplayStartWaitFlags):
	cmpl	$0x3f800000,C(vid_wait)+VWA_CVAR_VALUE_OFFSET
	jne	.Lvesa_wait_no_display_start_flag
	movl	$0x80,%eax
	ret
.Lvesa_wait_no_display_start_flag:
	xorl	%eax,%eax
	ret
#endif /* ASM486_VESA_WAIT */
