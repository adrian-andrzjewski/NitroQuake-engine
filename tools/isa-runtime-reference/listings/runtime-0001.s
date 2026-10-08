 .file "crt0.s"
 .comm __stklen, 4
 .comm __stubinfo, 4
 .comm ___djgpp_base_address, 4
 .comm ___djgpp_selector_limit, 4
 .comm ___djgpp_stack_limit, 4
 .comm ___djgpp_stack_top, 4
 .comm __crt0_startup_flags, 4
 .comm ___djgpp_ds_alias, 2
 .lcomm sel_buf, 8
 .data
___djgpp_memory_handle_pointer:
 .long ___djgpp_memory_handle_list+8
 .comm ___djgpp_memory_handle_list, 2048
 .comm ___djgpp_memory_handle_size, 1024
sbrk16_first_byte:
 .byte 0x12,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x02,0x00,0x00,0x00,0x00,0x00,0x00
 .byte 0x00,0x00,0x8c,0xd8,0x2e,0x8e,0x1e,0x06,0x00,0xa3,0x10,0x00,0x8c,0x16,0x0a,0x00
 .byte 0x66,0x89,0x26,0x0c,0x00,0x8e,0x16,0x06,0x00,0x66,0xbc,0x70,0x02,0x00,0x00,0xb8
 .byte 0x03,0x05,0xcd,0x31,0x72,0x24,0x89,0xca,0x89,0xd9,0x8b,0x1e,0x02,0x00,0xb8,0x07
 .byte 0x00,0xcd,0x31,0x8b,0x1e,0x04,0x00,0xb8,0x07,0x00,0xcd,0x31,0x06,0x07,0x0f,0xa0
 .byte 0x0f,0xa1,0x0f,0xa8,0x0f,0xa9,0x89,0xcb,0x89,0xd1,0x8e,0x16,0x0a,0x00,0x66,0x8b
 .byte 0x26,0x0c,0x00,0x8e,0x1e,0x10,0x00,0x66,0xcb,0x90,0x90,0x90
sbrk16_last_byte:
sbrk16_api_ofs:
 .long 0
sbrk16_api_seg:
 .word 0
zero:
 .long 0
_frame_struct:
 .long 0,0,0,0,0,0
 .long 0,0,0,0,0,0
.section .eh_frame
_CRT0_EH_FRAME_BEGIN_:
 .data
exit16_first_byte:
 .byte 0xb8,0x01,0x00,0xcd,0x31,0xb8,0x02,0x05,0xcd,0x31,0x88,0xd0,0xb4,0x4c,0xcd,0x21
exit16_last_byte:
hook_387_emulator:
 .long ___emu387_load_hook
 .long ___libc_ident_string
 .long _main
 .text
 .globl start
 .balign 16,,7
start:
 pushl %ds
 popl %es
 testb $0x1, __crt0_startup_flags+1
 jnz 1f
 movl $start, %eax
 cmpl $0x1000, %eax
 jl 1f
 movw $0x507, %ax
 .byte 0x64
 movl 0x18, %esi
 xorl %ebx, %ebx
 movl $1, %ecx
 movl $zero, %edx
 int $0x31
1:
 movw %ds, %bx
 movw $0x000a, %ax
 int $0x31
 jnc ds_alias_ok
 movb $0x4c, %ah
 int $0x21
ds_alias_ok:
 movw %ax, ___djgpp_ds_alias
 movl %eax, %ebx
 movw $0x0009, %ax
 movw %cs, %cx
 andl $3, %ecx
 shll $5, %ecx
 orw $0xc093, %cx
 int $0x31
 movw $0xffff, %cx
 movl %ecx, %edx
 movw $0x0008, %ax
 int $0x31
 lsl %ebx, %ebx
 incl %ebx
 jz 16f
 andb $0x7f, __crt0_startup_flags
 orb $0x80, __crt0_startup_flags+1
 jmp 2f
16: testb $0x80, __crt0_startup_flags
 jz 2f
 movw %cs, %bx
 movw $0x0008, %ax
 int $0x31
 movw %ds, %bx
 movw $0x0008, %ax
 int $0x31
2:
 testb $0x8, __crt0_startup_flags+1
 jz 8f
 movl $sbrk16_first_byte, %esi
 movzwl 8(%esi), %ebx
 shrl $4, %ebx
 movw $0x0100, %ax
 int $0x31
 jnc dos_alloc_ok
 movb $0x4c, %ah
 int $0x21
dos_alloc_ok:
 movw %cs, 2(%esi)
 movw %ds, 4(%esi)
 movw %dx, 6(%esi)
 movzwl (%esi), %eax
 movl %eax, sbrk16_api_ofs
 pushl %es
 movw %dx, %es
 movl $(sbrk16_last_byte - sbrk16_first_byte), %ecx
 shrl $2,%ecx
 xorl %edi, %edi
 cld
 rep
 movsl
 popl %es
 movl %edx, %ebx
 movw $0x000b, %ax
 movl $sel_buf, %edi
 int $0x31
 andb $0xbf, sel_buf+6
 andb $0xf0, sel_buf+5
 orb $0x0a, sel_buf+5
 xorl %eax, %eax
 movw $0x0001, %cx
 int $0x31
 movw %ax, sbrk16_api_seg
 movl %eax, %ebx
 movw $0x000c, %ax
 movl $sel_buf, %edi
 int $0x31
8: movl $___djgpp_memory_handle_list+8, %edi
 movl %edi, ___djgpp_memory_handle_pointer
 xorl %eax, %eax
9: cmpl %eax, (%edi)
 je 10f
 mov %eax, (%edi)
 addl $4, %edi
 jmp 9b
10: movw %cs, %bx
 movw $0x0006,%ax
 int $0x31
 movl %edx,___djgpp_base_address
 movw %cx,___djgpp_base_address+2
 .byte 0x64
 movl 0x1c, %eax
 movl %eax, __what_size_dpmi_thinks_we_are
 movl %eax, ___djgpp_memory_handle_size
 movl %ecx,%ebx
 movl %edx,%ecx
 addw $4096,%cx
 adcl $0,%ebx
 subl $4096,%eax
 pushl %eax
 call lock_memory
 .byte 0x64
 movl 0x18, %eax
 movl %eax, ___djgpp_memory_handle_list
 .byte 0x64
 movl 0x10, %eax
 pushl %eax
 call ___sbrk
 cmpl $-1, %eax
 je no_memory
 movl %eax, __stubinfo
 movl %eax, %edi
 .byte 0x64
 movl 0x10, %ecx
 shrl $2, %ecx
 xorl %esi, %esi
 pushl %ds
 pushl %fs
 popl %ds
 cld
 rep
 movsl
 popl %ds
 movl __stklen, %eax
 .byte 0x64
 movl 0x14, %ecx
 cmpl %ecx, %eax
 jge use_stubinfo_stack_size
 movl %ecx, %eax
 movl %eax, __stklen
use_stubinfo_stack_size:
 pushl %eax
 call ___sbrk
 cmpl $-1, %eax
 je no_memory
 movl %eax, ___djgpp_stack_limit
 addl __stklen, %eax
 movw %ds, %dx
 movw %dx, %ss
 andb $0xf8, %al
 movl %eax, %esp
 movl %eax, ___djgpp_stack_top
 subl ___djgpp_stack_limit, %eax
 movl %eax, __stklen
 xorl %ebp, %ebp
 pushl $_frame_struct
 pushl $_CRT0_EH_FRAME_BEGIN_
 call ___register_frame_info
 addl $8, %esp
 call ___crt1_startup
 jmp exit
no_memory:
 movb $0xff, %al
 jmp exit
 .global ___exit
 .balign 16,,7
___exit:
 movb 4(%esp), %al
exit:
 movb %al, %cl
 xorl %eax,%eax
 movw %ax,%fs
 movw %ax,%gs
 cli
 movw __go32_info_block+26, %bx; movw $0x0001, %ax; int $0x31
 movw ___djgpp_ds_alias, %bx; movw $0x0001, %ax; int $0x31
 testb $0x8, __crt0_startup_flags+1
 jz 9f
 movw sbrk16_api_seg, %bx; movw $0x0001, %ax; int $0x31
 movw sbrk16_first_byte+6,%dx
 movw $0x101, %ax
 int $0x31
9:
 movl __stubinfo, %edx
 movl 0x28(%edx), %eax
 movw %ax, sbrk16_api_seg
 xorl %edi, %edi
 movl %edi, sbrk16_api_ofs
 movw 0x22(%edx), %es
 movb %cl, %dl
 movl $exit16_first_byte, %esi
 movl $(exit16_last_byte - exit16_first_byte), %ecx
 cld
 rep
 movsb
 movw %es,%ax
 movw %ax,%ss
 movl $0x400,%esp
 movl ___djgpp_memory_handle_pointer, %ebx
 jmp 7f
6: subl $8, %ebx
 movl (%ebx), %edi
 movw 2(%ebx), %si
 movw $0x502, %ax
 int $0x31
7: cmpl $___djgpp_memory_handle_list+8, %ebx
 jne 6b
 xorl %ebp, %ebp
 movl ___djgpp_memory_handle_list, %edi
 movl ___djgpp_memory_handle_list+2, %esi
 movw %ds, %bx; movw $0x0001, %ax; int $0x31
 movw %cs, %bx
 .byte 0x2e
 ljmp *sbrk16_api_ofs
.data
__what_size_app_thinks_it_is:
 .long end
.text
 .lcomm __what_we_return_to_app_as_old_size, 4
 .lcomm __what_size_dpmi_thinks_we_are, 4
lock_memory:
 testb $0x10, __crt0_startup_flags+1
 jz 13f
 pushl %esi
 pushl %edi
 pushl %eax
 movl 16(%esp),%edi
 movw 18(%esp),%si
 movw $0x600,%ax
 int $0x31
 popl %eax
 popl %edi
 popl %esi
13: ret $4
 .global ___sbrk
 .balign 16,,7
___sbrk:
 movl __what_size_app_thinks_it_is, %eax
 movl 4(%esp), %ecx
 addl %ecx, %eax
 jnc brk_common
 test $0x80000000, %ecx
 jnz brk_common
 stc
 jmp brk_common
 .globl ___brk
 .balign 16,,7
___brk:
 movl 4(%esp), %eax
 clc
 .balign 16,,7
brk_common:
 pushl %esi
 pushl %edi
 pushl %ebx
 movl __what_size_app_thinks_it_is, %edx
 movl %edx, __what_we_return_to_app_as_old_size
 movl %eax, __what_size_app_thinks_it_is
 jc 10f
 cmpl __what_size_dpmi_thinks_we_are, %eax
 jbe brk_nochange
 testb $0x8, __crt0_startup_flags+1
 jz 10f
 addl $0x0000ffff, %eax
 andl $0xffff0000, %eax
 push %eax
 movl ___djgpp_memory_handle_list, %edi
 movw ___djgpp_memory_handle_list+2, %si
 movl %eax, %ecx
 movl %eax, %ebx
 shrl $16, %ebx
 movw $0x0900, %ax
 int $0x31
 pushl %eax
 lcall *sbrk16_api_ofs
 setc %dl
 popl %eax
 int $0x31
 test %dl,%dl
 popl %edx
 jne brk_error
 movl %edi, ___djgpp_memory_handle_list
 movw %si, ___djgpp_memory_handle_list+2
 movl %edx, ___djgpp_memory_handle_size
 movl %ecx, ___djgpp_base_address
 movw %bx, ___djgpp_base_address+2
 movl %edx, %eax
 movl __what_size_dpmi_thinks_we_are, %ecx
 subl %ecx, %eax
 addl ___djgpp_base_address, %ecx
 movl %ecx, %ebx
 shrl $16, %ebx
 pushl %eax
 call lock_memory
 decl %edx
 jmp 5f
10: movl %ecx, %eax
14: pushl %eax
 movl ___djgpp_memory_handle_pointer, %ecx
 xorl %edx, %edx
 subl $___djgpp_memory_handle_list, %ecx
 shrl $8, %ecx
 incl %edx
 addb $16, %cl
 shll %cl, %edx
 decl %edx
 movl %edx, %ecx
 notl %edx
 addl %ecx, %eax
 andl %edx, %eax
 movl %eax, %edx
 movl %eax, %ecx
 movl %eax, %ebx
 shrl $16, %ebx
 movw $0x501,%ax
 int $0x31
 popl %eax
 jc brk_error
 pushw %bx
 pushw %cx
 popl %ecx
 cmpl ___djgpp_base_address, %ecx
 jns 15f
 testb $0x80, __crt0_startup_flags+1
 jnz 14b
15:
 pushl %edx
 call lock_memory
 subl ___djgpp_base_address, %ecx
 cmpl %ecx, __what_size_dpmi_thinks_we_are
 je 4f
 movl %ecx, __what_size_dpmi_thinks_we_are
 movl %ecx, __what_we_return_to_app_as_old_size
4:
 movl __what_we_return_to_app_as_old_size, %ebx
 addl %ebx, %eax
 movl %eax, __what_size_app_thinks_it_is
 movl ___djgpp_memory_handle_pointer, %ebx
 movl %edi, (%ebx)
 movw %si, 2(%ebx)
 movl %ecx, 4(%ebx)
 movl %ebx, %edi
 subl $___djgpp_memory_handle_list, %edi
 shrl $1, %edi
 addl $___djgpp_memory_handle_size, %edi
 movl %edx, (%edi)
 addl $8, %ebx
 cmpl $___djgpp_memory_handle_list+2040, %ebx
 je 11f
 movl %ebx, ___djgpp_memory_handle_pointer
11:
 addl %ecx, %edx
 decl %edx
 cmpl ___djgpp_selector_limit, %edx
 jbe 12f
5: movl %edx, ___djgpp_selector_limit
 orw $0x0fff, %dx
 movw $0x0008, %ax
 movw %cs, %bx
 movl %edx, %ecx
 shrl $16, %ecx
 int $0x31
 testb $0x80, __crt0_startup_flags
 jnz 3f
 movw $0x0008, %ax
 movw %ds, %bx
 int $0x31
 movw $0x0008, %ax
 movl ___djgpp_ds_alias, %ebx
 int $0x31
3:
 movw $0x0007, %ax
 movl ___djgpp_ds_alias, %ebx
 movl ___djgpp_base_address, %edx
 movw ___djgpp_base_address+2, %cx
 int $0x31
 movl ___djgpp_selector_limit, %edx
12: incl %edx
 testb $0x60, __crt0_startup_flags
 jz no_fill_sbrk_memory
 pushl %ds
 popl %es
 movl __what_size_dpmi_thinks_we_are, %edi
 movl %edx, %ecx
 subl %edi, %ecx
 xorl %eax, %eax
 testb $0x40, __crt0_startup_flags
 jz no_deadbeef
 movl $0xdeadbeef, %eax
no_deadbeef:
 shrl $2, %ecx
 cld
 rep
 stosl
no_fill_sbrk_memory:
 movl %edx, __what_size_dpmi_thinks_we_are
brk_nochange:
 movl __what_we_return_to_app_as_old_size, %eax
 jmp brk_return
brk_error:
 movl __what_we_return_to_app_as_old_size, %eax
 movl %eax, __what_size_app_thinks_it_is
 movl $-1, %eax
brk_return:
 popl %ebx
 popl %edi
 popl %esi
 ret
 .globl __crt0_init_mcount
__crt0_init_mcount:
 ret
