/* Stable scoreboard frag sort from src/client/sbar.c:Sbar_SortFrags. */
#ifdef ASM486_SBAR_FRAGS

.extern _cl
.extern _fragsort
.extern _scoreboardlines

.text
.p2align 2
.globl _Sbar_SortFrags
.globl _Sbar_SortFrags_asm486
_Sbar_SortFrags:
_Sbar_SortFrags_asm486:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi

	movl	$0,_scoreboardlines
	movl	_cl+SBAR_CL_MAXCLIENTS_OFFSET,%ecx
	testl	%ecx,%ecx
	jle	.Lsbar_sort_done
	movl	_cl+SBAR_CL_SCORES_OFFSET,%esi
	xorl	%ebx,%ebx		/* i */

/* Collect non-empty player slots in the same order as C. */
.Lsbar_sort_collect:
	cmpl	%ecx,%ebx
	jge	.Lsbar_sort_collected
	movl	%ebx,%eax
	imull	$SBAR_SCOREBOARD_SIZE,%eax
	cmpb	$0,SBAR_SCOREBOARD_NAME_OFFSET(%esi,%eax)
	je	.Lsbar_sort_collect_next
	movl	_scoreboardlines,%edx
	movl	%ebx,_fragsort(,%edx,4)
	incl	_scoreboardlines
.Lsbar_sort_collect_next:
	incl	%ebx
	jmp	.Lsbar_sort_collect

/* Match the C shrinking pass bound, preserving the order of ties. */
.Lsbar_sort_collected:
	movl	_scoreboardlines,%edi
	cmpl	$1,%edi
	jle	.Lsbar_sort_done
	xorl	%ebx,%ebx		/* i */
.Lsbar_sort_outer:
	cmpl	%edi,%ebx
	jge	.Lsbar_sort_done
	xorl	%ecx,%ecx		/* j */
.Lsbar_sort_inner:
	movl	%edi,%edx
	decl	%edx
	subl	%ebx,%edx
	cmpl	%edx,%ecx
	jge	.Lsbar_sort_outer_next

	movl	_fragsort(,%ecx,4),%eax
	imull	$SBAR_SCOREBOARD_SIZE,%eax,%eax
	movl	SBAR_SCOREBOARD_FRAGS_OFFSET(%esi,%eax),%edx
	movl	_fragsort+4(,%ecx,4),%eax
	imull	$SBAR_SCOREBOARD_SIZE,%eax,%eax
	cmpl	SBAR_SCOREBOARD_FRAGS_OFFSET(%esi,%eax),%edx
	jge	.Lsbar_sort_inner_next

	movl	_fragsort(,%ecx,4),%eax
	movl	_fragsort+4(,%ecx,4),%edx
	movl	%edx,_fragsort(,%ecx,4)
	movl	%eax,_fragsort+4(,%ecx,4)
.Lsbar_sort_inner_next:
	incl	%ecx
	jmp	.Lsbar_sort_inner

.Lsbar_sort_outer_next:
	incl	%ebx
	jmp	.Lsbar_sort_outer

.Lsbar_sort_done:
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

#endif /* ASM486_SBAR_FRAGS */
