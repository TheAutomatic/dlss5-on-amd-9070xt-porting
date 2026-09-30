// c512-av-f GPU probe, one 32-bit input x per lane, definitions copied from c512-m32-mh (HIP_FMED3_CLAMP 1):
//  site AV : O1 = c5c_fp8(c5c_F(x))            N1 = c5c_fp8(x)
//  site QKV: O2 = q8(F(x))  (F with fmed3)     N2 = q8(fmed3(x+0))   N3 = q8(fmed3(x))  (N3: info only)
#define KERNEL extern "C" __attribute__((global))
#define DEV static inline __attribute__((device,always_inline))
typedef unsigned int uint;
DEV uint bits(float x){return __builtin_bit_cast(uint,x);}
DEV uint c5c_fp8(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f),0.f,0,false))&255u;}
DEV float c5c_F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f);float r=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:r;}
DEV float F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_amdgcn_fmed3f(x,-448.f,448.f);float r=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:r;}
DEV uint q8(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(x,x,0,false))&255u;}
DEV uint q8z(float x){return q8(__builtin_amdgcn_fmed3f(x+0.f,-448.f,448.f));}
KERNEL void probe(uint*o,uint*n,uint base){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();float x=__builtin_bit_cast(float,base+i);
 o[i]=c5c_fp8(c5c_F(x))|(c5c_fp8(x)<<8)|(q8(F(x))<<16)|(q8z(x)<<24);n[i]=q8(__builtin_amdgcn_fmed3f(x,-448.f,448.f));}
