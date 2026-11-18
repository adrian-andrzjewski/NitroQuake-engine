/* NitroQuake modifications: see Git history for dates and details (notice: 2026-11-18). */
#ifndef ASM_VISIBILITY_H
#define ASM_VISIBILITY_H
#include <stddef.h>
#define VIS_LAYOUT(name,condition) typedef char vis_##name[(condition) ? 1 : -1]
VIS_LAYOUT(pointer,sizeof(void *) == 4);
VIS_LAYOUT(float32,sizeof(float) == 4);
VIS_LAYOUT(buffer,MAX_MAP_LEAFS / 8 == 1024);
VIS_LAYOUT(model_size,sizeof(model_t) == 392);
VIS_LAYOUT(model_nodes,offsetof(model_t,nodes) == 164);
VIS_LAYOUT(model_leafs,offsetof(model_t,leafs) == 140);
VIS_LAYOUT(model_numleafs,offsetof(model_t,numleafs) == 136);
VIS_LAYOUT(node_size,sizeof(mnode_t) == 40);
VIS_LAYOUT(node_contents,offsetof(mnode_t,contents) == 0);
VIS_LAYOUT(node_plane,offsetof(mnode_t,plane) == 24);
VIS_LAYOUT(node_children,offsetof(mnode_t,children) == 28);
VIS_LAYOUT(leaf_size,sizeof(mleaf_t) == 48);
VIS_LAYOUT(leaf_contents,offsetof(mleaf_t,contents) == 0);
VIS_LAYOUT(leaf_compressed_vis,offsetof(mleaf_t,compressed_vis) == 24);
VIS_LAYOUT(plane_size,sizeof(mplane_t) == 20);
VIS_LAYOUT(plane_normal,offsetof(mplane_t,normal) == 0);
VIS_LAYOUT(plane_dist,offsetof(mplane_t,dist) == 12);
#undef VIS_LAYOUT
#endif
