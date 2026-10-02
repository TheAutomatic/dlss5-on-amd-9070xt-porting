// ideas-yi direction 3 probe: Hrtz as inline asm (production) vs builtin (HIP_C32_RTZ_ISA 2) feeding f32 mul/add consumers.
// All 2^32 x per launch-set; constants from a buffer so they are not folded; mismatches (bitwise) counted on the GPU.
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;
__attribute__((device)) static inline float hold(float x){uint h;float r;asm volatile("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(h):"v"(x));asm volatile("v_cvt_f32_f16 %0, %1":"=v"(r):"v"(h));return r;}
__attribute__((device)) static inline float hnew(float x){auto h=__builtin_amdgcn_cvt_pkrtz(x,x);return float(h[0]);}
KERNEL void probe(const float*c,uint*bad,uint*first,uint base){
 uint b=base+__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();float x=__builtin_bit_cast(float,b);
 float w=c[0],y=c[1];uint m=0;
 float o0=hold(x),n0=hnew(x);
 float o1=hold(x)*w,n1=hnew(x)*w;
 float o2=hold(x)+y,n2=hnew(x)+y;
 float o3=hold(hold(x)*w),n3=hnew(hnew(x)*w);
 float o4=hold(x)*w+y,n4=hnew(x)*w+y;
 m|=(__builtin_bit_cast(uint,o0)!=__builtin_bit_cast(uint,n0))?1u:0u;m|=(__builtin_bit_cast(uint,o1)!=__builtin_bit_cast(uint,n1))?2u:0u;
 m|=(__builtin_bit_cast(uint,o2)!=__builtin_bit_cast(uint,n2))?4u:0u;m|=(__builtin_bit_cast(uint,o3)!=__builtin_bit_cast(uint,n3))?8u:0u;
 m|=(__builtin_bit_cast(uint,o4)!=__builtin_bit_cast(uint,n4))?16u:0u;
 if(m){__hip_atomic_fetch_add(bad,1u,__ATOMIC_RELAXED,__HIP_MEMORY_SCOPE_AGENT);__hip_atomic_fetch_min(first,b,__ATOMIC_RELAXED,__HIP_MEMORY_SCOPE_AGENT);}}
