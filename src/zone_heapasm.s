/* i486 zone heap initialization, tagged allocation, and free/coalesce. */
#include "asm_i386.h"
#include "asm_zoneheap.h"
#undef i386
.arch i486
.code32

#ifdef ASM486_ZONE_HEAP
.text
.p2align 2
.globl C(Z_ClearZone)
C(Z_ClearZone):
	movl	4(%esp),%eax		/* zone */
	leal	ZH_MEMZONE_SIZE(%eax),%edx	/* first block */
	leal	ZH_MEMZONE_BLOCKLIST_OFFSET(%eax),%ecx /* sentinel */
	movl	%edx,ZH_MEMZONE_BLOCKLIST_NEXT_OFFSET(%eax)
	movl	%edx,ZH_MEMZONE_BLOCKLIST_PREV_OFFSET(%eax)
	movl	$1,ZH_MEMZONE_BLOCKLIST_TAG_OFFSET(%eax)
	movl	$0,ZH_MEMZONE_BLOCKLIST_ID_OFFSET(%eax)
	movl	$0,ZH_MEMZONE_BLOCKLIST_SIZE_OFFSET(%eax)
	movl	%edx,ZH_MEMZONE_ROVER_OFFSET(%eax)
	movl	%ecx,ZH_MEMBLOCK_PREV_OFFSET(%edx)
	movl	%ecx,ZH_MEMBLOCK_NEXT_OFFSET(%edx)
	movl	$0,ZH_MEMBLOCK_TAG_OFFSET(%edx)
	movl	$ZH_ZONE_ID,ZH_MEMBLOCK_ID_OFFSET(%edx)
	movl	8(%esp),%ecx
	subl	$ZH_MEMZONE_SIZE,%ecx
	movl	%ecx,ZH_MEMBLOCK_SIZE_OFFSET(%edx)
	ret

.p2align 2
.globl C(Z_Free)
C(Z_Free):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* payload pointer */
	testl	%ebx,%ebx
	jne	.Lzone_free_pointer
	pushl	$.Lzone_free_null_text
	call	C(Sys_Error)
	addl	$4,%esp
	/* Match the fatal C path if Sys_Error unexpectedly returns. */

.Lzone_free_pointer:
	leal	-ZH_MEMBLOCK_SIZE(%ebx),%esi
	cmpl	$ZH_ZONE_ID,ZH_MEMBLOCK_ID_OFFSET(%esi)
	je	.Lzone_free_id_valid
	pushl	$.Lzone_free_id_text
	call	C(Sys_Error)
	addl	$4,%esp

.Lzone_free_id_valid:
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%esi)
	jne	.Lzone_free_tag_valid
	pushl	$.Lzone_free_freed_text
	call	C(Sys_Error)
	addl	$4,%esp

.Lzone_free_tag_valid:
	movl	$0,ZH_MEMBLOCK_TAG_OFFSET(%esi)
	movl	ZH_MEMBLOCK_PREV_OFFSET(%esi),%eax
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%eax)
	jne	.Lzone_free_next
#ifdef PROFILE486
	incl	C(bench486_zone_coalesces)
#endif
	movl	ZH_MEMBLOCK_SIZE_OFFSET(%esi),%edx
	addl	%edx,ZH_MEMBLOCK_SIZE_OFFSET(%eax)
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%edx
	movl	%edx,ZH_MEMBLOCK_NEXT_OFFSET(%eax)
	movl	%eax,ZH_MEMBLOCK_PREV_OFFSET(%edx)
	movl	C(mainzone),%ecx
	cmpl	ZH_MEMZONE_ROVER_OFFSET(%ecx),%esi
	jne	.Lzone_free_prev_rover_done
	movl	%eax,ZH_MEMZONE_ROVER_OFFSET(%ecx)
.Lzone_free_prev_rover_done:
	movl	%eax,%esi

.Lzone_free_next:
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%eax
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%eax)
	jne	.Lzone_free_done
#ifdef PROFILE486
	incl	C(bench486_zone_coalesces)
#endif
	movl	ZH_MEMBLOCK_SIZE_OFFSET(%eax),%edx
	addl	%edx,ZH_MEMBLOCK_SIZE_OFFSET(%esi)
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%eax),%edx
	movl	%edx,ZH_MEMBLOCK_NEXT_OFFSET(%esi)
	movl	%esi,ZH_MEMBLOCK_PREV_OFFSET(%edx)
	movl	C(mainzone),%ecx
	cmpl	ZH_MEMZONE_ROVER_OFFSET(%ecx),%eax
	jne	.Lzone_free_done
	movl	%esi,ZH_MEMZONE_ROVER_OFFSET(%ecx)

.Lzone_free_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(Z_TagMalloc)
C(Z_TagMalloc):
	pushl	%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	20(%esp),%ebx		/* requested payload size */
	movl	24(%esp),%ebp		/* allocation tag */
	testl	%ebp,%ebp
	jne	.Lzone_tag_size
	pushl	$.Lzone_tag_zero_text
	call	C(Sys_Error)
	addl	$4,%esp
	/* Match the fatal C path if Sys_Error unexpectedly returns. */

.Lzone_tag_size:
	addl	$ZH_MEMBLOCK_SIZE+4,%ebx
	addl	$7,%ebx
	andl	$-8,%ebx
	movl	C(mainzone),%ecx
	movl	ZH_MEMZONE_ROVER_OFFSET(%ecx),%esi	/* base */
	movl	%esi,%edi			/* rover */
	movl	ZH_MEMBLOCK_PREV_OFFSET(%esi),%eax	/* stop before a full loop */

.Lzone_tag_scan:
#ifdef PROFILE486
	incl	C(bench486_zone_scan_iterations)
#endif
	cmpl	%eax,%edi
	je	.Lzone_tag_failed
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%edi)
	je	.Lzone_tag_scan_free
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%edi),%edi
	movl	%edi,%esi
	jmp	.Lzone_tag_scan_test

.Lzone_tag_scan_free:
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%edi),%edi

.Lzone_tag_scan_test:
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%esi)
	jne	.Lzone_tag_scan
	cmpl	%ebx,ZH_MEMBLOCK_SIZE_OFFSET(%esi)
	jl	.Lzone_tag_scan

	/* Found a free block. Preserve fragments only when they exceed 64 bytes. */
	movl	ZH_MEMBLOCK_SIZE_OFFSET(%esi),%eax
	subl	%ebx,%eax			/* remaining bytes */
	cmpl	$ZH_MIN_FRAGMENT,%eax
	jle	.Lzone_tag_no_split
#ifdef PROFILE486
	incl	C(bench486_zone_splits)
#endif
	leal	(%esi,%ebx),%edx		/* new free block */
	movl	%eax,ZH_MEMBLOCK_SIZE_OFFSET(%edx)
	movl	$0,ZH_MEMBLOCK_TAG_OFFSET(%edx)
	movl	%esi,ZH_MEMBLOCK_PREV_OFFSET(%edx)
	movl	$ZH_ZONE_ID,ZH_MEMBLOCK_ID_OFFSET(%edx)
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%ecx
	movl	%ecx,ZH_MEMBLOCK_NEXT_OFFSET(%edx)
	movl	%edx,ZH_MEMBLOCK_PREV_OFFSET(%ecx)
	movl	%edx,ZH_MEMBLOCK_NEXT_OFFSET(%esi)
	movl	%ebx,ZH_MEMBLOCK_SIZE_OFFSET(%esi)

.Lzone_tag_no_split:
	movl	%ebp,ZH_MEMBLOCK_TAG_OFFSET(%esi)
	movl	C(mainzone),%ecx
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%eax
	movl	%eax,ZH_MEMZONE_ROVER_OFFSET(%ecx)
	movl	$ZH_ZONE_ID,ZH_MEMBLOCK_ID_OFFSET(%esi)
	movl	ZH_MEMBLOCK_SIZE_OFFSET(%esi),%eax
	leal	-4(%esi,%eax),%edx
	movl	$ZH_ZONE_ID,(%edx)
	leal	ZH_MEMBLOCK_SIZE(%esi),%eax
	jmp	.Lzone_tag_done

.Lzone_tag_failed:
#ifdef PROFILE486
	incl	C(bench486_zone_failed_allocations)
#endif
	xorl	%eax,%eax

.Lzone_tag_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	popl	%ebp
	ret

.p2align 2
.globl C(Z_Malloc)
C(Z_Malloc):
	pushl	%ebx
	pushl	%esi
	movl	12(%esp),%ebx		/* requested payload size */
#ifdef PROFILE486
	incl	C(bench486_zone_malloc_calls)
	addl	%ebx,C(bench486_zone_malloc_bytes)
#endif
#ifdef PARANOID
	call	C(Z_CheckHeap)
#endif
	pushl	$1
	pushl	%ebx
	call	C(Z_TagMalloc)
	addl	$8,%esp
	testl	%eax,%eax
	jne	.Lzone_malloc_zero
	pushl	%ebx
	pushl	$.Lzone_malloc_failed_text
	call	C(Sys_Error)
	addl	$8,%esp
	/* Match the C path if Sys_Error unexpectedly returns. */
	xorl	%eax,%eax

.Lzone_malloc_zero:
	movl	%eax,%esi
	pushl	%ebx
	pushl	$0
	pushl	%esi
	call	C(Q_memset)
	addl	$12,%esp
	movl	%esi,%eax
	popl	%esi
	popl	%ebx
	ret

.section .rodata
.Lzone_free_null_text:
	.asciz	"Z_Free: NULL pointer"
.Lzone_free_id_text:
	.asciz	"Z_Free: freed a pointer without ZONEID"
.Lzone_free_freed_text:
	.asciz	"Z_Free: freed a freed pointer"
.Lzone_tag_zero_text:
	.asciz	"Z_TagMalloc: tried to use a 0 tag"
.Lzone_malloc_failed_text:
	.asciz	"Z_Malloc: failed on allocation of %i bytes"
#endif /* ASM486_ZONE_HEAP */
