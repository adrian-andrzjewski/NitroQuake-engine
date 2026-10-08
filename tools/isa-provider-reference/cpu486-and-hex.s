/* Derived from Charles W. Sandmann / DJ Delorie CWSDPMI R1 MSWITCH.ASM.
   Modified for an explicitly bounded i486 ISA: omit ID/CPUID detection after
   successful AC-flag detection. Keep the original 8086/286/386 paths and the
   original CPU-family return tail at its existing address.
   A small hexadecimal helper replaces AAM 16 + XCHG in the Borland formatter.
   Only AX and its documented flags change; all other registers and SP remain
   intact. GPL; retain verbatim COPYING.CWS and COPYING with this derivative. */
.arch i386
.code16
.text
.globl _cpu486_patch
_cpu486_patch:
    clc /* Match the original early-486 failed ID-toggle carry. */
    jmp .Lcpu486
.globl _hex_nibbles
_hex_nibbles:
    movb %al,%ah
    shrb $4,%al
    andb $15,%ah /* SF/ZF/PF retain the original low-nibble AAM result. */
    ret
    /* Unreachable padding preserves every following original address. */
    .byte 0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90
.Lcpu486:
    incw %cx
    incw %cx
    incw %cx
    incw %cx
    movw %cx,%ax
    ret
.globl _cpu486_patch_end
_cpu486_patch_end:
