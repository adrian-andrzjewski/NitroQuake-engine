/* Limits shared by the client, server, model and sound interfaces. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef Q_SHARED_H
#define Q_SHARED_H

#include "q_types.h"

#define MAX_QPATH 64
#define MAX_OSPATH 128
#define MAX_MSGLEN 8000
#define MAX_DATAGRAM 1024
#define MAX_EDICTS 600
#define MAX_LIGHTSTYLES 64
#define MAX_MODELS 256
#define MAX_SOUNDS 256
#define SAVEGAME_COMMENT_LENGTH 39
#define MAX_STYLESTRING 64

#define MAX_CL_STATS 32
#define STAT_HEALTH 0
#define STAT_FRAGS 1
#define STAT_WEAPON 2
#define STAT_AMMO 3
#define STAT_ARMOR 4
#define STAT_WEAPONFRAME 5
#define STAT_SHELLS 6
#define STAT_NAILS 7
#define STAT_ROCKETS 8
#define STAT_CELLS 9
#define STAT_ACTIVEWEAPON 10
#define STAT_TOTALSECRETS 11
#define STAT_TOTALMONSTERS 12
#define STAT_SECRETS 13
#define STAT_MONSTERS 14

#endif /* Q_SHARED_H */
