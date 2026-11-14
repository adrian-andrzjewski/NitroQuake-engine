/* i486 translation of the recursive area-link entity clipper. */
#include "collision/asm_cliplinks.h"

	.text
	.extern C(sv)
	.extern C(Sys_Error)
	.extern C(SV_ClipMoveToEntity)
	.globl C(SV_ClipToLinks)
C(SV_ClipToLinks):
	#if defined(BENCH486) && defined(ASM486_CLIP_TO_LINKS)
	incl C(bench486_cliptolinks_asm_calls)
	#endif
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$96,%esp
	movl	8(%ebp),%eax
	movl	12(%ebp),%ebx		/* moveclip_t */
.Lacl_cliplinks_node_entry:
	movl	%eax,-16(%ebp)		/* current area node */
	movl	%ebx,-20(%ebp)
	fnstcw	-90(%ebp)		/* C float-to-int flags conversion truncates */

	movl	ACL_NODE_SOLID_NEXT(%eax),%esi
.Lacl_cliplinks_entity:
	movl	-16(%ebp),%eax
	leal	ACL_NODE_SOLID_EDICTS(%eax),%edx
	cmpl	%edx,%esi
	je	.Lacl_cliplinks_recurse
	movl	ACL_LINK_NEXT(%esi),%eax
	movl	%eax,-28(%ebp)		/* save next before any call */
	leal	-ACL_EDICT_AREA(%esi),%edi
	movl	%edi,-32(%ebp)		/* touch edict */

	flds	ACL_EDICT_SOLID(%edi)
	fcomps	.Lacl_cliplinks_zero
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_not_solid_not
	je	.Lacl_cliplinks_next

.Lacl_cliplinks_not_solid_not:
	movl	ACL_MOVECLIP_PASSEDICT(%ebx),%eax
	testl	%eax,%eax
	jz	.Lacl_cliplinks_not_passed
	cmpl	%eax,%edi
	je	.Lacl_cliplinks_next
.Lacl_cliplinks_not_passed:

	flds	ACL_EDICT_SOLID(%edi)
	fcomps	.Lacl_cliplinks_one
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_not_trigger
	jne	.Lacl_cliplinks_not_trigger
	pushl	$.Lacl_cliplinks_trigger_text
	call	C(Sys_Error)
	addl	$4,%esp
.Lacl_cliplinks_not_trigger:

	cmpl	$1,ACL_MOVECLIP_TYPE(%ebx)
	jne	.Lacl_cliplinks_test_bounds
	flds	ACL_EDICT_SOLID(%edi)
	fcomps	.Lacl_cliplinks_four
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_nomonsters_not_bsp
	je	.Lacl_cliplinks_test_bounds
.Lacl_cliplinks_nomonsters_not_bsp:
	jmp	.Lacl_cliplinks_next

.Lacl_cliplinks_test_bounds:
	flds	ACL_MOVECLIP_BOXMINS+0(%ebx)
	fcomps	ACL_EDICT_ABSMAX+0(%edi)
	fnstsw	%ax
	sahf
	ja	.Lacl_cliplinks_next
	flds	ACL_MOVECLIP_BOXMINS+4(%ebx)
	fcomps	ACL_EDICT_ABSMAX+4(%edi)
	fnstsw	%ax
	sahf
	ja	.Lacl_cliplinks_next
	flds	ACL_MOVECLIP_BOXMINS+8(%ebx)
	fcomps	ACL_EDICT_ABSMAX+8(%edi)
	fnstsw	%ax
	sahf
	ja	.Lacl_cliplinks_next
	flds	ACL_MOVECLIP_BOXMAXS+0(%ebx)
	fcomps	ACL_EDICT_ABSMIN+0(%edi)
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_next
	jb	.Lacl_cliplinks_next
	flds	ACL_MOVECLIP_BOXMAXS+4(%ebx)
	fcomps	ACL_EDICT_ABSMIN+4(%edi)
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_next
	jb	.Lacl_cliplinks_next
	flds	ACL_MOVECLIP_BOXMAXS+8(%ebx)
	fcomps	ACL_EDICT_ABSMIN+8(%edi)
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_next
	jb	.Lacl_cliplinks_next

	movl	ACL_MOVECLIP_PASSEDICT(%ebx),%eax
	testl	%eax,%eax
	jz	.Lacl_cliplinks_test_allsolid
	flds	ACL_EDICT_SIZE+0(%eax)
	fcomps	.Lacl_cliplinks_zero
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_passed_size_nonzero
	je	.Lacl_cliplinks_test_allsolid
.Lacl_cliplinks_passed_size_nonzero:
	flds	ACL_EDICT_SIZE+0(%edi)
	fcomps	.Lacl_cliplinks_zero
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_touch_size_nonzero
	je	.Lacl_cliplinks_next
.Lacl_cliplinks_touch_size_nonzero:

.Lacl_cliplinks_test_allsolid:
	cmpl	$0,ACL_MOVECLIP_TRACE+0(%ebx)
	jne	.Lacl_cliplinks_return
	movl	ACL_MOVECLIP_PASSEDICT(%ebx),%eax
	testl	%eax,%eax
	jz	.Lacl_cliplinks_do_clip
	movl	C(sv)+ACL_SERVER_EDICTS,%edx
	movl	ACL_EDICT_OWNER(%edi),%ecx
	addl	%edx,%ecx
	cmpl	%eax,%ecx
	je	.Lacl_cliplinks_next
	movl	ACL_EDICT_OWNER(%eax),%ecx
	addl	%edx,%ecx
	cmpl	%edi,%ecx
	je	.Lacl_cliplinks_next

.Lacl_cliplinks_do_clip:
	movw	-90(%ebp),%ax
	andw	$0xf3ff,%ax
	orw	$0x0c00,%ax		/* round toward zero for (int)flags */
	movw	%ax,-92(%ebp)
	fldcw	-92(%ebp)
	flds	ACL_EDICT_FLAGS(%edi)
	fistpl	-96(%ebp)
	fldcw	-90(%ebp)
	testl	$32,-96(%ebp)
	jz	.Lacl_cliplinks_clip_regular

	movl	ACL_MOVECLIP_END(%ebx),%eax
	pushl	%eax
	leal	ACL_MOVECLIP_MAXS2(%ebx),%eax
	pushl	%eax
	leal	ACL_MOVECLIP_MINS2(%ebx),%eax
	pushl	%eax
	movl	ACL_MOVECLIP_START(%ebx),%eax
	pushl	%eax
	pushl	%edi
	leal	-84(%ebp),%eax
	pushl	%eax
	call	C(SV_ClipMoveToEntity)
	addl	$20,%esp		/* the struct-return callee pops its hidden pointer */
	jmp	.Lacl_cliplinks_compare_trace

.Lacl_cliplinks_clip_regular:
	movl	ACL_MOVECLIP_END(%ebx),%eax
	pushl	%eax
	movl	ACL_MOVECLIP_MAXS(%ebx),%eax
	pushl	%eax
	movl	ACL_MOVECLIP_MINS(%ebx),%eax
	pushl	%eax
	movl	ACL_MOVECLIP_START(%ebx),%eax
	pushl	%eax
	pushl	%edi
	leal	-84(%ebp),%eax
	pushl	%eax
	call	C(SV_ClipMoveToEntity)
	addl	$20,%esp		/* the struct-return callee pops its hidden pointer */

.Lacl_cliplinks_compare_trace:
	movl	-84(%ebp),%eax
	testl	%eax,%eax
	jnz	.Lacl_cliplinks_better_trace
	movl	-80(%ebp),%eax
	testl	%eax,%eax
	jnz	.Lacl_cliplinks_better_trace
	flds	-68(%ebp)
	fcomps	ACL_MOVECLIP_TRACE+16(%ebx)
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_not_better
	jb	.Lacl_cliplinks_better_trace
	jmp	.Lacl_cliplinks_not_better

.Lacl_cliplinks_better_trace:
	movl	-32(%ebp),%eax
	movl	%eax,-36(%ebp)		/* trace.ent = touch */
	movl	ACL_MOVECLIP_TRACE+4(%ebx),%eax
	testl	%eax,%eax
	jz	.Lacl_cliplinks_copy_trace
	pushl	%esi
	pushl	%edi
	leal	-84(%ebp),%esi
	leal	ACL_MOVECLIP_TRACE(%ebx),%edi
	movl	$13,%ecx
	rep
	movsl
	popl	%edi
	popl	%esi
	movl	$1,ACL_MOVECLIP_TRACE+4(%ebx)
	jmp	.Lacl_cliplinks_next

.Lacl_cliplinks_copy_trace:
	pushl	%esi
	pushl	%edi
	leal	-84(%ebp),%esi
	leal	ACL_MOVECLIP_TRACE(%ebx),%edi
	movl	$13,%ecx
	rep
	movsl
	popl	%edi
	popl	%esi
	jmp	.Lacl_cliplinks_next

.Lacl_cliplinks_not_better:
	cmpl	$0,-80(%ebp)
	je	.Lacl_cliplinks_next
	movl	$1,ACL_MOVECLIP_TRACE+4(%ebx)

.Lacl_cliplinks_next:
	movl	-28(%ebp),%esi
	jmp	.Lacl_cliplinks_entity

.Lacl_cliplinks_recurse:
	movl	-16(%ebp),%eax
	cmpl	$-1,ACL_NODE_AXIS(%eax)
	je	.Lacl_cliplinks_return
	movl	ACL_NODE_AXIS(%eax),%ecx
	leal	ACL_MOVECLIP_BOXMAXS(%ebx),%edx
	flds	(%edx,%ecx,4)
	fcomps	ACL_NODE_DIST(%eax)
	fnstsw	%ax
	sahf
	ja	.Lacl_cliplinks_child0
	jmp	.Lacl_cliplinks_test_child1

.Lacl_cliplinks_child0:
	movl	-16(%ebp),%eax
	movl	ACL_NODE_CHILDREN+0(%eax),%eax
	pushl	%ebx
	pushl	%eax
	call	C(SV_ClipToLinks)
	addl	$8,%esp

.Lacl_cliplinks_test_child1:
	movl	-16(%ebp),%eax
	movl	ACL_NODE_AXIS(%eax),%ecx
	leal	ACL_MOVECLIP_BOXMINS(%ebx),%edx
	flds	(%edx,%ecx,4)
	fcomps	ACL_NODE_DIST(%eax)
	fnstsw	%ax
	sahf
	jp	.Lacl_cliplinks_return
	jb	.Lacl_cliplinks_child1
	jmp	.Lacl_cliplinks_return

.Lacl_cliplinks_child1:
	movl	-16(%ebp),%eax
	movl	ACL_NODE_CHILDREN+4(%eax),%eax
	/* The final child has no continuation: reuse this invocation frame. */
	#if defined(BENCH486) && defined(ASM486_CLIP_TO_LINKS)
	incl C(bench486_cliptolinks_asm_calls)
	#endif
	jmp	.Lacl_cliplinks_node_entry

.Lacl_cliplinks_return:
	addl	$96,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

	.section .rodata
.Lacl_cliplinks_zero:
	.long 0
.Lacl_cliplinks_one:
	.long 0x3f800000
.Lacl_cliplinks_four:
	.long 0x40800000
.Lacl_cliplinks_trigger_text:
	.asciz "Trigger in clipping list"
	.text
