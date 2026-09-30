// c512-av-f: c5c_inv (rcp + 2 Newton) vs 1.f/x for every float x in [1/256, 624] (x = lo + lane index).
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;
KERNEL void probe(uint*bad,uint lo,uint hi){uint b=lo+__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(b>hi)return;
 float x=__builtin_bit_cast(float,b),r=__builtin_amdgcn_rcpf(x);r=__builtin_fmaf(r,__builtin_fmaf(-x,r,1.f),r);r=__builtin_fmaf(r,__builtin_fmaf(-x,r,1.f),r);
 if(__builtin_bit_cast(uint,r)!=__builtin_bit_cast(uint,1.f/x))__atomic_fetch_add(bad,1u,__ATOMIC_RELAXED);}
