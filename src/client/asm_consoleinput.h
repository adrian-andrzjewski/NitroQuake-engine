/* Shared key-state constants for the i486 console drawing implementations. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_CONSOLEINPUT_H
#define ASM_CONSOLEINPUT_H

#define ci_key_console       1
#define ci_key_message       2
#define ci_key_line_bytes    256
#define ci_num_con_times     4

#ifndef __ASSEMBLER__
typedef char console_input_key_line_size_must_match[
    (MAXCMDLINE == ci_key_line_bytes) ? 1 : -1];
typedef char console_input_key_console_must_match[
    (key_console == ci_key_console) ? 1 : -1];
typedef char console_notify_key_message_must_match[
(key_message == ci_key_message) ? 1 : -1];
typedef char console_notify_time_count_must_match[
(NUM_CON_TIMES == ci_num_con_times) ? 1 : -1];
typedef char console_notify_cvar_value_offset_must_match[
(__builtin_offsetof(cvar_t, value) == 16) ? 1 : -1];
#endif

#endif
