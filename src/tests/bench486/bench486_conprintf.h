/* Exact C/i486 parity for console formatting, logging and update flow. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_CONPRINTF_H
#define BENCH486_CONPRINTF_H

#if defined(BENCH486)

#include <stdarg.h>
#include "client/asm_consoleoutput.h"

#define BCO_TRACE_CAPACITY 16
#define BCO_CAPTURE_FD 0x4864

extern qboolean con_initialized, con_debuglog;
extern qboolean scr_disabled_for_loading;
extern client_static_t cls;
extern cvar_t developer;
extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
#ifdef ASM486_CONSOLE_INPUT
extern void Con_DebugLog_Console_C (char *file, char *format, ...);
extern void Con_Printf_Console_C (char *format, ...);
extern void Con_DPrintf_Console_C (char *format, ...);
#define BCO_CON_DEBUGLOG_C Con_DebugLog_Console_C
#define BCO_CON_PRINTF_C Con_Printf_Console_C
#define BCO_CON_DPRINTF_C Con_DPrintf_Console_C
#else
extern void Con_DebugLog (char *file, char *format, ...);
extern void Con_Printf (char *format, ...);
extern void Con_DPrintf (char *format, ...);
#define BCO_CON_DEBUGLOG_C Con_DebugLog
#define BCO_CON_PRINTF_C Con_Printf
#define BCO_CON_DPRINTF_C Con_DPrintf
#endif
extern void Con_DebugLog_asm486 (char *file, char *format, ...);
extern void Con_Printf_asm486 (char *format, ...);
extern void Con_DPrintf_asm486 (char *format, ...);
extern int con_printf_inupdate_asm486;
extern int bench486_memory_failures;

enum
{
	BCO_SYS_PRINTF = 1,
	BCO_OPEN,
	BCO_WRITE,
	BCO_CLOSE,
	BCO_UPDATE_SCREEN
};

typedef struct
{
	char sys_text[co_max_print_message];
	char log_file[128];
	int open_flags;
	int open_mode;
	int write_fd;
	unsigned write_count;
	char log_data[co_max_print_message];
	unsigned open_calls;
	unsigned write_calls;
	unsigned close_calls;
	unsigned sys_printf_calls;
	unsigned update_calls;
	unsigned trace_count;
	unsigned trace[BCO_TRACE_CAPACITY];
} bench486_console_output_events_t;

typedef struct
{
	bench486_conprint_result_t console;
	bench486_console_output_events_t events;
	unsigned abi;
} bench486_conprintf_result_t;

typedef struct
{
	bench486_conprint_saved_t console;
	int con_initialized_value;
	int con_debuglog_value;
	int cls_state;
	int cls_signon;
	int loading_disabled;
	char game_dir[MAX_OSPATH];
	float developer_value;
	int inupdate_asm;
} bench486_conprintf_saved_t;

bench486_console_output_events_t bench486_console_output_events;
void (*bench486_console_output_recursive_function)(char *format, ...);
int bench486_console_output_recurse_on_update;

static bench486_conprintf_result_t bench486_conprintf_c_result;
static bench486_conprintf_result_t bench486_conprintf_asm_result;
static char bench486_conprintf_game_dir[] = "bench";
static char bench486_conprintf_log_file[] = "bench-direct.log";
static char bench486_conprintf_string[] = "console";

static void Bench486ConsoleOutputTrace (unsigned event)
{
	if (bench486_console_output_events.trace_count < BCO_TRACE_CAPACITY)
		bench486_console_output_events.trace[
				bench486_console_output_events.trace_count++] = event;
}

int Bench486ConsoleOutputOpen (char *file, int flags, int mode)
{
	unsigned i;
	bench486_console_output_events.open_calls++;
	bench486_console_output_events.open_flags = flags;
	bench486_console_output_events.open_mode = mode;
	for (i = 0; i + 1 < sizeof(bench486_console_output_events.log_file) &&
			file[i]; i++)
		bench486_console_output_events.log_file[i] = file[i];
	bench486_console_output_events.log_file[i] = 0;
	Bench486ConsoleOutputTrace (BCO_OPEN);
	return BCO_CAPTURE_FD;
}

int Bench486ConsoleOutputWrite (int fd, char *data, unsigned count)
{
	unsigned i;
	bench486_console_output_events.write_calls++;
	bench486_console_output_events.write_fd = fd;
	bench486_console_output_events.write_count = count;
	for (i = 0; i < count && i + 1 < sizeof(
			bench486_console_output_events.log_data); i++)
		bench486_console_output_events.log_data[i] = data[i];
	bench486_console_output_events.log_data[i] = 0;
	Bench486ConsoleOutputTrace (BCO_WRITE);
	return (int)count;
}

int Bench486ConsoleOutputClose (int fd)
{
	bench486_console_output_events.close_calls++;
	bench486_console_output_events.write_fd = fd;
	Bench486ConsoleOutputTrace (BCO_CLOSE);
	return 0;
}

void Bench486ConsoleOutputSysPrintf (char *format, ...)
{
	va_list arguments;
	va_start (arguments, format);
	vsprintf (bench486_console_output_events.sys_text, format, arguments);
	va_end (arguments);
	bench486_console_output_events.sys_printf_calls++;
	Bench486ConsoleOutputTrace (BCO_SYS_PRINTF);
}

void Bench486ConsoleOutputUpdateScreen (void)
{
	bench486_console_output_events.update_calls++;
	Bench486ConsoleOutputTrace (BCO_UPDATE_SCREEN);
	if (bench486_console_output_recurse_on_update)
	{
		bench486_console_output_recurse_on_update = 0;
		bench486_console_output_recursive_function (
				"%s", "recursive update message\n");
	}
}

static void Bench486ConsoleOutputReset (void)
{
	Q_memset (&bench486_console_output_events, 0,
			sizeof(bench486_console_output_events));
	bench486_console_output_recurse_on_update = 0;
	bench486_console_output_recursive_function = NULL;
}

static void Bench486ConPrintfSave (bench486_conprintf_saved_t *saved)
{
	Bench486ConPrintSave (&saved->console);
	saved->con_initialized_value = con_initialized;
	saved->con_debuglog_value = con_debuglog;
	saved->cls_state = cls.state;
	saved->cls_signon = cls.signon;
	saved->loading_disabled = scr_disabled_for_loading;
	Q_memcpy (saved->game_dir, com_gamedir, sizeof(saved->game_dir));
	saved->developer_value = developer.value;
	saved->inupdate_asm = con_printf_inupdate_asm486;
}

static void Bench486ConPrintfRestore (
		const bench486_conprintf_saved_t *saved)
{
	Bench486ConPrintRestore (&saved->console);
	con_initialized = saved->con_initialized_value;
	con_debuglog = saved->con_debuglog_value;
	cls.state = saved->cls_state;
	cls.signon = saved->cls_signon;
	scr_disabled_for_loading = saved->loading_disabled;
	Q_memcpy (com_gamedir, (void *)saved->game_dir,
			sizeof(saved->game_dir));
	developer.value = saved->developer_value;
	con_printf_inupdate_asm486 = saved->inupdate_asm;
	Bench486ConsoleOutputReset ();
}

static void Bench486ConPrintfInstall (
		const bench486_conprint_case_t *test_case, int initialized,
		int debuglog, int client_state, int signon, int loading_disabled,
		float developer_value)
{
	Bench486ConPrintInstall (test_case);
	con_initialized = initialized;
	con_debuglog = debuglog;
	cls.state = client_state;
	cls.signon = signon;
	scr_disabled_for_loading = loading_disabled;
	Q_memset (com_gamedir, 0, MAX_OSPATH);
	Q_memcpy (com_gamedir, bench486_conprintf_game_dir,
			sizeof(bench486_conprintf_game_dir));
	developer.value = developer_value;
	con_printf_inupdate_asm486 = 0;
	Bench486ConsoleOutputReset ();
}

static unsigned Bench486ConPrintfInvoke (void (*function)(void),
		const char *format)
{
	unsigned arguments[3];
	arguments[0] = (unsigned)format;
	arguments[1] = 17U;
	arguments[2] = (unsigned)bench486_conprintf_string;
	return Bench486Call_asm486 (function, 3, arguments, NULL);
}

static unsigned Bench486ConDPrintfInvoke (void (*function)(void))
{
	static char format[] = "developer %d/%s\n";
	unsigned arguments[3];
	arguments[0] = (unsigned)format;
	arguments[1] = 23U;
	arguments[2] = (unsigned)bench486_conprintf_string;
	return Bench486Call_asm486 (function, 3, arguments, NULL);
}

static void Bench486ConPrintfCapture (bench486_conprintf_result_t *result,
		int assembly, unsigned abi)
{
	Bench486ConPrintCapture (&result->console, assembly, abi);
	Q_memcpy (&result->events, &bench486_console_output_events,
			sizeof(result->events));
	result->abi = abi;
}

static int Bench486ConPrintfCheck (const char *name, int passed,
		unsigned abi_c, unsigned abi_asm)
{
	if (!passed || abi_c || abi_asm || bench486_conprintf_c_result.abi ||
			bench486_conprintf_asm_result.abi)
	{
		bench486_memory_failures++;
		Bench486Printf ("console output %s C/ASM parity FAIL ABI %x/%x events %u/%u writes %u/%u updates %u/%u\n",
				(char *)name, abi_c, abi_asm,
				bench486_conprintf_c_result.events.trace_count,
				bench486_conprintf_asm_result.events.trace_count,
				bench486_conprintf_c_result.events.write_calls,
				bench486_conprintf_asm_result.events.write_calls,
				bench486_conprintf_c_result.events.update_calls,
				bench486_conprintf_asm_result.events.update_calls);
		return 0;
	}
	return 1;
}

static void Bench486ConPrintfCase (const bench486_conprint_case_t *test_case,
		const char *name, int initialized, int debuglog, int client_state,
		int signon, int loading_disabled, int recurse)
{
	bench486_conprintf_saved_t saved;
	static char format[] = "formatted %d/%s\n";
	unsigned abi_c, abi_asm;
	int passed;
	Bench486ConPrintfSave (&saved);
	Bench486ConPrintfInstall (test_case, initialized, debuglog, client_state,
			signon, loading_disabled, 1.0f);
	if (recurse)
	{
		bench486_console_output_recursive_function =
				(void (*)(char *, ...))BCO_CON_PRINTF_C;
		bench486_console_output_recurse_on_update = 1;
	}
	abi_c = Bench486ConPrintfInvoke ((void (*)(void))BCO_CON_PRINTF_C,
			format);
	Bench486ConPrintfCapture (&bench486_conprintf_c_result, 0, abi_c);
	Bench486ConPrintfInstall (test_case, initialized, debuglog, client_state,
			signon, loading_disabled, 1.0f);
	if (recurse)
	{
		bench486_console_output_recursive_function =
				(void (*)(char *, ...))Con_Printf_asm486;
		bench486_console_output_recurse_on_update = 1;
	}
	abi_asm = Bench486ConPrintfInvoke ((void (*)(void))Con_Printf_asm486,
			format);
	Bench486ConPrintfCapture (&bench486_conprintf_asm_result, 1, abi_asm);
	passed = !Q_memcmp (&bench486_conprintf_c_result,
			&bench486_conprintf_asm_result,
			sizeof(bench486_conprintf_c_result)) &&
			!Q_strcmp (bench486_conprintf_asm_result.events.sys_text,
				recurse ? "recursive update message\n" :
					"formatted 17/console\n");
	if (debuglog)
		passed = passed && bench486_conprintf_asm_result.events.open_calls == 1 &&
				bench486_conprintf_asm_result.events.write_calls == 1 &&
				bench486_conprintf_asm_result.events.close_calls == 1 &&
				!Q_strcmp (bench486_conprintf_asm_result.events.log_file,
						"bench/qconsole.log") &&
				!Q_strcmp (bench486_conprintf_asm_result.events.log_data,
						"formatted 17/console\n") &&
				bench486_conprintf_asm_result.events.open_flags == co_open_flags &&
				bench486_conprintf_asm_result.events.open_mode == co_open_mode;
	if (!initialized || client_state == ca_dedicated)
		passed = passed && bench486_conprintf_asm_result.console.current ==
				test_case->current;
	if (recurse)
		passed = passed && bench486_conprintf_asm_result.events.sys_printf_calls == 2 &&
				bench486_conprintf_asm_result.events.update_calls == 1 &&
				!Q_strcmp (bench486_conprintf_asm_result.events.sys_text,
						"recursive update message\n");
	Bench486ConPrintfCheck (name, passed, abi_c, abi_asm);
	Bench486ConPrintfRestore (&saved);
}

static void Bench486ConDPrintfCase (const bench486_conprint_case_t *test_case,
		const char *name, float developer_value, int expected_calls)
{
	bench486_conprintf_saved_t saved;
	unsigned abi_c, abi_asm;
	int passed;
	Bench486ConPrintfSave (&saved);
	Bench486ConPrintfInstall (test_case, 1, 0, ca_disconnected, SIGNONS, 0,
			developer_value);
	abi_c = Bench486ConDPrintfInvoke ((void (*)(void))BCO_CON_DPRINTF_C);
	Bench486ConPrintfCapture (&bench486_conprintf_c_result, 0, abi_c);
	Bench486ConPrintfInstall (test_case, 1, 0, ca_disconnected, SIGNONS, 0,
			developer_value);
	abi_asm = Bench486ConDPrintfInvoke ((void (*)(void))Con_DPrintf_asm486);
	Bench486ConPrintfCapture (&bench486_conprintf_asm_result, 1, abi_asm);
	passed = !Q_memcmp (&bench486_conprintf_c_result,
			&bench486_conprintf_asm_result,
			sizeof(bench486_conprintf_c_result)) &&
			bench486_conprintf_asm_result.events.sys_printf_calls ==
					(unsigned)expected_calls;
	if (expected_calls)
		passed = passed && !Q_strcmp (
				bench486_conprintf_asm_result.events.sys_text,
					"developer 23/console\n");
	Bench486ConPrintfCheck (name, passed, abi_c, abi_asm);
	Bench486ConPrintfRestore (&saved);
}

static void Bench486ConDebugLogCase (void)
{
	static char format[] = "%s/%d/%x";
	bench486_conprintf_saved_t saved;
	unsigned args[5], abi_c, abi_asm;
	int passed;
	Bench486ConPrintfSave (&saved);
	Bench486ConsoleOutputReset ();
	args[0] = (unsigned)bench486_conprintf_log_file;
	args[1] = (unsigned)format;
	args[2] = (unsigned)"debug";
	args[3] = 93U;
	args[4] = 42U;
	abi_c = Bench486Call_asm486 ((void (*)(void))BCO_CON_DEBUGLOG_C,
			5, args, NULL);
	Q_memcpy (&bench486_conprintf_c_result.events,
			&bench486_console_output_events,
			sizeof(bench486_conprintf_c_result.events));
	bench486_conprintf_c_result.abi = abi_c;
	Bench486ConsoleOutputReset ();
	abi_asm = Bench486Call_asm486 ((void (*)(void))Con_DebugLog_asm486,
			5, args, NULL);
	Q_memcpy (&bench486_conprintf_asm_result.events,
			&bench486_console_output_events,
			sizeof(bench486_conprintf_asm_result.events));
	bench486_conprintf_asm_result.abi = abi_asm;
	passed = !Q_memcmp (&bench486_conprintf_c_result.events,
			&bench486_conprintf_asm_result.events,
			sizeof(bench486_conprintf_c_result.events)) &&
			!Q_strcmp (bench486_conprintf_asm_result.events.log_file,
					"bench-direct.log") &&
			!Q_strcmp (bench486_conprintf_asm_result.events.log_data,
					"debug/93/2a") &&
			bench486_conprintf_asm_result.events.open_flags == co_open_flags &&
			bench486_conprintf_asm_result.events.open_mode == co_open_mode;
	Bench486ConPrintfCheck ("Con_DebugLog-format-open-write-close", passed,
			abi_c, abi_asm);
	Bench486ConPrintfRestore (&saved);
}

static void Bench486ConPrintfCases (void)
{
	static const bench486_conprint_case_t test_case = {
		"console-output", "seed", NULL, 13, 8, 4, 3, 2, 19, 0, 12.5, 0
	};
	union { unsigned bits; float value; } nan_value;
	unsigned failures_before = bench486_memory_failures;
	bench486_conprintf_saved_t saved;
	Bench486ConPrintfSave (&saved);
	Bench486Printf ("Con_Printf/Con_DPrintf/Con_DebugLog C/ASM parity begin\n");
	Bench486ConDebugLogCase ();
	Bench486ConPrintfCase (&test_case, "formatted active signed-on", 1, 0,
			ca_disconnected, SIGNONS, 0, 0);
	Bench486ConPrintfCase (&test_case, "debug-log and screen update", 1, 1,
			ca_disconnected, SIGNONS - 1, 0, 0);
	Bench486ConPrintfCase (&test_case, "loading update suppressed", 1, 0,
			ca_disconnected, SIGNONS - 1, 1, 0);
	Bench486ConPrintfCase (&test_case, "dedicated early return", 1, 0,
			ca_dedicated, SIGNONS - 1, 0, 0);
	Bench486ConPrintfCase (&test_case, "not initialized early return", 0, 0,
			ca_disconnected, SIGNONS - 1, 0, 0);
	Bench486ConPrintfCase (&test_case, "screen update recursion guard", 1, 0,
			ca_disconnected, SIGNONS - 1, 0, 1);
	Bench486ConDPrintfCase (&test_case, "developer disabled", 0.0f, 0);
	Bench486ConDPrintfCase (&test_case, "developer enabled", 1.0f, 1);
	nan_value.bits = 0x7fc00000U;
	Bench486ConDPrintfCase (&test_case, "developer unordered", nan_value.value, 0);
	Bench486ConPrintfRestore (&saved);
	if (bench486_memory_failures == failures_before)
		Bench486Printf ("Con_Printf/Con_DPrintf/Con_DebugLog formatting, logging, control-flow, recursion, x87 and ABI parity PASS\n");
	else
		Bench486Printf ("Con_Printf/Con_DPrintf/Con_DebugLog exact parity FAIL\n");
}

#undef BCO_CAPTURE_FD
#undef BCO_TRACE_CAPACITY

#undef BCO_CON_DPRINTF_C
#undef BCO_CON_PRINTF_C
#undef BCO_CON_DEBUGLOG_C

#endif

#endif
