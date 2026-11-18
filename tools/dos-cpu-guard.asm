; NitroQuake startup CPU guard, 2026-11-18. GPL-2.0-or-later.
; DJASM fragment appended before the pinned loader's BSS, with .start moved
; here. Until nq_386 only 8086 instructions are used. ES (DOS PSP), the stack,
; general registers and FLAGS are restored before entering the original loader.
; No CPUID, speculative opcode tests, BIOS equipment bits or runtime libraries.
;
; Algorithm reference: Intel AP-485, examples 1 and 2 (FLAGS/AC and x87).
; https://bochs.sourceforge.io/techspec/intel-proc-identification-and-cpuid.pdf

        .start
nq_cpu_guard:
        pushf
        push ax
        push cx
        push dx
        push ds
        push cs
        pop ds
        pushf
        pop cx

        ; 8086/186: high FLAGS bits remain set when asked to clear them.
        mov ax, cx
        and ax, 0x0fff
        push ax
        popf
        pushf
        pop ax
        and ax, 0xf000
        cmp ax, 0xf000
        jne nq_check_286
        jmpl nq_no_386
nq_check_286:
        ; 286 real mode: high FLAGS bits remain clear when asked to set them.
        mov ax, cx
        or ax, 0xf000
        push ax
        popf
        pushf
        pop ax
        and ax, 0xf000
        jnz nq_386
        jmpl nq_no_386
nq_386:
        push cx
        popf
        push si
        mov si, sp
        ; All stack accesses while AC is toggled must be dword aligned.
        and sp, 0xfffc
        push eax
        push ecx
        pushfd
        pop eax
        mov ecx, eax
        xor eax, 0x40000
        push eax
        popfd
        pushfd
        pop eax
        push ecx
        popfd
        xor eax, ecx
        test eax, 0x40000
        jnz nq_check_fpu
        jmpl nq_no_486
nq_check_fpu:
        ; EM or TS would make even a no-wait x87 instruction raise #NM.
        ; SMSW is unprivileged on the supported 386/486 DOS targets.
        smsw ax
        test ax, 0x000c
        jz nq_probe_fpu
        jmpl nq_no_fpu
nq_probe_fpu:
        ; DJASM has no x87 mnemonics. These marked directives are CODE in the
        ; source-bound loader proof, including each instruction's address word.
        ; FNINIT / FNSTSW m16 / FNSTCW m16 have no FWAIT prefix: an absent
        ; coprocessor must never reach WAIT or a floating-point calculation.
        .db 0xdb, 0xe3 ; NQ CODE: fninit
        movw [nq_fpu_word], 0x5a5a
        .db 0xdd, 0x3e ; NQ CODE: fnstsw m16
        .dw nq_fpu_word ; NQ CODE: address
        cmpw [nq_fpu_word], 0
        je nq_fpu_status_ok
        jmpl nq_no_fpu
nq_fpu_status_ok:
        .db 0xd9, 0x3e ; NQ CODE: fnstcw m16
        .dw nq_fpu_word ; NQ CODE: address
        mov ax, [nq_fpu_word]
        and ax, 0x103f
        cmp ax, 0x003f
        je nq_check_387
        jmpl nq_no_fpu
nq_check_387:
        ; Presence is known. Use only 8087/287-safe operations to distinguish
        ; projective (+inf == -inf) from 387 affine infinity. All exceptions
        ; are masked by FNINIT; WAIT is safe only after the presence check.
        .db 0xd9, 0xe8 ; NQ CODE: fld1
        .db 0xd9, 0xee ; NQ CODE: fldz
        .db 0xde, 0xf9 ; NQ CODE: fdivp st1, st0
        .db 0xd9, 0xc0 ; NQ CODE: fld st0
        .db 0xd9, 0xe0 ; NQ CODE: fchs
        .db 0xde, 0xd9 ; NQ CODE: fcompp
        .db 0x9b ; NQ CODE: fwait
        .db 0xdd, 0x3e ; NQ CODE: fnstsw m16
        .dw nq_fpu_word ; NQ CODE: address
        testw [nq_fpu_word], 0x4000
        jz nq_cpu_ok
        jmpl nq_no_fpu
nq_cpu_ok:
        .db 0xdb, 0xe3 ; NQ CODE: fninit
        pop ecx
        pop eax
        mov sp, si
        pop si
        pop ds
        pop dx
        pop cx
        pop ax
        popf
        jmpl nq_loader_start

nq_no_386:
        mov dx, nq_msg_386
        jmp nq_reject_cpu
nq_no_486:
        mov dx, nq_msg_486
        jmp nq_reject_cpu
nq_no_fpu:
        mov dx, nq_msg_fpu
nq_reject_cpu:
        cld ; DOS string services require the forward direction.
        mov ah, 9
        int 0x21
        mov dx, nq_msg_minimum
        mov ah, 9
        int 0x21
        mov ax, 0x4c01
        int 0x21

nq_fpu_word:
        .dw 0
nq_msg_386:
        .db "NitroQuake: missing 32-bit 386 CPU instructions.\r\n$"
nq_msg_486:
        .db "NitroQuake: missing 486 CPU instruction set (AC flag unavailable).\r\n$"
nq_msg_fpu:
        .db "NitroQuake: usable 387-compatible x87 FPU missing (absent/disabled/older).\r\n$"
nq_msg_minimum:
        .db "Minimum: Intel 486DX-compatible CPU with a 387-compatible x87 FPU.\r\n$"
