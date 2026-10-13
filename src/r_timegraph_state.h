/* Shared C state layout for the R_TimeGraph reference and assembly paths. */
#ifndef R_TIMEGRAPH_STATE_H
#define R_TIMEGRAPH_STATE_H

#include "asm_timegraph.h"

typedef struct
{
	int timex;
	byte timings[TG_MAX_TIMINGS];
} r_timegraph_state_t;

extern r_timegraph_state_t r_timegraph_state;

#endif
