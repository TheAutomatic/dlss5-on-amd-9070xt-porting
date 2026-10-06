#define KERNEL extern "C" __attribute__((global))
using uint=unsigned int;
using h8=_Float16 __attribute__((ext_vector_type(8)));
using f8=float __attribute__((ext_vector_type(8)));
KERNEL __attribute__((amdgpu_flat_work_group_size(32,32))) void c512_den_typed_basis(uint*out){
 uint lane=__builtin_amdgcn_workitem_id_x();h8 exponent[4];
 for(uint key=0;key<4;key++)for(uint e=0;e<8;e++)exponent[key][e]=(_Float16)(float(1+key*257+lane*8+e)/1024.f);
 h8 ones{};for(uint e=0;e<8;e++)ones[e]=(_Float16)1.f;
 f8 sums[2]{};
 // Exact operand order / four-WMMA reduction from production den.
 for(uint side=0;side<2;side++)for(uint h=0;h<2;h++)sums[side]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,exponent[side+2*h],sums[side]);
 for(uint e=0;e<8;e++)out[lane*8+e]=__builtin_bit_cast(uint,sums[0][e]+sums[1][e]);
}
