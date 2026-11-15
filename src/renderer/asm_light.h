/*
 * r_lightasm.s structure offsets.
 * Keep these in sync with model.h and client.h. r_light.c checks every
 * consumed offset with offsetof/sizeof when either lighting assembly path is
 * selected.
 */
#define ml_dlight_origin       0
#define ml_dlight_radius       12
#define ml_dlight_die          16
#define ml_dlight_minlight     24
#define ml_dlight_size         32

#define ml_plane_normal        0
#define ml_plane_dist          12
#define ml_plane_size          20

#define ml_node_contents       0
#define ml_node_plane          24
#define ml_node_children       28
#define ml_node_firstsurface   36
#define ml_node_numsurfaces    38
#define ml_node_size           40

#define ml_surface_dlightframe 4
#define ml_surface_dlightbits  8
#define ml_surface_plane       12
#define ml_surface_texturemins 44
#define ml_surface_extents     48
#define ml_surface_texinfo     52
#define ml_surface_size        64

#define ml_texinfo_vecs         0
#define ml_texinfo_size        44
