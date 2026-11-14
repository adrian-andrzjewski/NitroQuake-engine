/* Shared scalar types for renderer, video, memory, client and server APIs. */
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
