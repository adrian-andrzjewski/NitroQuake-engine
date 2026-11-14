/*
 * Assembly equivalent of src/renderer/r_part.c:R_ParseParticleEffect.
 *
 * Keep message decoding in the original MSG_Read* helpers. In particular,
 * those helpers own msg_readcount/msg_badread behavior for short packets, and
 * MSG_ReadChar returns a sign-extended byte. The only local arithmetic is the
 * exact binary scaling of that signed direction byte by 1/16.
 *
 * 32-bit cdecl, no parameters or return value. EBP is preserved; only caller-
 * saved integer registers are used. Each MSG_ReadCoord x87 return is stored
 * and popped before the next call; direction scaling also leaves x87 empty and
 * does not change the caller's control word.
 */
#include "asm_i386.h"
#include "quakeasm.h"

#if id386 && (defined(ASM486_PARSE_PARTICLE_EFFECT) || defined(BENCH486))

	.arch i486
	.arch .387
	.code32

	.extern C(MSG_ReadCoord)
	.extern C(MSG_ReadChar)
	.extern C(MSG_ReadByte)
	.extern C(R_RunParticleEffect)

	.text
	.p2align 4,,15
	.globl C(R_ParseParticleEffect_asm486)
#ifdef ASM486_PARSE_PARTICLE_EFFECT
	.globl C(R_ParseParticleEffect)
#endif
C(R_ParseParticleEffect_asm486):
#ifdef ASM486_PARSE_PARTICLE_EFFECT
C(R_ParseParticleEffect):
#endif
	/* Locals: org -12..-4, dir -24..-16, msgcount -28, color -32,
	 * signed MSG_ReadChar scratch -36. Keep helper call order identical to C. */
	pushl	%ebp
	movl	%esp,%ebp
	subl	$36,%esp

	call	C(MSG_ReadCoord)
	fstps	-12(%ebp)
	call	C(MSG_ReadCoord)
	fstps	-8(%ebp)
	call	C(MSG_ReadCoord)
	fstps	-4(%ebp)

	call	C(MSG_ReadChar)
	movl	%eax,-36(%ebp)
	fildl	-36(%ebp)
	fmull	.Lr_parseparticleeffect_sixteenth
	fstps	-24(%ebp)
	call	C(MSG_ReadChar)
	movl	%eax,-36(%ebp)
	fildl	-36(%ebp)
	fmull	.Lr_parseparticleeffect_sixteenth
	fstps	-20(%ebp)
	call	C(MSG_ReadChar)
	movl	%eax,-36(%ebp)
	fildl	-36(%ebp)
	fmull	.Lr_parseparticleeffect_sixteenth
	fstps	-16(%ebp)

	call	C(MSG_ReadByte)
	movl	%eax,-28(%ebp)
	call	C(MSG_ReadByte)
	movl	%eax,-32(%ebp)

	/* The original 255 sentinel requests the 1024-particle explosion path. */
	cmpl	$255,-28(%ebp)
	jne	.Lr_parseparticleeffect_count_ready
	movl	$1024,-28(%ebp)
.Lr_parseparticleeffect_count_ready:
	pushl	-28(%ebp)			/* count */
	pushl	-32(%ebp)			/* color */
	leal	-24(%ebp),%eax
	pushl	%eax				/* dir */
	leal	-12(%ebp),%eax
	pushl	%eax				/* org */
	call	C(R_RunParticleEffect)
	addl	$16,%esp

	leave
	ret

	.section .rodata
	.p2align 3
.Lr_parseparticleeffect_sixteenth:
	.double	0.0625

#endif /* id386 && (ASM486_PARSE_PARTICLE_EFFECT || BENCH486) */
