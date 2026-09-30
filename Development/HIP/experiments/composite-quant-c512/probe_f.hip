// composite-quant-c512 GPU probe: production C512 f32 exit F(Hrtz(x)) vs candidate F(bits(x)&0xffffe000), one input per lane.
// Hrtz and F are the deep_fast.hip definitions (HIP_NATIVE_RTZ, HIP_NATIVE_FP8_F + HIP_BRANCHLESS_F), compiled the same way.
#define KERNEL extern "C" __attribute__((global))
#define DEV static inline __attribute__((device,always_inline))
typedef unsigned int uint;
DEV uint bits(float x){return __builtin_bit_cast(uint,x);}
DEV float F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f);float r=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:r;}
DEV float Hrtz(float x){uint h;float r;asm("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(h):"v"(x));asm("v_cvt_f32_f16 %0, %1":"=v"(r):"v"(h));return r;}
KERNEL void probe(uint*o,uint*n,uint base){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();uint b=base+i;float x=__builtin_bit_cast(float,b);
 o[i]=bits(F(Hrtz(x)));n[i]=bits(F(__builtin_bit_cast(float,b&0xffffe000u)));}
