#ifndef NITROQUAKE_VERSION_H
#define NITROQUAKE_VERSION_H

/* The supported builder supplies this from an output-local generated header.
 * Direct legacy compiles remain identifiable as unnumbered build zero. */
#ifndef NITROQUAKE_BUILD_NUMBER
#define NITROQUAKE_BUILD_NUMBER 0
#endif
#define NITROQUAKE_STRINGIFY_INNER(value) #value
#define NITROQUAKE_STRINGIFY(value) NITROQUAKE_STRINGIFY_INNER(value)
#define NITROQUAKE_VERSION_STRING "NitroQuake v0.999"
#define NITROQUAKE_BUILD_STRING "Build " NITROQUAKE_STRINGIFY(NITROQUAKE_BUILD_NUMBER)

extern const char nitroquake_version[];
extern const char nitroquake_build[];

#endif
