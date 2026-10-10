/* Assembly-visible layout contracts for V_ParseDamage. */
#ifndef ASM_VDAMAGE_H
#define ASM_VDAMAGE_H

#define VDP_CLIENT_FACEANIMTIME       288
#define VDP_CLIENT_CSHIFTS            292
#define VDP_CLIENT_TIME               572
#define VDP_CLIENT_VIEWENTITY         2680
#define VDP_ENTITY_SIZE               180
#define VDP_ENTITY_ORIGIN             84
#define VDP_ENTITY_ANGLES             120
#define VDP_CSHIFT_DAMAGE             1
#define VDP_CSHIFT_SIZE               16
#define VDP_CSHIFT_DESTCOLOR          0
#define VDP_CSHIFT_PERCENT            12
#define VDP_CVAR_VALUE                16

#define VDP_CLIENT_DAMAGE_SHIFT \
		(VDP_CLIENT_CSHIFTS + VDP_CSHIFT_DAMAGE * VDP_CSHIFT_SIZE)
#define VDP_CLIENT_DAMAGE_COLOR \
		(VDP_CLIENT_DAMAGE_SHIFT + VDP_CSHIFT_DESTCOLOR)
#define VDP_CLIENT_DAMAGE_PERCENT \
		(VDP_CLIENT_DAMAGE_SHIFT + VDP_CSHIFT_PERCENT)

#ifndef __ASSEMBLER__
#include <stddef.h>
typedef char vdp_client_state_size[(sizeof(client_state_t) == 2900U) ? 1 : -1];
typedef char vdp_client_faceanimtime[(offsetof(client_state_t, faceanimtime) ==
		VDP_CLIENT_FACEANIMTIME) ? 1 : -1];
typedef char vdp_client_cshifts[(offsetof(client_state_t, cshifts) ==
		VDP_CLIENT_CSHIFTS) ? 1 : -1];
typedef char vdp_client_time[(offsetof(client_state_t, time) ==
		VDP_CLIENT_TIME) ? 1 : -1];
typedef char vdp_client_time_size[(sizeof(((client_state_t *)0)->time) ==
		8U) ? 1 : -1];
typedef char vdp_client_viewentity[(offsetof(client_state_t, viewentity) ==
		VDP_CLIENT_VIEWENTITY) ? 1 : -1];
typedef char vdp_entity_size[(sizeof(entity_t) == VDP_ENTITY_SIZE) ? 1 : -1];
typedef char vdp_entity_origin[(offsetof(entity_t, origin) ==
		VDP_ENTITY_ORIGIN) ? 1 : -1];
typedef char vdp_entity_angles[(offsetof(entity_t, angles) ==
		VDP_ENTITY_ANGLES) ? 1 : -1];
typedef char vdp_cshift_damage[(CSHIFT_DAMAGE == VDP_CSHIFT_DAMAGE) ? 1 : -1];
typedef char vdp_cshift_size[(sizeof(cshift_t) == VDP_CSHIFT_SIZE) ? 1 : -1];
typedef char vdp_cshift_destcolor[(offsetof(cshift_t, destcolor) ==
		VDP_CSHIFT_DESTCOLOR) ? 1 : -1];
typedef char vdp_cshift_percent[(offsetof(cshift_t, percent) ==
		VDP_CSHIFT_PERCENT) ? 1 : -1];
typedef char vdp_cvar_size[(sizeof(cvar_t) == 24U) ? 1 : -1];
typedef char vdp_cvar_value[(offsetof(cvar_t, value) == VDP_CVAR_VALUE) ?
		1 : -1];

void V_ParseDamage_asm486 (void);
#endif

#endif /* ASM_VDAMAGE_H */
