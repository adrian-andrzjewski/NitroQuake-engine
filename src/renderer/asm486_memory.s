/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
// asm486_memory.s
// i486 implementations of the engine memory primitives.

#include "asm_i386.h"
#include "renderer/d_ifacea.h"
#include "renderer/asm_draw.h"

	.text
	.p2align 4,,15

// void Q_memset_asm486(void *dest, int fill, int count)
C(Q_memset_asm486):
	.globl C(Q_memset_asm486)
	pushl	%edi
	movl	8(%esp),%edi		// dest
	movl	12(%esp),%eax		// fill
	movl	16(%esp),%ecx		// count
	testl	%ecx,%ecx
	jle	.Lmemset_done

	andl	$0xff,%eax

// Align the destination with byte stores.  The remaining count is kept in
// ECX until the dword count and tail count are split below.
.Lmemset_align:
	testl	$3,%edi
	jz	.Lmemset_aligned
	movb	%al,(%edi)
	incl	%edi
	decl	%ecx
	jnz	.Lmemset_align
	jmp	.Lmemset_done

.Lmemset_aligned:
// Expand the byte into a repeated dword pattern without newer instructions.
	movl	%eax,%edx
	shll	$8,%edx
	orl	%edx,%eax
	movl	%eax,%edx
	shll	$16,%edx
	orl	%edx,%eax

	movl	%ecx,%edx			// preserve the byte tail count
	shrl	$2,%ecx
	jz	.Lmemset_tail
	cld
	rep
	stosl

.Lmemset_tail:
	andl	$3,%edx
	jz	.Lmemset_done
	movl	%edx,%ecx
	cld
	rep
	stosb

.Lmemset_done:
	popl	%edi
	ret

	.p2align 4,,15

// void Q_memcpy_asm486(void *dest, void *src, int count)
// Matches the existing Q_memcpy contract: forward copy, no overlap handling.
C(Q_memcpy_asm486):
	.globl C(Q_memcpy_asm486)
	pushl	%edi
	pushl	%esi
	movl	12(%esp),%edi		// dest
	movl	16(%esp),%esi		// src
	movl	20(%esp),%ecx		// count
	testl	%ecx,%ecx
	jle	.Lmemcpy_done

// A dword loop is safe only when both pointers have the same alignment.
	movl	%edi,%eax
xorl	%esi,%eax
	testl	$3,%eax
jnz	.Lmemcpy_bytes

.Lmemcpy_align:
	testl	$3,%edi
	jz	.Lmemcpy_aligned
	movb	(%esi),%al
	movb	%al,(%edi)
	incl	%esi
	incl	%edi
	decl	%ecx
	jnz	.Lmemcpy_align
	jmp	.Lmemcpy_done

.Lmemcpy_aligned:
	movl	%ecx,%edx			// preserve the byte tail count
	shrl	$2,%ecx
	jz	.Lmemcpy_tail
	cld
	rep
	movsl

.Lmemcpy_tail:
	andl	$3,%edx
	jz	.Lmemcpy_done
	movl	%edx,%ecx
	cld
	rep
	movsb
	jmp	.Lmemcpy_done

.Lmemcpy_bytes:
	cld
	rep
	movsb

.Lmemcpy_done:
	popl	%esi
	popl	%edi
	ret

	.p2align 4,,15

