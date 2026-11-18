/* Cold model-cache miss dispatcher used by the alias rendering path. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
.equ MOD_NEEDLOAD_OFFSET, 64
.equ MOD_TYPE_OFFSET, 68
.equ MOD_NUMFRAMES_OFFSET, 72
.equ MOD_CACHE_OFFSET, 388
.equ MOD_TYPE_BRUSH, 0
.equ MOD_TYPE_SPRITE, 1
.equ MOD_TYPE_ALIAS, 2
.equ MOD_NEEDLOAD_PRESENT, 0
.equ MOD_IDPOLYHEADER, 0x4f504449
.equ MOD_IDSPRITEHEADER, 0x50534449
.equ MOD_STACK_BUFFER_SIZE, 1024
.equ MOD_STACK_BUFFER_OFFSET, 1036

.extern _loadmodel
.extern _loadname
.extern MODEL_LOAD_CACHE_CHECK
.extern MODEL_LOAD_STACK_FILE
.extern MODEL_LOAD_FILE_BASE
.extern MODEL_LOAD_ALIAS
.extern MODEL_LOAD_SPRITE
.extern MODEL_LOAD_BRUSH
.extern MODEL_LOAD_ERROR
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
.extern _Mod_LoadModelTrace_asm486
#endif

.section .rodata
.p2align 2
.LModLoadNotFound:
	.asciz "Mod_NumForName: %s not found"
.text
.p2align 3
.globl _Mod_LoadModel
.globl _Mod_LoadModel_asm486
_Mod_LoadModel:
_Mod_LoadModel_asm486:
	pushl	%ebp
	movl	%esp,%ebp
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	subl	$MOD_STACK_BUFFER_SIZE,%esp
	movl	8(%ebp),%ebx
	movl	12(%ebp),%esi

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	movl	MOD_NEEDLOAD_OFFSET(%ebx),%eax
	movl	MOD_TYPE_OFFSET(%ebx),%edx
	pushl	$0
	pushl	%edx
	pushl	%eax
	pushl	$39
	call	_Mod_LoadModelTrace_asm486
	addl	$16,%esp
#endif

	cmpl	$MOD_TYPE_ALIAS,MOD_TYPE_OFFSET(%ebx)
	jne	.LModLoadNonAlias
	leal	MOD_CACHE_OFFSET(%ebx),%eax
	pushl	%eax
	call	MODEL_LOAD_CACHE_CHECK
	addl	$4,%esp
	testl	%eax,%eax
	je	.LModLoadFile
	movl	$MOD_NEEDLOAD_PRESENT,MOD_NEEDLOAD_OFFSET(%ebx)
	movl	%ebx,%eax
	jmp	.LModLoadReturn

.LModLoadNonAlias:
	cmpl	$MOD_NEEDLOAD_PRESENT,MOD_NEEDLOAD_OFFSET(%ebx)
	jne	.LModLoadFile
	movl	%ebx,%eax
	jmp	.LModLoadReturn

.LModLoadFile:
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	movl	MOD_NEEDLOAD_OFFSET(%ebx),%eax
	movl	MOD_TYPE_OFFSET(%ebx),%edx
	pushl	$0
	pushl	%edx
	pushl	%eax
	pushl	$40
	call	_Mod_LoadModelTrace_asm486
	addl	$16,%esp
#endif
	leal	-MOD_STACK_BUFFER_OFFSET(%ebp),%eax
	pushl	$MOD_STACK_BUFFER_SIZE
	pushl	%eax
	pushl	%ebx
	call	MODEL_LOAD_STACK_FILE
	addl	$12,%esp
	movl	%eax,%edi

#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	xorl	%eax,%eax
	testl	%edi,%edi
	setne	%al
	movl	MOD_TYPE_OFFSET(%ebx),%edx
	pushl	$0
	pushl	%edx
	pushl	%eax
	pushl	$41
	call	_Mod_LoadModelTrace_asm486
	addl	$16,%esp
#endif

	testl	%edi,%edi
	jne	.LModLoadHaveFile
	testl	%esi,%esi
	je	.LModLoadMissing
	pushl	%ebx
	pushl	$.LModLoadNotFound
	call	MODEL_LOAD_ERROR
	addl	$8,%esp
.LModLoadMissing:
	xorl	%eax,%eax
	jmp	.LModLoadReturn

.LModLoadHaveFile:
	pushl	$_loadname
	pushl	%ebx
	call	MODEL_LOAD_FILE_BASE
	addl	$8,%esp
	movl	%ebx,_loadmodel
	movl	$MOD_NEEDLOAD_PRESENT,MOD_NEEDLOAD_OFFSET(%ebx)
	movl	(%edi),%eax
	cmpl	$MOD_IDPOLYHEADER,%eax
	je	.LModLoadAlias
	cmpl	$MOD_IDSPRITEHEADER,%eax
	je	.LModLoadSprite

.LModLoadBrush:
	pushl	%edi
	pushl	%ebx
	call	MODEL_LOAD_BRUSH
	addl	$8,%esp
	jmp	.LModLoadComplete

.LModLoadSprite:
	pushl	%edi
	pushl	%ebx
	call	MODEL_LOAD_SPRITE
	addl	$8,%esp
	jmp	.LModLoadComplete

.LModLoadAlias:
	pushl	%edi
	pushl	%ebx
	call	MODEL_LOAD_ALIAS
	addl	$8,%esp

.LModLoadComplete:
#if defined(BENCH486) && defined(ASM486_SCREEN_CENTER_STRING)
	movl	MOD_TYPE_OFFSET(%ebx),%eax
	movl	MOD_NUMFRAMES_OFFSET(%ebx),%edx
	pushl	$0
	pushl	%edx
	pushl	%eax
	pushl	$60
	call	_Mod_LoadModelTrace_asm486
	addl	$16,%esp
#endif
	movl	%ebx,%eax
.LModLoadReturn:
	leal	-12(%ebp),%esp
	popl	%edi
	popl	%esi
	popl	%ebx
	leave
	ret
