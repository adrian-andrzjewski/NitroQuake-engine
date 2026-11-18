/* Hand-maintained sky layout, checked against the original C definitions. */
/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_SKY_H
#define ASM_SKY_H
#define sky_texture_mip_offsets 44
#define sky_client_time 572
#define sky_size 128
#define sky_mask 127
#define sky_bottom_stride 131
#define sky_texture_stride 256
#ifndef __ASSEMBLER__
#include <stddef.h>
#define SKY_LAYOUT(name,condition) typedef char sky_layout_check_##name[(condition) ? 1 : -1]
SKY_LAYOUT(pointer32,sizeof(void *) == 4);
SKY_LAYOUT(integer32,sizeof(int) == 4 && sizeof(unsigned) == 4);
SKY_LAYOUT(float32,sizeof(float) == 4);
SKY_LAYOUT(double64,sizeof(double) == 8);
SKY_LAYOUT(texture_offsets,offsetof(texture_t,offsets) == sky_texture_mip_offsets);
SKY_LAYOUT(client_time,offsetof(client_state_t,time) == sky_client_time);
SKY_LAYOUT(sky_size,SKYSIZE == sky_size);
SKY_LAYOUT(sky_mask,SKYMASK == sky_mask);
SKY_LAYOUT(tile_size,TILE_SIZE == sky_size);
#undef SKY_LAYOUT
#endif
#endif
