/* Layout contract for screen.c:SCR_DrawNet. */
#ifndef ASM_SCREEN_NET_H
#define ASM_SCREEN_NET_H

#define SN_CL_LAST_RECEIVED_MESSAGE 588
#define SN_CLS_DEMOPLAYBACK 2252
#define SN_VRECT_X 0
#define SN_VRECT_Y 4
#define SN_VRECT_SIZE 20

#ifndef __ASSEMBLER__
#include <stddef.h>

typedef char sn_cl_last_received_message_must_match[
		(offsetof(client_state_t, last_received_message) ==
		SN_CL_LAST_RECEIVED_MESSAGE) ? 1 : -1];
typedef char sn_cls_demoplayback_must_match[
		(offsetof(client_static_t, demoplayback) == SN_CLS_DEMOPLAYBACK) ? 1 : -1];
typedef char sn_vrect_x_must_match[
		(offsetof(vrect_t, x) == SN_VRECT_X) ? 1 : -1];
typedef char sn_vrect_y_must_match[
		(offsetof(vrect_t, y) == SN_VRECT_Y) ? 1 : -1];
typedef char sn_vrect_size_must_match[
		(sizeof(vrect_t) == SN_VRECT_SIZE) ? 1 : -1];

#ifdef ASM486_SCREEN_NET
void SCR_DrawNet_asm486 (void);
#ifdef BENCH486
void SCR_DrawNet_Screen_C (void);
extern int bench486_screen_net_fixture_active;
void Bench486ScreenNetRecordDrawPic (int x, int y, qpic_t *pic);
void Bench486ScreenNetCases (void);
#endif
#endif

#endif

#endif /* ASM_SCREEN_NET_H */
