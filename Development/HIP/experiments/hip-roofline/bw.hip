// Streaming bandwidth kernels (grid-stride, 16-byte accesses). Timed by bw.cpp with hipEvents. No headers (comgr).
typedef float f4 __attribute__((ext_vector_type(4)));
typedef unsigned long long u64;
#define GID (u64(__builtin_amdgcn_workgroup_id_x())*256u+__builtin_amdgcn_workitem_id_x())
#define STRIDE st
#define KER extern "C" __attribute__((global)) __attribute__((amdgpu_flat_work_group_size(256,256)))
KER void rd(const f4*a,u64 n,float*sink,u64 st){f4 s=0;for(u64 i=GID;i<n;i+=STRIDE)s+=a[i];if(s.x+s.y+s.z+s.w==1234.5f)sink[0]=s.x;}
KER void wr(f4*a,u64 n,u64 st){for(u64 i=GID;i<n;i+=STRIDE)a[i]=0;}
KER void cp(const f4*a,f4*b,u64 n,u64 st){for(u64 i=GID;i<n;i+=STRIDE)b[i]=a[i];}
