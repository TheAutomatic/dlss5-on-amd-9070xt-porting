// f-sweep GPU probe B (host = c512-av-f probe_z.exe, all 2^32 x; slot O1/N1 kept as the AV pair so the CPU model check runs).
//  O2 = q8_fused_round(x) of multihead-fast-padded (HIP_BRANCHLESS_Q8 1, HIP_FMED3_CLAMP 1)
//  N2 = q8(med3(x+0,-448,448))  -- HIP_Q8_ADD0
#define KERNEL extern "C" __attribute__((global))
#define DEV static inline __attribute__((device,always_inline))
typedef unsigned int uint;
DEV uint bits(float x){return __builtin_bit_cast(uint,x);}
DEV uint c5c_fp8(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f),0.f,0,false))&255u;}
DEV float F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f);float r=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:r;}
DEV float add0(float x){
#pragma clang fp contract(off)
 return __builtin_amdgcn_fmed3f(x+0.f,-448.f,448.f);}
DEV uint q8(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(x,x,0,false))&255u;}
DEV uint oldb(float x){uint a=bits(x)&0x7fffffffu;uint q=q8(__builtin_amdgcn_fmed3f(x,-448.f,448.f));return a==0?0u:q;}
DEV uint newb(float x){return q8(add0(x));}
KERNEL void probe(uint*o,uint*n,uint base){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();float x=__builtin_bit_cast(float,base+i);
 o[i]=c5c_fp8(F(x))|(c5c_fp8(x)<<8)|(oldb(x)<<16)|(newb(x)<<24);n[i]=oldb(x);}
