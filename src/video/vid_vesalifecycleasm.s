#include "asm_i386.h"
#include "video/asm_vesalifecycle.h"

#ifdef ASM486_VESA_LIFECYCLE

#ifdef ASM486_VESA_LIFECYCLE_FIXTURE
#define VESA_LIFECYCLE_FREE_MAPPING C(Bench486VesaLifecycleFreeMapping)
#define VESA_LIFECYCLE_FREE_MEMORY C(Bench486VesaLifecycleFreeDosMemory)
#else
#define VESA_LIFECYCLE_FREE_MAPPING C(__dpmi_free_physical_address_mapping)
#define VESA_LIFECYCLE_FREE_MEMORY C(dos_freememory)
#endif

	.text
	.p2align 4,,15
	.globl C(VID_ExtraReleaseMode)
C(VID_ExtraReleaseMode):
	cmpl	$0,C(VID_extra_mapped)
	je	.Lvesalifecycle_unmapped
	leal	C(VID_extra_mapping),%eax
	pushl	%eax
	call	VESA_LIFECYCLE_FREE_MAPPING
	addl	$4,%esp
.Lvesalifecycle_unmapped:
	movl	$0,C(VID_extra_mapped)
	movl	$0,C(VID_membase)
	movl	$0,C(VGA_pcurmode)
	movl	$1,C(VID_extra_palette_ok)
	ret

	.p2align 4,,15
	.globl C(VID_ShutdownExtra)
C(VID_ShutdownExtra):
	call	C(VID_ExtraReleaseMode)
	movl	C(VID_extra_palette),%eax
	testl	%eax,%eax
	je	.Lvesalifecycle_shutdown_done
	pushl	%eax
	call	VESA_LIFECYCLE_FREE_MEMORY
	addl	$4,%esp
	movl	$0,C(VID_extra_palette)
.Lvesalifecycle_shutdown_done:
	ret

	.p2align 4,,15
	.globl C(VID_ExtraPaletteOK)
C(VID_ExtraPaletteOK):
	movl	C(VID_extra_palette_ok),%eax
	ret

#undef VESA_LIFECYCLE_FREE_MAPPING
#undef VESA_LIFECYCLE_FREE_MEMORY
#endif
