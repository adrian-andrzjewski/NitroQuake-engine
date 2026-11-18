/* Shared scalar types for renderer, video, memory, client and server APIs. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef Q_TYPES_H
#define Q_TYPES_H

#if !defined BYTE_DEFINED
typedef unsigned char byte;
#define BYTE_DEFINED 1
#endif

#undef true
#undef false
typedef enum { false, true } qboolean;

#endif /* Q_TYPES_H */
