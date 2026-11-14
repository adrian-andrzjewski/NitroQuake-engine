/* DJGPP i486 sprite orientation ABI. r_sprite.c asserts each consumed layout. */
#define so_entity_angles          120
#define so_entity_model           132
#define so_entity_frame           140
#define so_entity_syncbase        144
#define so_model_cache            388
#define so_client_time            572
#define so_sprite_type              0
#define so_sprite_numframes        12
#define so_sprite_beamlength       16
#define so_desc_frame               8
#define so_desc_up                 12
#define so_desc_right              24
#define so_desc_normal             36
#define so_desc_size               52

/* spritegn.h's on-disk orientation numbers, checked by r_sprite.c. */
#define so_parallel_upright         0
#define so_facing_upright           1
#define so_parallel                 2
#define so_oriented                 3
#define so_parallel_oriented        4
