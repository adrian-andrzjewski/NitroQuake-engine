/* Shared layout and constants for the console output i486 implementation. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_CONSOLE_OUTPUT_H
#define ASM_CONSOLE_OUTPUT_H

#define co_client_state_offset 0
#define co_client_signon_offset 2280
#define co_cvar_value_offset 16
#define co_dedicated_state 0
#define co_signons 4
#define co_max_print_message 4096
#define co_debuglog_buffer_size 1024
#define co_open_flags 0x1101
#define co_open_mode 0666

#ifndef __ASSEMBLER__
#include <stddef.h>
#include <fcntl.h>

typedef char co_client_state_offset_must_match[
	(offsetof(client_static_t, state) == co_client_state_offset) ? 1 : -1];
typedef char co_client_signon_offset_must_match[
	(offsetof(client_static_t, signon) == co_client_signon_offset) ? 1 : -1];
typedef char co_dedicated_state_must_match[
	(ca_dedicated == co_dedicated_state) ? 1 : -1];
typedef char co_signons_must_match[(SIGNONS == co_signons) ? 1 : -1];
typedef char co_cvar_value_offset_must_match[
	(offsetof(cvar_t, value) == co_cvar_value_offset) ? 1 : -1];
typedef char co_debuglog_open_flags_must_match[
	((O_WRONLY | O_CREAT | O_APPEND) == co_open_flags) ? 1 : -1];

#endif

#endif
