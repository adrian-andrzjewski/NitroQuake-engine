/* Public renderer entry ABI; constants shared with the assembly module. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_PUBLIC_BINDINGS_H
#define ASM_PUBLIC_BINDINGS_H
#define ASM_PUBLIC_BINDINGS_ALIAS_GLUE_PROFILE 28
#ifndef __ASSEMBLER__
typedef char public_bindings_pointer_32[(sizeof(void *) == 4) ? 1 : -1];
typedef char public_bindings_integer_32[(sizeof(int) == 4 && sizeof(long) == 4) ? 1 : -1];
#ifdef PROFILE486
typedef char public_bindings_profile_enum_check[
 (BENCH486_PROFILE_ALIAS_GLUE == ASM_PUBLIC_BINDINGS_ALIAS_GLUE_PROFILE) ? 1 : -1];
#endif
#endif
#endif
