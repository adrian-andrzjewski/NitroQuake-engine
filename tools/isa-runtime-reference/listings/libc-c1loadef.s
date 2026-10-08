	.file	"c1loadef.c"
	.section .text
LC0:
	.ascii "DJGPP\0"
LC1:
	.ascii "\\/:\0"
LC2:
	.ascii ":;/\\<>\0"
	.p2align 4,,15
	.globl	___crt0_load_environment_file
___crt0_load_environment_file:
LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$604, %esp
	.cfi_offset 7, -12
	.cfi_offset 6, -16
	.cfi_offset 3, -20
	movl	$LC0, (%esp)
	call	_getenv
	testl	%eax, %eax
	je	L1
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__open
	movl	%eax, %esi
	testl	%eax, %eax
	js	L1
	movl	$2, 8(%esp)
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	___lseek
	movl	%eax, %ebx
	leal	2(%eax), %eax
	movl	%eax, (%esp)
	call	_malloc
	movl	%eax, -564(%ebp)
	testl	%eax, %eax
	je	L1
	movl	$0, 8(%esp)
	movl	$0, 4(%esp)
	movl	%esi, (%esp)
	call	___lseek
	movl	-564(%ebp), %eax
	movl	%ebx, 8(%esp)
	movl	%eax, 4(%esp)
	movl	%esi, (%esp)
	call	__read
	movl	%esi, (%esp)
	call	__close
	movl	-564(%ebp), %eax
	cmpb	$10, -1(%eax,%ebx)
	je	L189
	movl	-564(%ebp), %eax
	movb	$10, (%eax,%ebx)
	movb	$0, 1(%eax,%ebx)
L7:
	movl	8(%ebp), %edx
	movb	$91, -536(%ebp)
	movsbl	(%edx), %eax
	testb	%al, %al
	je	L65
	movl	%edx, %edi
	movl	%edx, %esi
	incl	%edi
	.p2align 4,,7
L11:
	movl	%eax, 4(%esp)
	movl	$LC1, (%esp)
	call	_strchr
	testl	%eax, %eax
	je	L10
	movl	%edi, %esi
L10:
	movsbl	(%edi), %eax
	incl	%edi
	testb	%al, %al
	jne	L11
	movb	(%esi), %al
	leal	-535(%ebp), %edx
	cmpb	$46, %al
	je	L8
	.p2align 4,,7
L184:
	testb	%al, %al
	je	L8
	andl	$255, %eax
	incl	%esi
	movb	___dj_ctype_tolower+1(%eax), %al
	movb	%al, (%edx)
	movb	(%esi), %al
	incl	%edx
	cmpb	$46, %al
	jne	L184
L8:
	addl	$30, %ebx
	movl	-564(%ebp), %eax
	movl	%ebx, -580(%ebp)
	movb	$93, (%edx)
	movl	-580(%ebp), %ecx
	movb	$0, 1(%edx)
	shrl	$4, %ecx
	movl	%eax, -540(%ebp)
	movl	$1, -568(%ebp)
	movl	%ecx, -580(%ebp)
	.p2align 4,,7
L170:
	movl	-540(%ebp), %edx
	movb	(%edx), %al
	testb	%al, %al
	je	L15
	movl	-540(%ebp), %edi
	cmpb	$10, %al
	je	L169
	jmp	L203
	.p2align 4,,7
L18:
	cmpb	$13, %al
	jne	L191
L169:
	incl	%edi
	movb	(%edi), %al
	testb	%al, %al
	jne	L18
L15:
	movl	-564(%ebp), %eax
	movl	%eax, (%esp)
	call	_free
L1:
	leal	-12(%ebp), %esp
	popl	%ebx
	.cfi_remember_state
	.cfi_restore 3
	popl	%esi
	.cfi_restore 6
	popl	%edi
	.cfi_restore 7
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.p2align 4,,7
L191:
	.cfi_restore_state
	cmpb	$10, %al
	je	L169
L16:
	movl	%edi, %edx
	cmpb	$10, %al
	jne	L186
	jmp	L19
	.p2align 4,,7
L134:
	incl	%edx
	movb	(%edx), %al
	cmpb	$10, %al
	je	L19
L186:
	testb	%al, %al
	je	L19
	cmpb	$13, %al
	jne	L134
L64:
	leal	1(%edx), %eax
	movb	$0, (%edx)
	movl	%eax, -540(%ebp)
	movb	(%edi), %al
	cmpb	$35, %al
	je	L170
	testb	%al, %al
	je	L170
	cmpb	$91, %al
	je	L192
	movl	-568(%ebp), %edx
	testl	%edx, %edx
	je	L170
	movl	-580(%ebp), %edx
	sall	$4, %edx
	subl	%edx, %esp
	leal	27(%esp), %ecx
	andl	$-16, %ecx
	cmpb	$10, %al
	movl	%ecx, %ebx
	je	L69
	cmpb	$61, %al
	jne	L32
	jmp	L69
	.p2align 4,,7
L193:
	cmpb	$61, %al
	je	L80
	testb	%al, %al
	je	L170
L32:
	incl	%edi
	movb	%al, (%ebx)
	incl	%ebx
	movb	(%edi), %al
	cmpb	$10, %al
	jne	L193
L80:
	testb	%al, %al
	sete	%dl
L29:
	cmpb	$10, %al
	je	L170
	testb	%dl, %dl
	jne	L170
	movl	%ecx, -592(%ebp)
	cmpb	$43, (%ecx)
	je	L194
L33:
	movb	(%edi), %al
	leal	1(%ebx), %esi
	movb	%al, (%ebx)
	incl	%edi
L171:
	movb	(%edi), %al
	testb	%al, %al
	je	L62
	.p2align 4,,7
L63:
	cmpb	$37, %al
	je	L195
	movb	%al, (%esi)
	incl	%edi
	incl	%esi
L202:
	movb	(%edi), %al
	testb	%al, %al
	jne	L63
L62:
	movl	-592(%ebp), %edx
	movb	$0, (%esi)
	movl	%edx, (%esp)
	call	___putenv
	jmp	L170
	.p2align 4,,7
L192:
	leal	-1(%edx), %eax
	cmpl	%edi, %eax
	jbe	L26
	movb	-1(%edx), %dl
	cmpb	$9, %dl
	je	L168
	jmp	L182
	.p2align 4,,7
L196:
	movb	(%eax), %dl
	cmpb	$9, %dl
	jne	L182
L168:
	decl	%eax
	cmpl	%edi, %eax
	jne	L196
L26:
	movb	$0, 1(%eax)
	leal	-536(%ebp), %eax
	movl	%eax, 4(%esp)
	movl	%edi, (%esp)
	call	_strcmp
	testl	%eax, %eax
	sete	%dl
	andl	$255, %edx
	movl	%edx, -568(%ebp)
	jmp	L170
L182:
	cmpb	$32, %dl
	je	L168
	jmp	L26
	.p2align 4,,7
L195:
	movb	1(%edi), %dl
	cmpb	$37, %dl
	je	L197
	movl	$0, -560(%ebp)
	movl	$0, -556(%ebp)
	movl	$0, -548(%ebp)
	movl	$0, -544(%ebp)
	movl	$0, -576(%ebp)
	movl	$0, -572(%ebp)
	movb	%dl, %bl
	.p2align 4,,7
L36:
	movsbl	%bl, %eax
	movl	%eax, 4(%esp)
	movl	$LC2, (%esp)
	call	_strchr
	testl	%eax, %eax
	je	L198
	subl	$47, %ebx
	cmpb	$45, %bl
	ja	L40
	andl	$255, %ebx
	jmp	*L45(,%ebx,4)
	.p2align 2
	.p2align 2
L45:
	.long	L39
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L72
	.long	L41
	.long	L42
	.long	L40
	.long	L43
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L40
	.long	L44
	.p2align 4,,7
L72:
	movl	$1, -572(%ebp)
L40:
	incl	%edi
	movb	1(%edi), %bl
	jmp	L36
	.p2align 4,,7
L44:
	incl	%edi
	movl	$1, -560(%ebp)
	movb	1(%edi), %bl
	jmp	L36
	.p2align 4,,7
L43:
	incl	%edi
	movl	$1, -548(%ebp)
	movb	1(%edi), %bl
	jmp	L36
	.p2align 4,,7
L42:
	incl	%edi
	movl	$1, -544(%ebp)
	movb	1(%edi), %bl
	jmp	L36
	.p2align 4,,7
L41:
	incl	%edi
	movl	$1, -576(%ebp)
	movb	1(%edi), %bl
	jmp	L36
	.p2align 4,,7
L39:
	incl	%edi
	movl	$1, -556(%ebp)
	movb	1(%edi), %bl
	jmp	L36
	.p2align 4,,7
L198:
	leal	1(%edi), %eax
	movb	%bl, %dl
	movl	%eax, %edi
	cmpb	$37, %bl
	jne	L187
	jmp	L47
	.p2align 4,,7
L199:
	incl	%edi
	movb	(%edi), %dl
	cmpb	$37, %dl
	je	L47
L187:
	testb	%dl, %dl
	jne	L199
L47:
	movb	$0, (%edi)
	movl	%eax, (%esp)
	movb	%dl, -596(%ebp)
	call	_getenv
	movb	-596(%ebp), %dl
	testl	%eax, %eax
	je	L74
	movb	(%eax), %bl
	testb	%bl, %bl
	je	L200
	movl	%edi, -584(%ebp)
	movl	%esi, -552(%ebp)
	movl	%eax, %edi
	movb	%dl, -585(%ebp)
	jmp	L59
	.p2align 4,,7
L81:
	cmpb	$47, %bl
	jne	L57
L172:
	cmpb	$0, -560(%ebp)
	je	L57
	movb	$92, %bl
L57:
	movb	%bl, (%esi)
	incl	%esi
	movb	(%edi), %bl
	testb	%bl, %bl
	je	L201
L59:
	movsbl	%bl, %eax
	movl	%eax, 4(%esp)
	movl	$LC1, (%esp)
	call	_strchr
	incl	%edi
	testl	%eax, %eax
	je	L52
	movl	%esi, -552(%ebp)
L52:
	movl	-544(%ebp), %eax
	testl	%eax, %eax
	je	L53
	andl	$255, %ebx
	movb	___dj_ctype_toupper+1(%ebx), %bl
L53:
	movl	-548(%ebp), %eax
	testl	%eax, %eax
	je	L54
	andl	$255, %ebx
	movb	___dj_ctype_tolower+1(%ebx), %bl
L54:
	cmpb	$92, %bl
	jne	L81
	cmpb	$0, -556(%ebp)
	je	L81
	movb	$47, %bl
	jmp	L172
	.p2align 4,,7
L201:
	movl	%edi, %ecx
	movl	-576(%ebp), %ebx
	testl	%ecx, %ecx
	movl	-584(%ebp), %edi
	setne	%al
	movb	-585(%ebp), %dl
	andl	%ebx, %eax
L50:
	movl	-572(%ebp), %ecx
	testl	%ecx, %ecx
	je	L60
	movl	-552(%ebp), %esi
L60:
	testb	%al, %al
	je	L61
	movb	$59, (%esi)
	incl	%esi
L61:
	testb	%dl, %dl
	je	L62
	incl	%edi
	jmp	L202
L197:
	movb	$37, (%esi)
	addl	$2, %edi
	incl	%esi
	jmp	L171
L203:
	cmpb	$13, %al
	je	L169
	jmp	L16
	.p2align 4,,7
L189:
	movb	$0, (%eax,%ebx)
	jmp	L7
L74:
	movl	%esi, -552(%ebp)
	xorl	%eax, %eax
	jmp	L50
L200:
	movb	-576(%ebp), %al
	movl	%esi, -552(%ebp)
	jmp	L50
L65:
	leal	-535(%ebp), %edx
	jmp	L8
L194:
	movl	-592(%ebp), %eax
	movb	$0, (%ebx)
	incl	%eax
	movl	%eax, -592(%ebp)
	movl	-592(%ebp), %edx
	movl	%edx, (%esp)
	call	_getenv
	testl	%eax, %eax
	jne	L170
	jmp	L33
L69:
	xorl	%edx, %edx
	jmp	L29
	.p2align 4,,7
L19:
	testb	%al, %al
	jne	L64
	jmp	L15
	.cfi_endproc
LFE0:
	.ident	"GCC: (GNU) 4.7.4"
