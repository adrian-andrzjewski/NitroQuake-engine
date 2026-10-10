/* Shared layout constants for the Con_DrawInput i486 implementation. */
#ifndef ASM_CONSOLEINPUT_H
#define ASM_CONSOLEINPUT_H

#define ci_key_console       1
#define ci_key_line_bytes    256

#ifndef __ASSEMBLER__
typedef char console_input_key_line_size_must_match[
    (MAXCMDLINE == ci_key_line_bytes) ? 1 : -1];
typedef char console_input_key_console_must_match[
    (key_console == ci_key_console) ? 1 : -1];
#endif

#endif
