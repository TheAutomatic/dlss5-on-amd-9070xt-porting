// f-sweep GPU probe A (host = c512-av-f probe_z.exe, all 2^32 x; slot O1/N1 kept as the AV pair so the CPU model check runs).
//  O2 = byte_F(x) with the branchless F of deep_fast/vit-stream (== w2_up_F, decoder cvt_pk(F(merged)))
//  N2 = cvt_pk_fp8(med3(x+0,-448,448))   -- HIP_BYTE_F_ADD0 / W2_UP_ADD0
#define KERNEL extern "C" __attribute__((global))
#define DEV static inline __attribute__((device,always_inline))
typedef unsigned int uint;
DEV uint bits(float x){return __builtin_bit_cast(uint,x);}
DEV uint c5c_fp8(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f),0.f,0,false))&255u;}
DEV float F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f);float r=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:r;}
DEV float add0(float x){
#pragma clang fp contract(off)
 return __builtin_amdgcn_fmed3f(x+0.f,-448.f,448.f);}
DEV uint oldb(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(F(x),0.f,0,false))&255u;}
DEV uint newb(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(add0(x),0.f,0,false))&255u;}
KERNEL void probe(uint*o,uint*n,uint base){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();float x=__builtin_bit_cast(float,base+i);
 o[i]=c5c_fp8(F(x))|(c5c_fp8(x)<<8)|(oldb(x)<<16)|(newb(x)<<24);n[i]=oldb(x);}
