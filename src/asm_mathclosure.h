/* Math support ABI: packed float vectors/matrices, original C scalar types. */
#ifndef ASM_MATHCLOSURE_H
#define ASM_MATHCLOSURE_H
typedef char mc_pointer_size[(sizeof(void *) == 4) ? 1 : -1];
typedef char mc_int_size[(sizeof(int) == 4) ? 1 : -1];
typedef char mc_float_size[(sizeof(float) == 4) ? 1 : -1];
typedef char mc_double_size[(sizeof(double) == 8) ? 1 : -1];
typedef char mc_vec_t_size[(sizeof(vec_t) == 4) ? 1 : -1];
typedef char mc_vec3_t_size[(sizeof(vec3_t) == 12) ? 1 : -1];
typedef char mc_matrix3x3_size[(sizeof(float[3][3]) == 36) ? 1 : -1];
typedef char mc_matrix3x4_size[(sizeof(float[3][4]) == 48) ? 1 : -1];
#endif
