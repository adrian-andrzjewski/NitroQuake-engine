	.file	"is_exec.c"
	.section .text
	.p2align 4,,15
	.globl	__get_magic
__get_magic:
LFB17:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$92, %esp
	.cfi_def_cfa_offset 112
	movl	112(%esp), %edx
	testl	%edx, %edx
	je	L2
	movl	112(%esp), %eax
	movl	$0, 4(%esp)
	movl	%eax, (%esp)
	call	__open
	cmpl	$-1, %eax
	je	L29
	movw	%ax, 44(%esp)
	xorl	%esi, %esi
	xorl	%edi, %edi
	leal	28(%esp), %ebp
L5:
	movl	__go32_info_block+12, %eax
	movl	%ebp, 4(%esp)
	shrl	$4, %eax
	movl	$33, (%esp)
	movw	%ax, 64(%esp)
	movw	$0, 48(%esp)
	movw	$16128, 56(%esp)
	movw	$2, 52(%esp)
	call	___dpmi_int
	movl	56(%esp), %eax
	cmpw	$2, %ax
	je	L13
	orl	$-1, %ebx
	testb	$1, 60(%esp)
	jne	L32
L7:
	movl	112(%esp), %eax
	testl	%eax, %eax
	je	L8
L34:
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movw	$15872, 56(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L33
L10:
	testl	%ebx, %ebx
	jne	L11
L35:
	movl	__go32_info_block+12, %eax
/APP
# 145 "c:/djgpp/include/libc/farptrgs.h" 1
	movw __go32_info_block+26, %gs 
	.byte 0x65 
	movw (%eax),%ax 

# 0 "" 2
/NO_APP
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L11:
	.cfi_restore_state
	cmpl	$-1, %ebx
	je	L29
	movl	%ebx, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
L29:
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L32:
	.cfi_restore_state
	movl	%eax, %ebx
	movl	112(%esp), %eax
	andl	$65535, %ebx
	testl	%eax, %eax
	jne	L34
L8:
	movl	116(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movw	$16896, 56(%esp)
	movw	%ax, 44(%esp)
	movw	%di, 52(%esp)
	movw	%si, 48(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	je	L10
L30:
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	movl	%eax, _errno
	addl	$92, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L13:
	.cfi_restore_state
	xorl	%ebx, %ebx
	jmp	L7
	.p2align 4,,7
L33:
	movl	56(%esp), %eax
	andl	$65535, %eax
	movl	%eax, (%esp)
	call	___doserr_to_errno
	testl	%ebx, %ebx
	movl	%eax, _errno
	jne	L11
	jmp	L35
	.p2align 4,,7
L2:
	leal	28(%esp), %ebp
	movl	116(%esp), %eax
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movw	$16897, 56(%esp)
	movw	%ax, 44(%esp)
	movw	$0, 48(%esp)
	movw	$0, 52(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	jne	L30
	movl	%ebp, 4(%esp)
	movl	$33, (%esp)
	movl	48(%esp), %edi
	movl	56(%esp), %esi
	movw	$0, 48(%esp)
	movw	$16896, 56(%esp)
	movw	$0, 52(%esp)
	call	___dpmi_int
	testb	$1, 60(%esp)
	je	L5
	jmp	L30
	.cfi_endproc
LFE17:
	.p2align 4,,15
	.globl	__is_executable
__is_executable:
LFB18:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	pushl	%edi
	.cfi_def_cfa_offset 12
	.cfi_offset 7, -12
	pushl	%esi
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushl	%ebx
	.cfi_def_cfa_offset 20
	.cfi_offset 3, -20
	subl	$60, %esp
	.cfi_def_cfa_offset 80
	movl	88(%esp), %ebp
	movl	80(%esp), %ebx
	testl	%ebp, %ebp
	jne	L37
	testl	%ebx, %ebx
	jne	L86
L37:
	movw	__djstat_flags, %si
	testl	$2, %esi
	jne	L41
	testl	%ebp, %ebp
	je	L41
	movb	0(%ebp), %dl
	testb	%dl, %dl
	je	L41
	movl	%ebp, (%esp)
	movb	%dl, 28(%esp)
	call	_strlen
	movb	28(%esp), %dl
	cmpb	$46, %dl
	sete	%cl
	andl	$255, %ecx
	addl	$3, %ecx
	cmpl	%eax, %ecx
	jb	L41
	movb	$124, 42(%esp)
	cmpb	$46, %dl
	je	L87
L43:
	leal	43(%esp), %eax
	.p2align 4,,7
L45:
	andl	$255, %edx
	incl	%ebp
	movb	___dj_ctype_toupper+1(%edx), %dl
	movb	%dl, (%eax)
	movb	0(%ebp), %dl
	incl	%eax
	testb	%dl, %dl
	jne	L45
L44:
	leal	42(%esp), %edi
	movb	$124, (%eax)
	movb	$0, 1(%eax)
	movl	%edi, 4(%esp)
	movl	$_non_executables, (%esp)
	call	_strstr
	movl	%eax, %edx
	xorl	%eax, %eax
	testl	%edx, %edx
	jne	L74
	movl	%edi, 4(%esp)
	movl	$_executables, (%esp)
	call	_strstr
	movl	%eax, %edx
	movl	$1, %eax
	testl	%edx, %edx
	jne	L74
	.p2align 4,,7
L41:
	xorl	%eax, %eax
	andl	$4, %esi
	je	L88
L74:
	addl	$60, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L86:
	.cfi_restore_state
	movb	(%ebx), %al
	testb	%al, %al
	je	L38
	movl	%ebx, %edx
	xorl	%ecx, %ecx
	jmp	L40
	.p2align 4,,7
L90:
	cmpb	$47, %al
	je	L51
	cmpb	$58, %al
	setne	%al
	andl	$255, %eax
	negl	%eax
	andl	%eax, %ecx
L39:
	incl	%edx
	movb	(%edx), %al
	testb	%al, %al
	je	L89
L40:
	cmpb	$46, %al
	je	L50
	cmpb	$92, %al
	jne	L90
L51:
	incl	%edx
	xorl	%ecx, %ecx
	movb	(%edx), %al
	testb	%al, %al
	jne	L40
L89:
	movl	%ecx, %ebp
	jmp	L37
	.p2align 4,,7
L50:
	movl	%edx, %ecx
	jmp	L39
	.p2align 4,,7
L88:
	movl	84(%esp), %eax
	movl	%ebx, (%esp)
	movl	%eax, 4(%esp)
	call	__get_magic
	cmpw	$332, %ax
	je	L48
	jbe	L91
	cmpw	$8483, %ax
	je	L48
	cmpw	$23117, %ax
	je	L48
L57:
	addl	$60, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	xorl	%eax, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
	.p2align 4,,7
L91:
	.cfi_restore_state
	cmpw	$267, %ax
	jne	L57
	.p2align 4,,7
L48:
	addl	$60, %esp
	.cfi_remember_state
	.cfi_def_cfa_offset 20
	movl	$1, %eax
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 16
	popl	%esi
	.cfi_restore 6
	.cfi_def_cfa_offset 12
	popl	%edi
	.cfi_restore 7
	.cfi_def_cfa_offset 8
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa_offset 4
	ret
L38:
	.cfi_restore_state
	movw	__djstat_flags, %si
	jmp	L41
	.p2align 4,,7
L87:
	movb	1(%ebp), %dl
	leal	1(%ebp), %eax
	testb	%dl, %dl
	je	L53
	movl	%eax, %ebp
	jmp	L43
L53:
	leal	43(%esp), %eax
	jmp	L44
	.cfi_endproc
LFE18:
.comm __djstat_fail_bits,16
.comm __djstat_flags,16
	.section .data
	.p2align 4
_non_executables:
	.ascii "|A|A01|A02|A03|A04|A05|ADL|ARC|ARJ|ASC|ASM|AUX|AWK|BAS|BIB|BGI|BMP|C|CC|CFG|CGZ|CH3|CHR|CI|CLP|CMF|CPI|CPP|CXX|DAT|DBF|DIZ|DOC|DVI|E|EL|ELC|F77|FN3|GDT|GIF|GPR|GZ|H|HLP|HPP|HXX|ICO|IN|INC|INF|INI|INZ|JPG|L|LEX|LF|LIB|LOG|LST|LZH|M|MAK|MAP|MF|MID|MPG|O|OBJ|PAK|PAS|PBM|PCD|PCX|PDS|PIC|PIF|PN3|PRJ|PS|RAS|RGB|RGD|RLE|S|SND|SY3|TAR|TAZ|TEX|TGA|TGZ|TIF|TXH|TXI|TXT|VOC|WAV|WK1|WK3|WKB|WQ1|WQ3|WQ4|WQ5|WQ6|WQ!|XBM|Y|ZIP|ZOO|\0"
	.p2align 4
_executables:
	.ascii "|EXE|COM|BAT|BTM|DLL|VXD|\0"
	.ident	"GCC: (GNU) 4.7.4"
