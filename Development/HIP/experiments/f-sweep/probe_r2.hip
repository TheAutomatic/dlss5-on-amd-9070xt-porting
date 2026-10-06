// f-sweep: rcp + 2 Newton vs 1.f/x for every float in [1/256, 2048]. Host = c512-av-f probe_r.exe (passes lo..hi of
// [1/256, 624]); each lane also checks x = bits(624)+index while <= bits(2048), so the union is [1/256, 2048].
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;
static inline __attribute__((device,always_inline)) bool bad(uint b){float x=__builtin_bit_cast(float,b),r=__builtin_amdgcn_rcpf(x);r=__builtin_fmaf(r,__builtin_fmaf(-x,r,1.f),r);r=__builtin_fmaf(r,__builtin_fmaf(-x,r,1.f),r);return __builtin_bit_cast(uint,r)!=__builtin_bit_cast(uint,1.f/x);}
KERNEL void probe(uint*o,uint lo,uint hi){uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x(),b=lo+i;if(b>hi)return;
 if(bad(b))__atomic_fetch_add(o,1u,__ATOMIC_RELAXED);
 uint b2=hi+i;if(b2<=0x45000000u&&bad(b2))__atomic_fetch_add(o,1u,__ATOMIC_RELAXED);}
