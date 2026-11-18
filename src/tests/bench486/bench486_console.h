/* Benchmark-only console wrappers and C-reference entry points. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_CONSOLE_H
#define BENCH486_CONSOLE_H

void Con_CheckResize_C (void);
int Bench486ConsoleResizeCases (void);

void Bench486ConPrintSound (char *sample);

int Bench486ConsoleOutputOpen (char *file, int flags, int mode);
int Bench486ConsoleOutputWrite (int fd, char *data, unsigned count);
int Bench486ConsoleOutputClose (int fd);
void Bench486ConsoleOutputSysPrintf (char *format, ...);
void Bench486ConsoleOutputUpdateScreen (void);

#endif /* BENCH486_CONSOLE_H */
