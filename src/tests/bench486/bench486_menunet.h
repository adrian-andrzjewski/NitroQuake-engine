/* C/assembly parity for network menu asset selection and help text. */
#ifndef BENCH486_MENUNET_H
#define BENCH486_MENUNET_H

#if defined(BENCH486) && defined(ASM486_SCREEN_OVERLAYS)

#include "client/asm_menutext.h"

#define BNM_PATH_QLAQUE 10
#define BNM_PATH_DOT_FIRST 15
#define BNM_PATH_MULTI_TITLE 29
#define BNM_PATH_NETMEN1 31
#define BNM_PATH_NETMEN2 32
#define BNM_PATH_NETMEN3 33
#define BNM_PATH_NETMEN4 34
#define BNM_PATH_NETMEN5 35
#define BNM_PATH_DIM_MODEM 36
#define BNM_PATH_DIM_DIRECT 37
#define BNM_PATH_DIM_IPX 38
#define BNM_PATH_DIM_TCPIP 39
#define BNM_EVENT_TRANSPIC 1
#define BNM_EVENT_PIC 2
#define BNM_EVENT_CACHEPIC 4
#define BNM_TEXTBOX_EVENTS 138
#define BNM_FRAMES 6
#define BNM_PICTURE_GUARD_WORDS 2
#define BNM_TEXT_GUARD_WORDS 2

static const int bench486_menu_net_states[][3] =
{
	{ 0, 0, 0 }, { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 },
	{ 1, 1, 0 }, { 1, 0, 1 }, { 0, 1, 1 }, { 1, 1, 1 }
};

static bench486_menu_picture_result_t bench486_menu_net_picture_reference;
static bench486_menu_picture_result_t bench486_menu_net_picture_candidate;
static bench486_menu_text_result_t bench486_menu_net_text_reference;
static bench486_menu_text_result_t bench486_menu_net_text_candidate;

static qpic_t *Bench486MenuNetFakePicture (unsigned path)
{
	return (qpic_t *)(bench486_menu_picture_fake_pic + path * 4U);
}

static unsigned Bench486MenuNetExpectEvent (
		const bench486_menu_picture_result_t *result, unsigned index,
		int kind, int x, int y, unsigned path)
{
	const bench486_menu_picture_event_t *event;
	if (index >= result->trace.count)
		return 0x4d4e0010U + index;
	event = &result->trace.events[index];
	if (event->kind != kind || event->x != x || event->y != y ||
			event->pic != Bench486MenuNetFakePicture (path) ||
			event->translation != NULL)
		return 0x4d4e0020U + index;
	return 0;
}

static unsigned Bench486MenuNetExpectedPicture (unsigned video_width,
		int cursor, int menu_items, int serial, int ipx, int tcpip,
		unsigned dot_frame, const bench486_menu_picture_result_t *result)
{
	static const unsigned active_paths[4] =
		{ BNM_PATH_NETMEN1, BNM_PATH_NETMEN2,
			BNM_PATH_NETMEN3, BNM_PATH_NETMEN4 };
	static const unsigned dim_paths[4] =
		{ BNM_PATH_DIM_MODEM, BNM_PATH_DIM_DIRECT,
			BNM_PATH_DIM_IPX, BNM_PATH_DIM_TCPIP };
	unsigned enabled[4];
	unsigned viewport_offset = (video_width - 320U) >> 1;
	unsigned title_width =
			bench486_menu_picture_fake_pic[BNM_PATH_MULTI_TITLE * 4U];
	unsigned icon_rows = menu_items == 5 ? 5U : 4U;
	unsigned event_index = 4;
	unsigned dot_path = BNM_PATH_DOT_FIRST + dot_frame - 1U;
	int title_x = (320 - (int)title_width) / 2;
	unsigned row, i;
	unsigned failure = 0;
	bench486_menu_picture_result_t textbox_result;
	bench486_menu_textbox_case_t textbox_case;

	enabled[0] = serial != 0;
	enabled[1] = serial != 0;
	enabled[2] = ipx != 0;
	enabled[3] = tcpip != 0;
	if (result->trace.overflow || result->trace.cache_error)
		return 0x4d4e0001U;
	failure |= Bench486MenuNetExpectEvent (result, 0,
			BNM_EVENT_CACHEPIC, 0, 0, BNM_PATH_QLAQUE);
	failure |= Bench486MenuNetExpectEvent (result, 1,
			BNM_EVENT_TRANSPIC, (int)(viewport_offset + 16U), 4,
			BNM_PATH_QLAQUE);
	failure |= Bench486MenuNetExpectEvent (result, 2,
			BNM_EVENT_CACHEPIC, 0, 0, BNM_PATH_MULTI_TITLE);
	failure |= Bench486MenuNetExpectEvent (result, 3,
			BNM_EVENT_PIC,
			(int)(viewport_offset + (unsigned)title_x), 4,
			BNM_PATH_MULTI_TITLE);
	for (row = 0; row < 4; row++)
	{
		unsigned path = enabled[row] ? active_paths[row] : dim_paths[row];
		failure |= Bench486MenuNetExpectEvent (result, event_index++,
				BNM_EVENT_CACHEPIC, 0, 0, path);
		failure |= Bench486MenuNetExpectEvent (result, event_index++,
				BNM_EVENT_TRANSPIC, (int)(viewport_offset + 72U),
				32 + (int)(row * 19U), path);
	}
	if (menu_items == 5)
	{
		failure |= Bench486MenuNetExpectEvent (result, event_index++,
				BNM_EVENT_CACHEPIC, 0, 0, BNM_PATH_NETMEN5);
		failure |= Bench486MenuNetExpectEvent (result, event_index++,
				BNM_EVENT_TRANSPIC, (int)(viewport_offset + 72U), 108,
				BNM_PATH_NETMEN5);
	}
	if (result->trace.count != event_index + BNM_TEXTBOX_EVENTS + 2U)
		return failure | 0x4d4e0002U;

	Q_memset (&textbox_result, 0, sizeof(textbox_result));
	textbox_result.trace.count = BNM_TEXTBOX_EVENTS;
	for (i = 0; i < BNM_PICTURE_GUARD_WORDS; i++)
	{
		textbox_result.trace.before[i] = result->trace.before[i];
		textbox_result.trace.after[i] = result->trace.after[i];
	}
	Q_memcpy (textbox_result.trace.events,
			(void *)&result->trace.events[event_index],
			BNM_TEXTBOX_EVENTS * sizeof(result->trace.events[0]));
	textbox_case.name = "net-menu-help-box";
	textbox_case.video_width = video_width;
	textbox_case.x = 56;
	textbox_case.y = 134;
	textbox_case.width = 24;
	textbox_case.lines = 4;
	failure |= Bench486MenuTextBoxExpected (&textbox_case, &textbox_result);
	event_index += BNM_TEXTBOX_EVENTS;
	failure |= Bench486MenuNetExpectEvent (result, event_index++,
			BNM_EVENT_CACHEPIC, 0, 0, dot_path);
	failure |= Bench486MenuNetExpectEvent (result, event_index,
			BNM_EVENT_TRANSPIC, (int)(viewport_offset + 54U),
			32 + cursor * 20, dot_path);
	for (i = 0; i < BNM_PICTURE_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d500000U + i ||
				result->trace.after[i] != 0x4d50f000U + i)
			failure |= 0x4d4e0040U + i;
	return failure;
}

static unsigned Bench486MenuNetExpectedText (unsigned video_width,
		int cursor, const bench486_menu_text_result_t *result)
{
	unsigned viewport_offset = (video_width - 320U) >> 1;
	unsigned glyph = 0, line, i;
	unsigned failure = 0;

	if (result->trace.overflow)
		return 0x4d4e0050U;
	for (line = 0; line < 4; line++)
	{
		const char *message = net_helpMessage[cursor * 4 + (int)line];
		for (i = 0; message[i]; i++)
		{
			if (glyph >= sizeof(result->trace.glyphs) /
					sizeof(result->trace.glyphs[0]) ||
					result->trace.glyphs[glyph].x !=
							(int)(viewport_offset + 64U + i * 8U) ||
					result->trace.glyphs[glyph].y !=
							142 + (int)(line * 8U) ||
					result->trace.glyphs[glyph].num !=
							(int)(char)message[i] + 128)
				failure |= 0x4d4e0060U + (glyph & 0xfU);
			glyph++;
		}
	}
	if (result->trace.count != glyph)
		failure |= 0x4d4e0070U;
	for (i = 0; i < BNM_TEXT_GUARD_WORDS; i++)
		if (result->trace.before[i] != 0x4d540000U + i ||
				result->trace.after[i] != 0x4d54f000U + i)
			failure |= 0x4d4e0080U + i;
	return failure;
}

static unsigned Bench486MenuNetRun (unsigned video_width, int cursor,
		int menu_items, int serial, int ipx, int tcpip, double host_time_value,
		unsigned short control_word, void (*function)(void),
		bench486_menu_picture_result_t *picture_result,
		bench486_menu_text_result_t *text_result)
{
	unsigned abi;
	unsigned short cw_before, cw_after;
	unsigned saved_width = vid.width;
	int saved_cursor = m_net_cursor;
	int saved_items = m_net_items;
	double saved_host_time = host_time;
	qboolean saved_serial = serialAvailable;
	qboolean saved_ipx = ipxAvailable;
	qboolean saved_tcpip = tcpipAvailable;
	unsigned failure = 0;

	vid.width = video_width;
	m_net_cursor = cursor;
	m_net_items = menu_items;
	host_time = host_time_value;
	serialAvailable = serial;
	ipxAvailable = ipx;
	tcpipAvailable = tcpip;
	__asm__ __volatile__ ("fldcw %0" : : "m" (control_word));
	Bench486MenuPictureInitTrace ();
	Bench486MenuTextInitTrace ();
	cw_before = Bench486MenuTextGetControlWord ();
	bench486_menu_text_trace_active = 1;
	abi = Bench486Call_asm486 (function, 0, NULL, NULL);
	bench486_menu_text_trace_active = 0;
	cw_after = Bench486MenuTextGetControlWord ();
	Bench486MenuPictureCapture (picture_result, abi, cw_before, cw_after);
	Bench486MenuTextCapture (text_result, abi, cw_before, cw_after);
	if ((abi & 0x20U) || cw_before != cw_after)
		failure |= 0x4d4e0090U;
	if (vid.width != video_width || m_net_cursor != cursor ||
			m_net_items != menu_items || host_time != host_time_value ||
			serialAvailable != serial || ipxAvailable != ipx ||
			tcpipAvailable != tcpip)
		failure |= 0x4d4e0091U;
	vid.width = saved_width;
	m_net_cursor = saved_cursor;
	m_net_items = saved_items;
	host_time = saved_host_time;
	serialAvailable = saved_serial;
	ipxAvailable = saved_ipx;
	tcpipAvailable = saved_tcpip;
	return failure;
}

static unsigned Bench486MenuNetCase (unsigned video_width, int cursor,
		int menu_items, int serial, int ipx, int tcpip, double host_time_value,
		unsigned frame, unsigned short control_word)
{
	unsigned failure = 0;
	failure |= Bench486MenuNetRun (video_width, cursor, menu_items,
			serial, ipx, tcpip, host_time_value, control_word,
			M_Net_Draw_C, &bench486_menu_net_picture_reference,
			&bench486_menu_net_text_reference);
	failure |= Bench486MenuNetRun (video_width, cursor, menu_items,
			serial, ipx, tcpip, host_time_value, control_word,
			M_Net_Draw, &bench486_menu_net_picture_candidate,
			&bench486_menu_net_text_candidate);
	failure |= Bench486MenuNetExpectedPicture (video_width, cursor,
			menu_items, serial, ipx, tcpip, frame,
			&bench486_menu_net_picture_reference);
	failure |= Bench486MenuNetExpectedPicture (video_width, cursor,
			menu_items, serial, ipx, tcpip, frame,
			&bench486_menu_net_picture_candidate);
	failure |= Bench486MenuNetExpectedText (video_width, cursor,
			&bench486_menu_net_text_reference);
	failure |= Bench486MenuNetExpectedText (video_width, cursor,
			&bench486_menu_net_text_candidate);
	failure |= Bench486MenuPictureDifference (
			&bench486_menu_net_picture_reference,
			&bench486_menu_net_picture_candidate);
	failure |= Bench486MenuTextDifference (&bench486_menu_net_text_reference,
			&bench486_menu_net_text_candidate);
	return failure;
}

void Bench486MenuNetCases (void)
{
	static const unsigned full_profile_states[2] = { 0, 7 };
	unsigned state, items_index, cursor, precision, rounding, frame, width;
	unsigned cases = 0, failure = 0;
	unsigned widths = sizeof (bench486_menu_page_widths) /
			sizeof (bench486_menu_page_widths[0]);
	unsigned precisions = sizeof (bench486_menu_page_precisions) /
			sizeof (bench486_menu_page_precisions[0]);
	unsigned states = sizeof (bench486_menu_net_states) /
			sizeof (bench486_menu_net_states[0]);
	unsigned short original_cw = Bench486MenuTextGetControlWord ();
	unsigned saved_width = vid.width;
	unsigned saved_title_width =
			bench486_menu_picture_fake_pic[BNM_PATH_MULTI_TITLE * 4U];
	int saved_cursor = m_net_cursor;
	int saved_items = m_net_items;
	double saved_host_time = host_time;
	qboolean saved_serial = serialAvailable;
	qboolean saved_ipx = ipxAvailable;
	qboolean saved_tcpip = tcpipAvailable;

	bench486_menu_picture_fake_pic[BNM_PATH_MULTI_TITLE * 4U] = 95;
	for (state = 0; state < states && !failure; state++)
	{
		unsigned precision_index = state % precisions;
		unsigned control_rounding = state % 4U;
		unsigned short control_word = Bench486MenuPageControlWord (
				original_cw,
				bench486_menu_page_precisions[precision_index],
				control_rounding);
		failure = Bench486MenuNetCase (
				bench486_menu_page_widths[state % widths],
				(int)(state % 4U), state & 1U ? 5 : 4,
				bench486_menu_net_states[state][0],
				bench486_menu_net_states[state][1],
				bench486_menu_net_states[state][2],
				bench486_menu_page_times[state % BNM_FRAMES],
				state % BNM_FRAMES + 1U, control_word);
		cases++;
		if (failure)
			break;
	}
	for (state = 0; state < 2 && !failure; state++)
		for (items_index = 0; items_index < 2 && !failure; items_index++)
			for (cursor = 0; cursor < 4 && !failure; cursor++)
				for (precision = 0; precision < precisions && !failure;
						precision++)
					for (rounding = 0; rounding < 4 && !failure; rounding++)
						for (frame = 0;
								frame < BNM_FRAMES && !failure; frame++)
							for (width = 0; width < widths; width++)
							{
								unsigned short control_word =
										Bench486MenuPageControlWord (
											original_cw,
											bench486_menu_page_precisions[
													precision], rounding);
								unsigned net_state = full_profile_states[state];
								failure = Bench486MenuNetCase (
										bench486_menu_page_widths[
											(width + frame + cursor) % widths],
										(int)cursor, items_index ? 5 : 4,
										bench486_menu_net_states[net_state][0],
										bench486_menu_net_states[net_state][1],
										bench486_menu_net_states[net_state][2],
										bench486_menu_page_times[frame],
										frame + 1U, control_word);
								cases++;
								if (failure)
								{
									Bench486Printf (
											"net menu C/assembly FAIL state %u items %u cursor %u precision %u rounding %u frame %u width %u code %08x\n",
											state, items_index ? 5 : 4, cursor,
											bench486_menu_page_precisions[
													precision], rounding, frame + 1U,
											bench486_menu_page_widths[
													(width + frame + cursor) % widths],
											failure);
									break;
								}
							}
	bench486_menu_text_trace_active = 0;
	vid.width = saved_width;
	m_net_cursor = saved_cursor;
	m_net_items = saved_items;
	host_time = saved_host_time;
	serialAvailable = saved_serial;
	ipxAvailable = saved_ipx;
	tcpipAvailable = saved_tcpip;
	bench486_menu_picture_fake_pic[BNM_PATH_MULTI_TITLE * 4U] =
			saved_title_width;
	__asm__ __volatile__ ("fldcw %0" : : "m" (original_cw));
	if (failure)
		bench486_memory_failures++;
	else
		Bench486Printf (
				"net menu: %u exact C/assembly protocol, help text, textbox, animation, and x87 cases PASS\n",
				cases);
}

#undef BNM_TEXTBOX_EVENTS
#undef BNM_TEXT_GUARD_WORDS
#undef BNM_PICTURE_GUARD_WORDS
#undef BNM_FRAMES
#undef BNM_EVENT_CACHEPIC
#undef BNM_EVENT_PIC
#undef BNM_EVENT_TRANSPIC
#undef BNM_PATH_DIM_TCPIP
#undef BNM_PATH_DIM_IPX
#undef BNM_PATH_DIM_DIRECT
#undef BNM_PATH_DIM_MODEM
#undef BNM_PATH_NETMEN5
#undef BNM_PATH_NETMEN4
#undef BNM_PATH_NETMEN3
#undef BNM_PATH_NETMEN2
#undef BNM_PATH_NETMEN1
#undef BNM_PATH_MULTI_TITLE
#undef BNM_PATH_DOT_FIRST
#undef BNM_PATH_QLAQUE

#endif

#endif
