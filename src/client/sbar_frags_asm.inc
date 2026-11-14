/* Status-bar top frag strip from src/client/sbar.c:Sbar_DrawFrags. */
#ifdef ASM486_SBAR_FRAGS

#if defined(BENCH486) && defined(ASM486_SBAR_FRAGS_FIXTURE)
#define SBAR_FRAGS_FILL _Bench486SbarFragsFill
#define SBAR_FRAGS_CHARACTER _Bench486SbarFragsCharacter
#else
#define SBAR_FRAGS_FILL _Draw_Fill
#define SBAR_FRAGS_CHARACTER _Sbar_DrawCharacter
#endif

.extern _cl
.extern _vid
.extern _fragsort
.extern _scoreboardlines
.extern _Sbar_SortFrags_asm486
.extern _sprintf
.extern SBAR_FRAGS_FILL
.extern SBAR_FRAGS_CHARACTER

.text
.p2align 2
.globl _Sbar_DrawFrags
.globl _Sbar_DrawFrags_asm486
_Sbar_DrawFrags:
_Sbar_DrawFrags_asm486:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	/* 76 bytes keeps the outgoing cdecl call area 16-byte aligned. */
	subl	$76,%esp

	call	_Sbar_SortFrags_asm486
	movl	_scoreboardlines,%eax
	cmpl	$SBAR_FRAGS_MAX_DISPLAY,%eax
	jle	.Lsbar_frags_limit_ready
	movl	$SBAR_FRAGS_MAX_DISPLAY,%eax
.Lsbar_frags_limit_ready:
	movl	%eax,-24(%ebp)		/* l */
	movl	$0,-16(%ebp)		/* i */
	movl	$23,-36(%ebp)		/* x */

	cmpl	$SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	je	.Lsbar_frags_deathmatch
	movl	_vid+SBAR_VID_WIDTH_OFFSET,%eax
	subl	$320,%eax
	/* vid.width is unsigned in the DOS C ABI, so C uses a logical shift. */
	shrl	$1,%eax
	movl	%eax,-44(%ebp)		/* xofs */
	jmp	.Lsbar_frags_y
.Lsbar_frags_deathmatch:
	movl	$0,-44(%ebp)
.Lsbar_frags_y:
	movl	_vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl	$47,%eax
	movl	%eax,-40(%ebp)		/* y */

.Lsbar_frags_loop:
	movl	-16(%ebp),%eax
	cmpl	-24(%ebp),%eax
	jge	.Lsbar_frags_done
	movl	_fragsort(,%eax,4),%ebx
	movl	%ebx,-20(%ebp)		/* k */
	movl	_cl+SBAR_CL_SCORES_OFFSET,%esi
	imull	$SBAR_SCOREBOARD_SIZE,%ebx,%eax
	addl	%eax,%esi
	cmpb	$0,SBAR_SCOREBOARD_NAME_OFFSET(%esi)
	je	.Lsbar_frags_next

	/* Sbar_ColorForMap returns its input plus eight on both branches. */
	movl	SBAR_SCOREBOARD_COLORS_OFFSET(%esi),%eax
	movl	%eax,%ecx
	andl	$0xf0,%eax
	addl	$8,%eax
	movl	%eax,-28(%ebp)		/* top */
	andl	$15,%ecx
	shll	$4,%ecx
	addl	$8,%ecx
	movl	%ecx,-32(%ebp)		/* bottom */

	/* Draw_Fill(xofs + x*8 + 10, y, 28, 4, top). */
	subl	$32,%esp
	movl	-36(%ebp),%eax
	shll	$3,%eax
	addl	-44(%ebp),%eax
	addl	$10,%eax
	movl	%eax,0(%esp)
	movl	-40(%ebp),%eax
	movl	%eax,4(%esp)
	movl	$28,8(%esp)
	movl	$4,12(%esp)
	movl	-28(%ebp),%eax
	movl	%eax,16(%esp)
	call	SBAR_FRAGS_FILL
	addl	$32,%esp

	/* Draw_Fill(xofs + x*8 + 10, y + 4, 28, 3, bottom). */
	subl	$32,%esp
	movl	-36(%ebp),%eax
	shll	$3,%eax
	addl	-44(%ebp),%eax
	addl	$10,%eax
	movl	%eax,0(%esp)
	movl	-40(%ebp),%eax
	addl	$4,%eax
	movl	%eax,4(%esp)
	movl	$28,8(%esp)
	movl	$3,12(%esp)
	movl	-32(%ebp),%eax
	movl	%eax,16(%esp)
	call	SBAR_FRAGS_FILL
	addl	$32,%esp

	/* sprintf(num, "%3i", frags), preserving the original three glyphs. */
	subl	$16,%esp
	leal	-68(%ebp),%eax
	movl	%eax,0(%esp)
	leal	.Lsbar_frags_format,%eax
	movl	%eax,4(%esp)
	movl	SBAR_SCOREBOARD_FRAGS_OFFSET(%esi),%eax
	movl	%eax,8(%esp)
	call	_sprintf
	addl	$16,%esp

	/* Three right-aligned frag glyphs. */
	subl	$16,%esp
	movl	-36(%ebp),%eax
	addl	$1,%eax
	shll	$3,%eax
	movl	%eax,0(%esp)
	movl	$-24,4(%esp)
	movzbl	-68(%ebp),%eax
	movl	%eax,8(%esp)
	call	SBAR_FRAGS_CHARACTER
	addl	$16,%esp

	subl	$16,%esp
	movl	-36(%ebp),%eax
	addl	$2,%eax
	shll	$3,%eax
	movl	%eax,0(%esp)
	movl	$-24,4(%esp)
	movzbl	-67(%ebp),%eax
	movl	%eax,8(%esp)
	call	SBAR_FRAGS_CHARACTER
	addl	$16,%esp

	subl	$16,%esp
	movl	-36(%ebp),%eax
	addl	$3,%eax
	shll	$3,%eax
	movl	%eax,0(%esp)
	movl	$-24,4(%esp)
	movzbl	-66(%ebp),%eax
	movl	%eax,8(%esp)
	call	SBAR_FRAGS_CHARACTER
	addl	$16,%esp

	/* Mark the local player's frag cell with the two bracket glyphs. */
	movl	_cl+SBAR_CL_VIEWENTITY_OFFSET,%eax
	decl	%eax
	cmpl	-20(%ebp),%eax
	jne	.Lsbar_frags_next
	subl	$16,%esp
	movl	-36(%ebp),%eax
	shll	$3,%eax
	addl	$2,%eax
	movl	%eax,0(%esp)
	movl	$-24,4(%esp)
	movl	$16,8(%esp)
	call	SBAR_FRAGS_CHARACTER
	addl	$16,%esp

	subl	$16,%esp
	movl	-36(%ebp),%eax
	addl	$4,%eax
	shll	$3,%eax
	subl	$4,%eax
	movl	%eax,0(%esp)
	movl	$-24,4(%esp)
	movl	$17,8(%esp)
	call	SBAR_FRAGS_CHARACTER
	addl	$16,%esp

.Lsbar_frags_next:
	addl	$4,-36(%ebp)
	incl	-16(%ebp)
	jmp	.Lsbar_frags_loop

.Lsbar_frags_done:
	addl	$76,%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret

.section .rodata
.p2align 2
.Lsbar_frags_format:
	.asciz	"%3i"
.text

#undef SBAR_FRAGS_FILL
#undef SBAR_FRAGS_CHARACTER
#endif /* ASM486_SBAR_FRAGS */
