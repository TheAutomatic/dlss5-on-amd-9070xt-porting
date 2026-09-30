// c512-av-f: does the P.V WMMA chain (4 x wmma_f32_16x16x16_fp8_fp8 from f8{} = +0, as in c5c_body) ever return -0?
// Per wave: V/P bytes from a hash of (seed, trial, lane); mode picks the byte pool. Output: count of lanes*elems whose result is -0,
// count of exact zeros (+0) for coverage.
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;typedef int i2 __attribute__((ext_vector_type(2)));typedef float f8 __attribute__((ext_vector_type(8)));
static inline __attribute__((device,always_inline)) uint hsh(uint x){x^=x>>16;x*=0x7feb352du;x^=x>>15;x*=0x846ca68bu;x^=x>>16;return x;}
static inline __attribute__((device,always_inline)) uint vbyte(uint mode,uint r){
 switch(mode){
  case 0: return 0x80u;                                   // all V = -0
  case 1: return (r&1)?0x80u:0x00u;                        // +-0 mix
  case 2: return (r&3)==0?0x80u:((r>>2)&1?0x01u:0x81u);    // -0 and +-min subnormal (cancellation)
  case 3: {uint m=(r>>1)&7u;return (r&1?0x80u:0u)|m;}      // signed subnormals incl. -0
  default: return r&255u&~0x7fu?((r&255u)==0xffu?0xfeu:(r&255u)):((r&255u)==0x7fu?0x7eu:(r&255u)); // any non-NaN byte
 }}
static inline __attribute__((device,always_inline)) uint pbyte(uint mode,uint r){uint b=r&0x7fu;if(b==0x7fu)b=0x7eu;return (mode==5)?0u:b;} // prob >= +0, never NaN
KERNEL void probe(uint*out,uint seed){
 uint lane=__builtin_amdgcn_workitem_id_x()&31u,wg=__builtin_amdgcn_workgroup_id_x()*(8)+__builtin_amdgcn_workitem_id_x()/32;
 uint neg0=0,pos0=0;
 for(uint t=0;t<64;t++){uint mode=(wg+t)%6;f8 av{};
  for(uint kt=0;kt<4;kt++){i2 v,p;uint vb[2]={0,0},pb[2]={0,0};
   for(uint e=0;e<8;e++){uint r=hsh(seed^hsh(wg*977u+t*131u+kt*17u+e*3u)^hsh(lane*7919u+e));vb[e/4]|=vbyte(mode==5?0:mode,r)<<(8*(e%4));pb[e/4]|=pbyte(mode,hsh(r))<<(8*(e%4));}
   v=i2{int(vb[0]),int(vb[1])};p=i2{int(pb[0]),int(pb[1])};
   av=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(v,p,av);}
  for(uint e=0;e<8;e++){uint b=__builtin_bit_cast(uint,av[e]);neg0+=b==0x80000000u;pos0+=b==0u;}}
 __atomic_fetch_add(&out[0],neg0,__ATOMIC_RELAXED);__atomic_fetch_add(&out[1],pos0,__ATOMIC_RELAXED);}
