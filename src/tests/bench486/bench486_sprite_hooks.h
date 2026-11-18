/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef BENCH486_SPRITE_HOOKS_H
#define BENCH486_SPRITE_HOOKS_H

#ifdef BENCH486
struct spritedesc_s;

extern void (*bench486_sprite_setup_hook) (void);
extern void (*bench486_sprite_project_hook) (const struct spritedesc_s *desc);
#endif

#endif /* BENCH486_SPRITE_HOOKS_H */
