#include "asm_sbar.h"

#ifdef ASM486_SBAR_PRIMITIVES

.text
.p2align 2

/* Sbar_itoa: format a signed 32-bit value with reciprocal-multiply division.
   The 0xcccccccd high product computes unsigned n / 10 on 386 and later. */
.globl _Sbar_itoa
_Sbar_itoa:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	leal 11(%esi),%edi
	movb $0,(%edi)
	testl %ebx,%ebx
	jns .Lsbar_itoa_digits
	negl %ebx

.Lsbar_itoa_digits:
	movl %ebx,%eax
	movl $0xcccccccd,%ecx
	mull %ecx
	shrl $3,%edx
	leal (%edx,%edx,4),%ecx
	addl %ecx,%ecx
	subl %ecx,%ebx
	leal -1(%edi),%edi
	addb $'0',%bl
	movb %bl,(%edi)
	movl %edx,%ebx
	testl %ebx,%ebx
	jnz .Lsbar_itoa_digits

	movl 8(%ebp),%eax
	testl %eax,%eax
	jns .Lsbar_itoa_copy
	leal -1(%edi),%edi
	movb $'-',(%edi)

.Lsbar_itoa_copy:
	leal 11(%esi),%eax
	subl %edi,%eax
	movl %eax,%ebx
	movl %edi,%esi
	movl 12(%ebp),%edi
	movl %ebx,%ecx
	cld
	rep movsb
	movb $0,(%edi)
	movl %ebx,%eax

	popl %edi
	popl %esi
	popl %ebx
	leave
	ret

/* Sbar_DrawPic: translate logical HUD coordinates, then tail-call Draw_Pic. */
.globl _Sbar_DrawPic
_Sbar_DrawPic:
	movl 4(%esp),%edx
	movl _vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl $SBAR_HEIGHT,%eax
	addl 8(%esp),%eax
	cmpl $SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	je .Lsbar_pic_positioned
	movl _vid+SBAR_VID_WIDTH_OFFSET,%ecx
	subl $320,%ecx
	shrl $1,%ecx
	addl %ecx,%edx
.Lsbar_pic_positioned:
#ifdef BENCH486
	cmpl $0,_bench486_sbar_capture_active
	jne .Lsbar_pic_capture
#endif
	movl %edx,4(%esp)
	movl %eax,8(%esp)
	jmp _Draw_Pic
#ifdef BENCH486
.Lsbar_pic_capture:
	movl 12(%esp),%ecx
	pushl %ecx
	pushl %eax
	pushl %edx
	pushl $SBAR_CAPTURE_PIC
	call _Bench486SbarCapture
	addl $16,%esp
	ret
#endif

/* Sbar_DrawTransPic: same origin transform for masked status-bar art. */
.globl _Sbar_DrawTransPic
_Sbar_DrawTransPic:
	movl 4(%esp),%edx
	movl _vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl $SBAR_HEIGHT,%eax
	addl 8(%esp),%eax
	cmpl $SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	je .Lsbar_transpic_positioned
	movl _vid+SBAR_VID_WIDTH_OFFSET,%ecx
	subl $320,%ecx
	shrl $1,%ecx
	addl %ecx,%edx
.Lsbar_transpic_positioned:
#ifdef BENCH486
	cmpl $0,_bench486_sbar_capture_active
	jne .Lsbar_transpic_capture
#endif
	movl %edx,4(%esp)
	movl %eax,8(%esp)
	jmp _Draw_TransPic
#ifdef BENCH486
.Lsbar_transpic_capture:
	movl 12(%esp),%ecx
	pushl %ecx
	pushl %eax
	pushl %edx
	pushl $SBAR_CAPTURE_TRANSPIC
	call _Bench486SbarCapture
	addl $16,%esp
	ret
#endif

/* Sbar_DrawCharacter adds the four-pixel glyph inset before centering. */
.globl _Sbar_DrawCharacter
_Sbar_DrawCharacter:
	movl 4(%esp),%edx
	addl $4,%edx
	movl _vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl $SBAR_HEIGHT,%eax
	addl 8(%esp),%eax
	cmpl $SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	je .Lsbar_character_positioned
	movl _vid+SBAR_VID_WIDTH_OFFSET,%ecx
	subl $320,%ecx
	shrl $1,%ecx
	addl %ecx,%edx
.Lsbar_character_positioned:
#ifdef BENCH486
	cmpl $0,_bench486_sbar_capture_active
	jne .Lsbar_character_capture
#endif
	movl %edx,4(%esp)
	movl %eax,8(%esp)
	jmp _Draw_Character
#ifdef BENCH486
.Lsbar_character_capture:
	movl 12(%esp),%ecx
	pushl %ecx
	pushl %eax
	pushl %edx
	pushl $SBAR_CAPTURE_CHARACTER
	call _Bench486SbarCapture
	addl $16,%esp
	ret
#endif

/* Sbar_DrawString only changes the HUD origin; Draw_String owns glyph walking. */
.globl _Sbar_DrawString
_Sbar_DrawString:
	movl 4(%esp),%edx
	movl _vid+SBAR_VID_HEIGHT_OFFSET,%eax
	subl $SBAR_HEIGHT,%eax
	addl 8(%esp),%eax
	cmpl $SBAR_GAME_DEATHMATCH,_cl+SBAR_CL_GAMETYPE_OFFSET
	je .Lsbar_string_positioned
	movl _vid+SBAR_VID_WIDTH_OFFSET,%ecx
	subl $320,%ecx
	shrl $1,%ecx
	addl %ecx,%edx
.Lsbar_string_positioned:
#ifdef BENCH486
	cmpl $0,_bench486_sbar_capture_active
	jne .Lsbar_string_capture
#endif
	movl %edx,4(%esp)
	movl %eax,8(%esp)
	jmp _Draw_String
#ifdef BENCH486
.Lsbar_string_capture:
	movl 12(%esp),%ecx
	pushl %ecx
	pushl %eax
	pushl %edx
	pushl $SBAR_CAPTURE_STRING
	call _Bench486SbarCapture
	addl $16,%esp
	ret
#endif

/* Sbar_DrawNum: truncate or left-pad the decimal text and select digit art. */
.globl _Sbar_DrawNum
_Sbar_DrawNum:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi
	subl $12,%esp
	leal -24(%ebp),%eax
	pushl %eax
	pushl 16(%ebp)
	call _Sbar_itoa
	addl $8,%esp
	movl %eax,%esi
	leal -24(%ebp),%edi
	movl 8(%ebp),%ebx
	movl 20(%ebp),%ecx
	cmpl %ecx,%esi
	jle .Lsbar_drawnum_padding
	subl %ecx,%esi
	addl %esi,%edi
	movl %ecx,%esi
.Lsbar_drawnum_padding:
	movl 20(%ebp),%ecx
	cmpl %ecx,%esi
	jge .Lsbar_drawnum_loop
	subl %esi,%ecx
	imull $24,%ecx,%ecx
	addl %ecx,%ebx
	jmp .Lsbar_drawnum_loop

.Lsbar_drawnum_loop:
	movzbl (%edi),%eax
	testl %eax,%eax
	jz .Lsbar_drawnum_done
	cmpl $'-',%eax
	je .Lsbar_drawnum_minus
	subl $'0',%eax
	jmp .Lsbar_drawnum_frame
.Lsbar_drawnum_minus:
	movl $10,%eax
.Lsbar_drawnum_frame:
	movl 24(%ebp),%ecx
	imull $SBAR_NUM_COLOR_STRIDE,%ecx,%ecx
	leal (%ecx,%eax,4),%eax
	movl _sb_nums(%eax),%ecx
	pushl %ecx
	pushl 12(%ebp)
	pushl %ebx
	call _Sbar_DrawTransPic
	addl $12,%esp
	addl $24,%ebx
	incl %edi
	jmp .Lsbar_drawnum_loop

.Lsbar_drawnum_done:
	addl $12,%esp
	popl %edi
	popl %esi
	popl %ebx
	leave
	ret

#endif /* ASM486_SBAR_PRIMITIVES */

#ifdef ASM486_SBAR_DRAW
#include "sbar_draw_asm.inc"
#endif

#ifdef ASM486_SBAR_INVENTORY
#include "sbar_inventory_asm.inc"
#endif

#ifdef ASM486_SBAR_FRAGS
#include "sbar_sortfrags_asm.inc"
#include "sbar_frags_asm.inc"
#endif
