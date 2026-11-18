/* i486 zone heap initialization, tagged allocation, and free/coalesce. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#include "asm_i386.h"
#include "memory/asm_zoneheap.h"
#include "memory/asm_cachealloc.h"
#include "memory/asm_hunknamedalloc.h"
#include "memory/asm_cachetryalloc.h"
#undef i386
.arch i486
.arch .387
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

.p2align 2
.globl C(Cache_Init)
C(Cache_Init):
	movl	$C(cache_head),%eax
	movl	%eax,ZH_CACHE_HEAD_NEXT_OFFSET(%eax)
	movl	%eax,ZH_CACHE_HEAD_PREV_OFFSET(%eax)
	movl	%eax,ZH_CACHE_HEAD_LRU_NEXT_OFFSET(%eax)
	movl	%eax,ZH_CACHE_HEAD_LRU_PREV_OFFSET(%eax)
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$C(Cache_Flush)
	pushl	$.Lzone_cache_flush_command
	call	C(Bench486MemoryAddCommand)
#else
	pushl	$C(Cache_Flush)
	pushl	$.Lzone_cache_flush_command
	call	C(Cmd_AddCommand)
#endif
	addl	$8,%esp
	ret

.p2align 2
.globl C(Memory_Init)
C(Memory_Init):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$4,%esp			/* zonesize local */
	movl	8(%ebp),%eax
	movl	%eax,C(hunk_base)
	movl	12(%ebp),%eax
	movl	%eax,C(hunk_size)
	movl	$0,C(hunk_low_used)
	movl	$0,C(hunk_high_used)
	movl	$0,C(hunk_low_peak_used)
	movl	$0,C(hunk_high_peak_used)
	movl	$0xc000,-16(%ebp)		/* DYNAMIC_SIZE */
	call	C(Cache_Init)
	pushl	$.Lzone_memory_zone_parameter
	call	C(COM_CheckParm)
	addl	$4,%esp
	movl	%eax,%esi			/* parameter index */
	testl	%esi,%esi
	je	.Lzone_memory_allocate
	movl	C(com_argc),%eax
	decl	%eax
	cmpl	%eax,%esi
	jge	.Lzone_memory_missing_zone_size
	movl	C(com_argv),%edx
	movl	4(%edx,%esi,4),%eax	/* com_argv[p + 1] */
	pushl	%eax
	call	C(Q_atoi)
	addl	$4,%esp
	imull	$1024,%eax
	movl	%eax,-16(%ebp)
	jmp	.Lzone_memory_allocate

.Lzone_memory_missing_zone_size:
	pushl	$.Lzone_memory_missing_size_text
	call	C(Sys_Error)
	addl	$4,%esp			/* C retains the default size if it returns */

.Lzone_memory_allocate:
	movl	-16(%ebp),%eax
	movl	%eax,C(memory_zone_size)
	pushl	$.Lzone_memory_zone_name
	pushl	-16(%ebp)
	call	C(Hunk_AllocName)
	addl	$8,%esp
	movl	%eax,C(mainzone)
	pushl	-16(%ebp)
	pushl	%eax
	call	C(Z_ClearZone)
	addl	$8,%esp
	addl	$4,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.p2align 2
.globl C(Z_Print)
C(Z_Print):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%ebx		/* zone */
	pushl	$0
	pushl	%ebx
	pushl	$ZH_PRINT_ZONE_HEADER
	call	C(Zone_PrintTrace)
	addl	$12,%esp
	leal	ZH_MEMZONE_BLOCKLIST_OFFSET(%ebx),%edi /* sentinel */
	movl	ZH_MEMZONE_BLOCKLIST_NEXT_OFFSET(%ebx),%esi

.Lzone_print_loop:
	pushl	%esi
	pushl	%ebx
	pushl	$ZH_PRINT_ZONE_BLOCK
	call	C(Zone_PrintTrace)
	addl	$12,%esp
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%eax
	cmpl	%edi,%eax
	je	.Lzone_print_done

	movl	%esi,%edx
	addl	ZH_MEMBLOCK_SIZE_OFFSET(%esi),%edx
	cmpl	%eax,%edx
	je	.Lzone_print_backlink
	pushl	%esi
	pushl	%ebx
	pushl	$ZH_PRINT_ZONE_BAD_BOUNDARY
	call	C(Zone_PrintTrace)
	addl	$12,%esp
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%eax

.Lzone_print_backlink:
	cmpl	%esi,ZH_MEMBLOCK_PREV_OFFSET(%eax)
	je	.Lzone_print_adjacent_free
	pushl	%esi
	pushl	%ebx
	pushl	$ZH_PRINT_ZONE_BAD_BACKLINK
	call	C(Zone_PrintTrace)
	addl	$12,%esp
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%eax

.Lzone_print_adjacent_free:
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%esi)
	jne	.Lzone_print_advance
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%eax)
	jne	.Lzone_print_advance
	pushl	%esi
	pushl	%ebx
	pushl	$ZH_PRINT_ZONE_ADJACENT_FREE
	call	C(Zone_PrintTrace)
	addl	$12,%esp
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%eax

.Lzone_print_advance:
	movl	%eax,%esi
	jmp	.Lzone_print_loop

.Lzone_print_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(Zone_PrintTrace)
C(Zone_PrintTrace):
#ifdef ASM486_ZONE_HEAP_FIXTURE
	movl	4(%esp),%eax		/* kind */
	movl	8(%esp),%edx		/* zone */
	movl	12(%esp),%ecx		/* block */
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	call	C(Bench486ZonePrintEvent)
	addl	$12,%esp
	ret
#else
	movl	4(%esp),%eax
	cmpl	$ZH_PRINT_ZONE_HEADER,%eax
	je	.Lzone_print_trace_header
	cmpl	$ZH_PRINT_ZONE_BLOCK,%eax
	je	.Lzone_print_trace_block
	cmpl	$ZH_PRINT_ZONE_BAD_BOUNDARY,%eax
	je	.Lzone_print_trace_bad_boundary
	cmpl	$ZH_PRINT_ZONE_BAD_BACKLINK,%eax
	je	.Lzone_print_trace_bad_backlink
	cmpl	$ZH_PRINT_ZONE_ADJACENT_FREE,%eax
	je	.Lzone_print_trace_adjacent_free
	ret

.Lzone_print_trace_header:
	movl	C(mainzone),%eax
	pushl	%eax
	pushl	ZH_MEMZONE_SIZE_OFFSET(%eax)
	pushl	$.Lzone_print_header_format
	call	C(Con_Printf)
	addl	$12,%esp
	ret

.Lzone_print_trace_block:
	movl	12(%esp),%ecx
	pushl	ZH_MEMBLOCK_TAG_OFFSET(%ecx)
	pushl	ZH_MEMBLOCK_SIZE_OFFSET(%ecx)
	pushl	%ecx
	pushl	$.Lzone_print_block_format
	call	C(Con_Printf)
	addl	$16,%esp
	ret

.Lzone_print_trace_bad_boundary:
	pushl	$.Lzone_print_bad_boundary_text
	call	C(Con_Printf)
	addl	$4,%esp
	ret

.Lzone_print_trace_bad_backlink:
	pushl	$.Lzone_print_bad_backlink_text
	call	C(Con_Printf)
	addl	$4,%esp
	ret

.Lzone_print_trace_adjacent_free:
	pushl	$.Lzone_print_adjacent_free_text
	call	C(Con_Printf)
	addl	$4,%esp
	ret
#endif

.p2align 2
.globl C(Zone_CachePrintTrace)
C(Zone_CachePrintTrace):
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	4(%esp)
	call	C(Bench486CachePrintEvent)
	addl	$4,%esp
	ret
#else
	movl	4(%esp),%eax		/* cache system */
	pushl	CA_CACHE_SYSTEM_NAME_OFFSET(%eax)
	pushl	CA_CACHE_SYSTEM_SIZE_OFFSET(%eax)
	pushl	$.Lzone_cache_print_format
	call	C(Con_Printf)
	addl	$12,%esp
	ret
#endif

.p2align 2
.globl C(Cache_Print)
C(Cache_Print):
	pushl	%ebx
	pushl	%esi
	movl	$C(cache_head),%ebx
	movl	CTA_CACHE_HEAD_NEXT_OFFSET(%ebx),%esi

.Lzone_cache_print_loop:
	cmpl	%ebx,%esi
	je	.Lzone_cache_print_done
	pushl	%esi
	call	C(Zone_CachePrintTrace)
	addl	$4,%esp
	movl	CTA_CACHE_NEXT_OFFSET(%esi),%esi
	jmp	.Lzone_cache_print_loop

.Lzone_cache_print_done:
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(Zone_CacheReportTrace)
C(Zone_CacheReportTrace):
#ifdef ASM486_ZONE_HEAP_FIXTURE
	movl	4(%esp),%eax		/* low doubleword */
	movl	8(%esp),%edx		/* high doubleword */
	pushl	%edx
	pushl	%eax
	call	C(Bench486CacheReportEvent)
	addl	$8,%esp
	ret
#else
	movl	4(%esp),%eax		/* low doubleword */
	movl	8(%esp),%edx		/* high doubleword */
	pushl	%edx
	pushl	%eax
	pushl	$.Lzone_cache_report_format
	call	C(Con_DPrintf)
	addl	$12,%esp
	ret
#endif

.p2align 2
.globl C(Cache_Report)
C(Cache_Report):
	pushl	%ebp
	movl	%esp,%ebp
	subl	$16,%esp
	movl	C(hunk_size),%eax
	subl	C(hunk_high_used),%eax
	subl	C(hunk_low_used),%eax
	movl	%eax,-4(%ebp)
	movl	$ZH_CACHE_REPORT_MB_SCALE_BITS,-16(%ebp)
	flds	-16(%ebp)
	fimull	-4(%ebp)
	fstpl	-12(%ebp)
	pushl	-8(%ebp)
	pushl	-12(%ebp)
	call	C(Zone_CacheReportTrace)
	addl	$8,%esp
	leave
	ret

.p2align 2
.globl C(Zone_HunkPrintTrace)
C(Zone_HunkPrintTrace):
#ifdef ASM486_ZONE_HEAP_FIXTURE
	movl	4(%esp),%eax		/* kind */
	movl	8(%esp),%edx		/* hunk */
	movl	12(%esp),%ecx		/* value */
	pushl	%ecx
	pushl	%edx
	pushl	%eax
	call	C(Bench486HunkPrintEvent)
	addl	$12,%esp
	ret
#else
	pushl	%ebp
	movl	%esp,%ebp
	subl	$16,%esp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	8(%ebp),%eax		/* kind */
	cmpl	$HNA_HUNK_PRINT_TOTAL_SIZE,%eax
	je	.Lzone_hunk_print_trace_total
	cmpl	$HNA_HUNK_PRINT_SEPARATOR,%eax
	je	.Lzone_hunk_print_trace_separator
	cmpl	$HNA_HUNK_PRINT_REMAINING,%eax
	je	.Lzone_hunk_print_trace_remaining
	cmpl	$HNA_HUNK_PRINT_ALLOCATION,%eax
	je	.Lzone_hunk_print_trace_allocation
	cmpl	$HNA_HUNK_PRINT_GROUP_TOTAL,%eax
	je	.Lzone_hunk_print_trace_group
	cmpl	$HNA_HUNK_PRINT_BLOCKS,%eax
	je	.Lzone_hunk_print_trace_blocks
	pushl	$.Lzone_hunk_print_bad_trace_text
	call	C(Sys_Error)
	addl	$4,%esp
	jmp	.Lzone_hunk_print_trace_done

.Lzone_hunk_print_trace_total:
	pushl	16(%ebp)
	pushl	$.Lzone_hunk_print_total_format
	call	C(Con_Printf)
	addl	$8,%esp
	jmp	.Lzone_hunk_print_trace_done

.Lzone_hunk_print_trace_separator:
	pushl	$.Lzone_hunk_print_separator_text
	call	C(Con_Printf)
	addl	$4,%esp
	jmp	.Lzone_hunk_print_trace_done

.Lzone_hunk_print_trace_remaining:
	pushl	16(%ebp)
	pushl	$.Lzone_hunk_print_remaining_format
	call	C(Con_Printf)
	addl	$8,%esp
	jmp	.Lzone_hunk_print_trace_done

.Lzone_hunk_print_trace_allocation:
	movl	12(%ebp),%esi		/* hunk */
	movl	HNA_HUNK_NAME_OFFSET(%esi),%eax
	movl	%eax,-16(%ebp)
	movl	HNA_HUNK_NAME_OFFSET+4(%esi),%eax
	movl	%eax,-12(%ebp)
	movb	$0,-8(%ebp)
	leal	-16(%ebp),%eax
	pushl	%eax
	pushl	16(%ebp)
	pushl	%esi
	pushl	$.Lzone_hunk_print_allocation_format
	call	C(Con_Printf)
	addl	$16,%esp
	jmp	.Lzone_hunk_print_trace_done

.Lzone_hunk_print_trace_group:
	movl	12(%ebp),%esi		/* hunk */
	movl	HNA_HUNK_NAME_OFFSET(%esi),%eax
	movl	%eax,-16(%ebp)
	movl	HNA_HUNK_NAME_OFFSET+4(%esi),%eax
	movl	%eax,-12(%ebp)
	movb	$0,-8(%ebp)
	leal	-16(%ebp),%eax
	pushl	%eax
	pushl	16(%ebp)
	pushl	$.Lzone_hunk_print_group_format
	call	C(Con_Printf)
	addl	$12,%esp
	jmp	.Lzone_hunk_print_trace_done

.Lzone_hunk_print_trace_blocks:
	pushl	16(%ebp)
	pushl	$.Lzone_hunk_print_blocks_format
	call	C(Con_Printf)
	addl	$8,%esp

.Lzone_hunk_print_trace_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
#endif

.p2align 2
.globl C(Zone_HunkPrintError)
C(Zone_HunkPrintError):
#ifdef ASM486_ZONE_HEAP_FIXTURE
	movl	4(%esp),%eax
	cmpl	$HNA_HUNK_PRINT_ERROR_SENTINAL,%eax
	je	.Lzone_hunk_print_error_sentinal_fixture
	pushl	$.Lzone_hunk_check_size_text
	jmp	.Lzone_hunk_print_error_fixture_call
.Lzone_hunk_print_error_sentinal_fixture:
	pushl	$.Lzone_hunk_check_sentinal_text
.Lzone_hunk_print_error_fixture_call:
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
	ret
#else
	movl	4(%esp),%eax
	cmpl	$HNA_HUNK_PRINT_ERROR_SENTINAL,%eax
	je	.Lzone_hunk_print_error_sentinal
	pushl	$.Lzone_hunk_check_size_text
	jmp	.Lzone_hunk_print_error_call
.Lzone_hunk_print_error_sentinal:
	pushl	$.Lzone_hunk_check_sentinal_text
.Lzone_hunk_print_error_call:
	call	C(Sys_Error)
	addl	$4,%esp
	ret
#endif

.p2align 2
.globl C(Hunk_Print)
C(Hunk_Print):
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$24,%esp

	movl	C(hunk_base),%ebx
	movl	%ebx,%esi
	movl	C(hunk_low_used),%eax
	leal	(%ebx,%eax),%edi		/* end of low hunk */
	movl	C(hunk_size),%eax
	leal	(%ebx,%eax),%edx
	movl	%edx,-16(%ebp)		/* end of high hunk */
	movl	C(hunk_high_used),%ecx
	subl	%ecx,%edx
	movl	%edx,-20(%ebp)		/* start of high hunk */
	movl	$0,-24(%ebp)		/* grouped byte total */
	movl	$0,-28(%ebp)		/* allocation count */
	movl	8(%ebp),%eax
	movl	%eax,-32(%ebp)		/* print every allocation */

	pushl	C(hunk_size)
	pushl	$0
	pushl	$HNA_HUNK_PRINT_TOTAL_SIZE
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp
	pushl	$0
	pushl	$0
	pushl	$HNA_HUNK_PRINT_SEPARATOR
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp

.Lhunk_print_loop:
	cmpl	%edi,%esi
	jne	.Lhunk_print_not_low_end
	pushl	$0
	pushl	$0
	pushl	$HNA_HUNK_PRINT_SEPARATOR
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp
	movl	C(hunk_size),%eax
	subl	C(hunk_low_used),%eax
	subl	C(hunk_high_used),%eax
	pushl	%eax
	pushl	$0
	pushl	$HNA_HUNK_PRINT_REMAINING
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp
	pushl	$0
	pushl	$0
	pushl	$HNA_HUNK_PRINT_SEPARATOR
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp
	movl	-20(%ebp),%esi

.Lhunk_print_not_low_end:
	cmpl	-16(%ebp),%esi
	je	.Lhunk_print_done
	cmpl	$HNA_HUNK_SENTINAL_VALUE,HNA_HUNK_SENTINAL_OFFSET(%esi)
	je	.Lhunk_print_valid_sentinal
	pushl	$HNA_HUNK_PRINT_ERROR_SENTINAL
	call	C(Zone_HunkPrintError)
	addl	$4,%esp

.Lhunk_print_valid_sentinal:
	movl	HNA_HUNK_SIZE_OFFSET(%esi),%eax
	leal	(%esi,%eax),%edx
	movl	%edx,-36(%ebp)		/* next hunk header */
	cmpl	$HNA_HUNK_SIZE,%eax
	jl	.Lhunk_print_bad_size
	cmpl	-16(%ebp),%edx
	jbe	.Lhunk_print_valid_size

.Lhunk_print_bad_size:
	pushl	$HNA_HUNK_PRINT_ERROR_SIZE
	call	C(Zone_HunkPrintError)
	addl	$4,%esp
	movl	HNA_HUNK_SIZE_OFFSET(%esi),%eax

.Lhunk_print_valid_size:
	incl	-28(%ebp)
	addl	%eax,-24(%ebp)
	cmpl	$0,-32(%ebp)
	je	.Lhunk_print_group_check
	pushl	%eax
	pushl	%esi
	pushl	$HNA_HUNK_PRINT_ALLOCATION
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp

.Lhunk_print_group_check:
	movl	-36(%ebp),%edx
	cmpl	%edi,%edx
	je	.Lhunk_print_group_end
	cmpl	-16(%ebp),%edx
	je	.Lhunk_print_group_end
	leal	HNA_HUNK_NAME_OFFSET(%esi),%eax
	leal	HNA_HUNK_NAME_OFFSET(%edx),%ecx
	movl	$HNA_HUNK_NAME_SIZE,%edx
.Lhunk_print_name_compare:
	movzbl	(%ecx),%ebx
	cmpb	(%eax),%bl
	jne	.Lhunk_print_group_end
	testb	%bl,%bl
	je	.Lhunk_print_next
	incl	%eax
	incl	%ecx
	decl	%edx
	jne	.Lhunk_print_name_compare
	jmp	.Lhunk_print_next

.Lhunk_print_group_end:
	cmpl	$0,-32(%ebp)
	jne	.Lhunk_print_reset_group
	movl	-24(%ebp),%eax
	pushl	%eax
	pushl	%esi
	pushl	$HNA_HUNK_PRINT_GROUP_TOTAL
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp

.Lhunk_print_reset_group:
	movl	$0,-24(%ebp)

.Lhunk_print_next:
	movl	-36(%ebp),%esi
	jmp	.Lhunk_print_loop

.Lhunk_print_done:
	pushl	$0
	pushl	$0
	pushl	$HNA_HUNK_PRINT_SEPARATOR
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp
	pushl	-28(%ebp)
	pushl	$0
	pushl	$HNA_HUNK_PRINT_BLOCKS
	call	C(Zone_HunkPrintTrace)
	addl	$12,%esp
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.p2align 2
.globl C(Z_CheckHeap)
C(Z_CheckHeap):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	C(mainzone),%eax
	leal	ZH_MEMZONE_BLOCKLIST_OFFSET(%eax),%ebx /* sentinel */
	movl	ZH_MEMZONE_BLOCKLIST_NEXT_OFFSET(%eax),%esi
#ifdef PROFILE486
	incl	C(bench486_zone_check_calls)
#endif

.Lzone_check_heap_loop:
	movl	ZH_MEMBLOCK_NEXT_OFFSET(%esi),%edi
	cmpl	%ebx,%edi
	je	.Lzone_check_heap_done
#ifdef PROFILE486
	incl	C(bench486_zone_check_blocks)
#endif
	movl	%esi,%eax
	addl	ZH_MEMBLOCK_SIZE_OFFSET(%esi),%eax
	cmpl	%edi,%eax
	je	.Lzone_check_heap_backlink
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_check_heap_boundary_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
#else
	pushl	$.Lzone_check_heap_boundary_text
	call	C(Sys_Error)
	addl	$4,%esp
#endif

.Lzone_check_heap_backlink:
	cmpl	%esi,ZH_MEMBLOCK_PREV_OFFSET(%edi)
	je	.Lzone_check_heap_free_pair
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_check_heap_backlink_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
#else
	pushl	$.Lzone_check_heap_backlink_text
	call	C(Sys_Error)
	addl	$4,%esp
#endif

.Lzone_check_heap_free_pair:
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%esi)
	jne	.Lzone_check_heap_advance
	cmpl	$0,ZH_MEMBLOCK_TAG_OFFSET(%edi)
	jne	.Lzone_check_heap_advance
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_check_heap_free_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
#else
	pushl	$.Lzone_check_heap_free_text
	call	C(Sys_Error)
	addl	$4,%esp
#endif

.Lzone_check_heap_advance:
	movl	%edi,%esi
	jmp	.Lzone_check_heap_loop

.Lzone_check_heap_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(Hunk_Check)
C(Hunk_Check):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	C(hunk_base),%esi
	movl	C(hunk_low_used),%eax
	leal	(%esi,%eax),%ebx		/* end of low hunk */

.Lzone_hunk_check_loop:
	cmpl	%ebx,%esi
	je	.Lzone_hunk_check_done
	cmpl	$HNA_HUNK_SENTINAL_VALUE,HNA_HUNK_SENTINAL_OFFSET(%esi)
	je	.Lzone_hunk_check_size
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_hunk_check_sentinal_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
#else
	pushl	$.Lzone_hunk_check_sentinal_text
	call	C(Sys_Error)
	addl	$4,%esp
#endif

.Lzone_hunk_check_size:
	movl	HNA_HUNK_SIZE_OFFSET(%esi),%edi
	cmpl	$HNA_HUNK_SIZE,%edi
	jl	.Lzone_hunk_check_bad_size
	movl	%esi,%eax
	subl	C(hunk_base),%eax
	addl	%edi,%eax
	cmpl	C(hunk_size),%eax
	jle	.Lzone_hunk_check_advance

.Lzone_hunk_check_bad_size:
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_hunk_check_size_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
#else
	pushl	$.Lzone_hunk_check_size_text
	call	C(Sys_Error)
	addl	$4,%esp
#endif

.Lzone_hunk_check_advance:
	addl	%edi,%esi
	jmp	.Lzone_hunk_check_loop

.Lzone_hunk_check_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(Cache_UnlinkLRU)
C(Cache_UnlinkLRU):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%esi		/* cache system */
	movl	CTA_CACHE_LRU_NEXT_OFFSET(%esi),%eax
	testl	%eax,%eax
	je	.Lzone_cache_unlink_lru_bad
	movl	CTA_CACHE_LRU_PREV_OFFSET(%esi),%edx
	testl	%edx,%edx
	je	.Lzone_cache_unlink_lru_bad
	movl	%edx,CTA_CACHE_LRU_PREV_OFFSET(%eax)
	movl	%eax,CTA_CACHE_LRU_NEXT_OFFSET(%edx)
	movl	$0,CTA_CACHE_LRU_NEXT_OFFSET(%esi)
	movl	$0,CTA_CACHE_LRU_PREV_OFFSET(%esi)
	jmp	.Lzone_cache_unlink_lru_done

.Lzone_cache_unlink_lru_bad:
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_cache_unlink_lru_error_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
	jmp	.Lzone_cache_unlink_lru_done
#else
	pushl	$.Lzone_cache_unlink_lru_error_text
	call	C(Sys_Error)
	addl	$4,%esp
	/* If a fatal error unexpectedly returns, continue as the C routine does. */
	movl	CTA_CACHE_LRU_NEXT_OFFSET(%esi),%eax
	movl	CTA_CACHE_LRU_PREV_OFFSET(%esi),%edx
	movl	%edx,CTA_CACHE_LRU_PREV_OFFSET(%eax)
	movl	%eax,CTA_CACHE_LRU_NEXT_OFFSET(%edx)
	movl	$0,CTA_CACHE_LRU_NEXT_OFFSET(%esi)
	movl	$0,CTA_CACHE_LRU_PREV_OFFSET(%esi)
#endif

.Lzone_cache_unlink_lru_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	ret

.p2align 2
.globl C(Cache_MakeLRU)
C(Cache_MakeLRU):
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	movl	16(%esp),%esi		/* cache system */
	cmpl	$0,CTA_CACHE_LRU_NEXT_OFFSET(%esi)
	jne	.Lzone_cache_make_lru_bad
	cmpl	$0,CTA_CACHE_LRU_PREV_OFFSET(%esi)
	jne	.Lzone_cache_make_lru_bad
	movl	$C(cache_head),%ebx
	movl	CTA_CACHE_HEAD_LRU_NEXT_OFFSET(%ebx),%eax
	movl	%esi,CTA_CACHE_LRU_PREV_OFFSET(%eax)
	movl	%eax,CTA_CACHE_LRU_NEXT_OFFSET(%esi)
	movl	%ebx,CTA_CACHE_LRU_PREV_OFFSET(%esi)
	movl	%esi,CTA_CACHE_HEAD_LRU_NEXT_OFFSET(%ebx)
	jmp	.Lzone_cache_make_lru_done

.Lzone_cache_make_lru_bad:
#ifdef ASM486_ZONE_HEAP_FIXTURE
	pushl	$.Lzone_cache_make_lru_error_text
	call	C(Bench486ZoneHeapError)
	addl	$4,%esp
#else
	pushl	$.Lzone_cache_make_lru_error_text
	call	C(Sys_Error)
	addl	$4,%esp
	/* Sys_Error is fatal; preserve the C behavior if it unexpectedly returns. */
	movl	$C(cache_head),%ebx
	movl	CTA_CACHE_HEAD_LRU_NEXT_OFFSET(%ebx),%eax
	movl	%esi,CTA_CACHE_LRU_PREV_OFFSET(%eax)
	movl	%eax,CTA_CACHE_LRU_NEXT_OFFSET(%esi)
	movl	%ebx,CTA_CACHE_LRU_PREV_OFFSET(%esi)
	movl	%esi,CTA_CACHE_HEAD_LRU_NEXT_OFFSET(%ebx)
#endif

.Lzone_cache_make_lru_done:
	popl	%edi
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
.Lzone_cache_flush_command:
	.asciz	"flush"
.Lzone_memory_zone_parameter:
	.asciz	"-zone"
.Lzone_memory_missing_size_text:
	.asciz	"Memory_Init: you must specify a size in KB after -zone"
.Lzone_memory_zone_name:
	.asciz	"zone"
.Lzone_check_heap_boundary_text:
	.asciz	"Z_CheckHeap: block size does not touch the next block\n"
.Lzone_check_heap_backlink_text:
	.asciz	"Z_CheckHeap: next block doesn't have proper back link\n"
.Lzone_check_heap_free_text:
	.asciz	"Z_CheckHeap: two consecutive free blocks\n"
.Lzone_hunk_check_sentinal_text:
	.asciz	"Hunk_Check: trahsed sentinal"
.Lzone_hunk_check_size_text:
	.asciz	"Hunk_Check: bad size"
.Lzone_cache_unlink_lru_error_text:
	.asciz	"Cache_UnlinkLRU: NULL link"
.Lzone_cache_make_lru_error_text:
	.asciz	"Cache_MakeLRU: active link"
.Lzone_print_header_format:
	.asciz	"zone size: %i  location: %p\n"
.Lzone_print_block_format:
	.asciz	"block:%p    size:%7i    tag:%3i\n"
.Lzone_print_bad_boundary_text:
	.asciz	"ERROR: block size does not touch the next block\n"
.Lzone_print_bad_backlink_text:
	.asciz	"ERROR: next block doesn't have proper back link\n"
.Lzone_print_adjacent_free_text:
	.asciz	"ERROR: two consecutive free blocks\n"
.Lzone_cache_print_format:
	.asciz	"%8i : %s\n"
.Lzone_cache_report_format:
	.asciz	"%4.1f megabyte data cache\n"
.Lzone_hunk_print_total_format:
	.asciz	"          :%8i total hunk size\n"
.Lzone_hunk_print_separator_text:
	.asciz	"-------------------------\n"
.Lzone_hunk_print_remaining_format:
	.asciz	"          :%8i REMAINING\n"
.Lzone_hunk_print_allocation_format:
	.asciz	"%8p :%8i %8s\n"
.Lzone_hunk_print_group_format:
	.asciz	"          :%8i %8s (TOTAL)\n"
.Lzone_hunk_print_blocks_format:
	.asciz	"%8i total blocks\n"
.Lzone_hunk_print_bad_trace_text:
	.asciz	"Hunk_Print: bad trace event"
#endif /* ASM486_ZONE_HEAP */
