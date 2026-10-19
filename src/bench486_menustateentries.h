/* C/assembly parity for renderer-reachable menu state entry points. */
#ifndef BENCH486_MENU_STATE_ENTRIES_H
#define BENCH486_MENU_STATE_ENTRIES_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "asm_menutext.h"

#define BMSE_MULTI_CURSOR_COUNT 4U
#define BMSE_NET_CURSOR_COUNT 4U
#define BMSE_LAN_CURSOR_COUNT 5U
#define BMSE_PORT_COUNT 8U

extern unsigned Bench486Call_asm486 (void (*function)(void), unsigned words,
		const unsigned *arguments, float *float_return);
extern void M_Menu_LanConfig_f (void);
extern void M_Menu_ServerList_f (void);
extern void M_Menu_LanConfig_f_C (void);
extern void M_Menu_ServerList_f_C (void);

extern keydest_t key_dest;
extern int m_state;
extern qboolean m_entersound;
extern qboolean m_return_onerror;
extern char m_return_reason[32];
extern int m_multiplayer_cursor;
extern int m_net_cursor;
extern int lanConfig_cursor;
extern int lanConfig_port;
extern char lanConfig_portname[6];
extern char lanConfig_joinname[22];
extern int slist_cursor;
extern qboolean slist_sorted;
extern int DEFAULTnet_hostport;

typedef struct bench486_menu_state_entry_case_s
{
	int multiplayer_cursor;
	int net_cursor;
	int lan_cursor;
	int default_port;
	unsigned seed;
} bench486_menu_state_entry_case_t;

typedef struct bench486_menu_state_entry_result_s
{
	int destination;
	int state;
	int entersound;
	int return_onerror;
	int multiplayer_cursor;
	int net_cursor;
	int lan_cursor;
	int lan_port;
	char lan_portname[6];
	char lan_joinname[22];
	int server_cursor;
	int server_sorted;
	char return_reason[32];
	int default_port;
	unsigned abi;
	unsigned short cw_before;
	unsigned short cw_after;
} bench486_menu_state_entry_result_t;

static const int bench486_menu_state_entry_multi_cursors[
		BMSE_MULTI_CURSOR_COUNT] = { 0, 1, 2, -1 };
static const int bench486_menu_state_entry_net_cursors[
		BMSE_NET_CURSOR_COUNT] = { 0, 1, 3, 4 };
static const int bench486_menu_state_entry_lan_cursors[
		BMSE_LAN_CURSOR_COUNT] = { -1, 0, 1, 2, 7 };
static const int bench486_menu_state_entry_ports[BMSE_PORT_COUNT] =
		{ 0, 1, 9, 10, 999, 1000, 26000, 65535 };

static bench486_menu_state_entry_result_t
		bench486_menu_state_entry_saved;
static bench486_menu_state_entry_result_t
		bench486_menu_state_entry_reference;
static bench486_menu_state_entry_result_t
		bench486_menu_state_entry_candidate;

static unsigned short Bench486MenuStateEntryControlWord (void)
{
	unsigned short control_word;
	__asm__ __volatile__ ("fnstcw %0" : "=m" (control_word));
	return control_word;
}

static void Bench486MenuStateEntrySeedArrays (unsigned seed,
		char *portname, char *joinname, char *reason)
{
	unsigned i;
	for (i = 0; i < 6U; i++)
		portname[i] = (char)(0xa0U + i + (seed & 0x1fU));
	for (i = 0; i < 22U; i++)
		joinname[i] = (char)(0x51U + i + seed);
	for (i = 0; i < 32U; i++)
		reason[i] = (char)(0x80U + ((seed + i) % 0x7fU));
}

static void Bench486MenuStateEntryPrepare (
		const bench486_menu_state_entry_case_t *test_case)
{
	key_dest = (keydest_t)((int)(test_case->seed % 7U) - 2);
	m_state = (int)(test_case->seed % (MD_STATE_LAST + 1U));
	m_entersound = (qboolean)((test_case->seed >> 1) & 1U);
	m_return_onerror = (qboolean)((test_case->seed >> 2) & 1U);
	m_multiplayer_cursor = test_case->multiplayer_cursor;
	m_net_cursor = test_case->net_cursor;
	lanConfig_cursor = test_case->lan_cursor;
	lanConfig_port = (int)(0x12340000U ^ test_case->seed);
	slist_cursor = (int)(test_case->seed % 15U) - 7;
	slist_sorted = (qboolean)(test_case->seed & 1U);
	DEFAULTnet_hostport = test_case->default_port;
	Bench486MenuStateEntrySeedArrays (test_case->seed, lanConfig_portname,
			lanConfig_joinname, m_return_reason);
}

static void Bench486MenuStateEntryCapture (
		bench486_menu_state_entry_result_t *result, unsigned abi,
		unsigned short cw_before, unsigned short cw_after)
{
	Q_memset (result, 0, sizeof(*result));
	result->destination = key_dest;
	result->state = m_state;
	result->entersound = m_entersound;
	result->return_onerror = m_return_onerror;
	result->multiplayer_cursor = m_multiplayer_cursor;
	result->net_cursor = m_net_cursor;
	result->lan_cursor = lanConfig_cursor;
	result->lan_port = lanConfig_port;
	Q_memcpy (result->lan_portname, lanConfig_portname,
			sizeof(result->lan_portname));
	Q_memcpy (result->lan_joinname, lanConfig_joinname,
			sizeof(result->lan_joinname));
	result->server_cursor = slist_cursor;
	result->server_sorted = slist_sorted;
	Q_memcpy (result->return_reason, m_return_reason,
			sizeof(result->return_reason));
	result->default_port = DEFAULTnet_hostport;
	result->abi = abi;
	result->cw_before = cw_before;
	result->cw_after = cw_after;
}

static unsigned Bench486MenuStateEntryRun (
		const bench486_menu_state_entry_case_t *test_case,
		void (*function)(void), bench486_menu_state_entry_result_t *result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;

	Bench486MenuStateEntryPrepare (test_case);
	cw_before = Bench486MenuStateEntryControlWord ();
	abi = Bench486Call_asm486 (function, 0U, NULL, NULL);
	cw_after = Bench486MenuStateEntryControlWord ();
	Bench486MenuStateEntryCapture (result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		return 0x4d534501U;
	return 0;
}

static unsigned Bench486MenuStateEntryExpected (
		const bench486_menu_state_entry_case_t *test_case,
		const bench486_menu_state_entry_result_t *result, unsigned lan_entry)
{
	char expected_portname[6];
	char expected_joinname[22];
	char expected_reason[32];
	int expected_lan_cursor = test_case->lan_cursor;
	int expected_lan_port = (int)(0x12340000U ^ test_case->seed);
	int expected_server_cursor = (int)(test_case->seed % 15U) - 7;
	int expected_server_sorted = (int)(test_case->seed & 1U);
	unsigned i;

	Bench486MenuStateEntrySeedArrays (test_case->seed, expected_portname,
			expected_joinname, expected_reason);
	if (lan_entry)
	{
		if (expected_lan_cursor == -1)
			expected_lan_cursor =
					test_case->multiplayer_cursor == 0 &&
					test_case->net_cursor == 3 ? 2 : 1;
		if (test_case->multiplayer_cursor == 1 &&
				expected_lan_cursor == 2)
			expected_lan_cursor = 1;
		sprintf (expected_portname, "%u",
				(unsigned)test_case->default_port);
		expected_lan_port = test_case->default_port;
	}
	expected_reason[0] = 0;
	if (!lan_entry)
	{
		expected_server_cursor = 0;
		expected_server_sorted = 0;
	}
	for (i = 0; i < 32U; i++)
	{
		if (result->return_reason[i] != expected_reason[i])
			return 0x4d534510U;
	}
	if (result->destination != MD_KEY_MENU ||
			result->state != (int)(lan_entry ? MD_STATE_LANCONFIG :
					MD_STATE_SERVERLIST) ||
			result->entersound != 1 || result->return_onerror != 0 ||
			result->multiplayer_cursor != test_case->multiplayer_cursor ||
			result->net_cursor != test_case->net_cursor ||
			result->lan_cursor != (lan_entry ? expected_lan_cursor :
					test_case->lan_cursor) ||
			result->lan_port != expected_lan_port ||
			Q_memcmp ((void *)result->lan_portname,
					(void *)expected_portname,
					sizeof(expected_portname)) ||
			Q_memcmp ((void *)result->lan_joinname,
					(void *)expected_joinname,
					sizeof(expected_joinname)) ||
			result->server_cursor != expected_server_cursor ||
			result->server_sorted != expected_server_sorted ||
			result->default_port != test_case->default_port)
		return 0x4d534520U;
	return 0;
}

static unsigned Bench486MenuStateEntryDifference (
		const bench486_menu_state_entry_result_t *reference,
		const bench486_menu_state_entry_result_t *candidate)
{
	return Q_memcmp ((void *)reference, (void *)candidate,
			sizeof(*reference)) ? 0x4d534530U : 0;
}

static unsigned Bench486MenuStateEntryBoundedPort (int port,
		unsigned seed, const char *expected_text)
{
	bench486_menu_state_entry_case_t test_case;
	bench486_menu_state_entry_result_t result;
	char expected_joinname[22];
	char unused_portname[6];
	char unused_reason[32];
	unsigned error;

	test_case.multiplayer_cursor = 0;
	test_case.net_cursor = 3;
	test_case.lan_cursor = 0;
	test_case.default_port = port;
	test_case.seed = seed;
	error = Bench486MenuStateEntryRun (&test_case,
			M_Menu_LanConfig_f, &result);
	Bench486MenuStateEntrySeedArrays (seed, unused_portname,
			expected_joinname, unused_reason);
	if (error || result.lan_port != port ||
			Q_memcmp ((void *)result.lan_portname, (void *)expected_text, 6U) ||
			Q_memcmp ((void *)result.lan_joinname,
					(void *)expected_joinname, sizeof(expected_joinname)))
		return 0x4d534540U | error;
	return 0;
}

static void Bench486MenuStateEntrySaveState (void)
{
	Bench486MenuStateEntryCapture (&bench486_menu_state_entry_saved, 0U,
			Bench486MenuStateEntryControlWord (),
			Bench486MenuStateEntryControlWord ());
}

static void Bench486MenuStateEntryRestoreState (void)
{
	const bench486_menu_state_entry_result_t *saved =
			&bench486_menu_state_entry_saved;
	key_dest = (keydest_t)saved->destination;
	m_state = saved->state;
	m_entersound = (qboolean)saved->entersound;
	m_return_onerror = (qboolean)saved->return_onerror;
	m_multiplayer_cursor = saved->multiplayer_cursor;
	m_net_cursor = saved->net_cursor;
	lanConfig_cursor = saved->lan_cursor;
	lanConfig_port = saved->lan_port;
	Q_memcpy (lanConfig_portname, (void *)saved->lan_portname,
			sizeof(lanConfig_portname));
	Q_memcpy (lanConfig_joinname, (void *)saved->lan_joinname,
			sizeof(lanConfig_joinname));
	slist_cursor = saved->server_cursor;
	slist_sorted = (qboolean)saved->server_sorted;
	Q_memcpy (m_return_reason, (void *)saved->return_reason,
			sizeof(m_return_reason));
	DEFAULTnet_hostport = saved->default_port;
	__asm__ __volatile__ ("fldcw %0" : : "m" (saved->cw_before));
}

void Bench486MenuStateEntryCases (void)
{
	bench486_menu_state_entry_case_t test_case;
	unsigned multi_index, net_index, lan_index, port_index;
	unsigned total = 0, failure = 0;

	Bench486MenuStateEntrySaveState ();
	for (multi_index = 0; multi_index < BMSE_MULTI_CURSOR_COUNT && !failure;
			multi_index++)
	for (net_index = 0; net_index < BMSE_NET_CURSOR_COUNT && !failure;
			net_index++)
	for (lan_index = 0; lan_index < BMSE_LAN_CURSOR_COUNT && !failure;
			lan_index++)
	for (port_index = 0; port_index < BMSE_PORT_COUNT && !failure;
			port_index++)
	{
		unsigned entry;
		test_case.multiplayer_cursor =
				bench486_menu_state_entry_multi_cursors[multi_index];
		test_case.net_cursor =
				bench486_menu_state_entry_net_cursors[net_index];
		test_case.lan_cursor =
				bench486_menu_state_entry_lan_cursors[lan_index];
		test_case.default_port =
				bench486_menu_state_entry_ports[port_index];
		test_case.seed = multi_index *
				(BMSE_NET_CURSOR_COUNT * BMSE_LAN_CURSOR_COUNT *
				 BMSE_PORT_COUNT) +
				net_index * (BMSE_LAN_CURSOR_COUNT * BMSE_PORT_COUNT) +
				lan_index * BMSE_PORT_COUNT + port_index;
		for (entry = 0; entry < 2U && !failure; entry++)
		{
			void (*reference_function)(void) = entry ?
					M_Menu_ServerList_f_C : M_Menu_LanConfig_f_C;
			void (*candidate_function)(void) = entry ?
					M_Menu_ServerList_f : M_Menu_LanConfig_f;
			unsigned reference_error, candidate_error;
			unsigned reference_expected, candidate_expected;

			reference_error = Bench486MenuStateEntryRun (&test_case,
					reference_function, &bench486_menu_state_entry_reference);
			candidate_error = Bench486MenuStateEntryRun (&test_case,
					candidate_function, &bench486_menu_state_entry_candidate);
			reference_expected = Bench486MenuStateEntryExpected (&test_case,
					&bench486_menu_state_entry_reference, !entry);
			candidate_expected = Bench486MenuStateEntryExpected (&test_case,
					&bench486_menu_state_entry_candidate, !entry);
			failure = reference_error | candidate_error |
					reference_expected | candidate_expected |
					Bench486MenuStateEntryDifference (
							&bench486_menu_state_entry_reference,
							&bench486_menu_state_entry_candidate);
			total++;
			if (failure)
				Bench486Printf ("menu state-entry FAIL function %u multi %d net %d lan %d port %d seed %u code %08x reference %08x candidate %08x\n",
						entry, test_case.multiplayer_cursor,
						test_case.net_cursor, test_case.lan_cursor,
						test_case.default_port, test_case.seed, failure,
						reference_expected | reference_error,
						candidate_expected | candidate_error);
		}
	}
	if (!failure)
		failure = Bench486MenuStateEntryBoundedPort (-1, 700U, "42949") |
				Bench486MenuStateEntryBoundedPort (1000000000, 701U, "10000");
	Bench486MenuStateEntryRestoreState ();
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf ("menu state entry points: %u exact C/assembly LAN/server-list state and ABI cases plus 2 bounded port cases PASS\n",
				total);
}

#endif

#endif
