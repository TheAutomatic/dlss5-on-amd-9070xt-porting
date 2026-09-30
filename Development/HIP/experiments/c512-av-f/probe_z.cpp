// Host for probe_z.hip: all 2^32 patterns; CPU model (model.inc fp8 RNE-saturating + fmodel.inc F) checked against the GPU O1.
#include "hip_api.h"
#include <vector>
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <cmath>
static float fb(uint32_t u){float f;memcpy(&f,&u,4);return f;}
static uint32_t bf(float f){uint32_t u;memcpy(&u,&f,4);return u;}
#include "model.inc"
#include "fmodel.inc"
int main(int argc,char**argv){try{hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 const uint32_t chunk=1u<<27;void*dO;void*dN;a.Check(a.hipMalloc(&dO,chunk*4ull),"m");a.Check(a.hipMalloc(&dN,chunk*4ull),"m");
 std::vector<uint32_t>O(chunk),N(chunk);
 uint64_t model_bad=0,m1=0,m1z=0,m1o=0,m2=0,m2o=0,m3=0,m3z=0,m3o=0;
 for(uint32_t c=0;c<32;c++){uint32_t base=c*chunk;void*args[]={&dO,&dN,&base};
  a.Check(a.hipModuleLaunchKernel(f,chunk/256,1,1,256,1,1,0,{},args,nullptr),"l");a.Check(a.hipDeviceSynchronize(),"s");
  a.Check(a.hipMemcpy(O.data(),dO,chunk*4ull,2),"b");a.Check(a.hipMemcpy(N.data(),dN,chunk*4ull,2),"b");
  for(uint32_t i=0;i<chunk;i++){uint32_t b=base+i;float x=fb(b);uint32_t w=O[i],o1=w&255,n1=(w>>8)&255,o2=(w>>16)&255,n2=w>>24,n3=N[i];
   if(std::isfinite(x)){uint32_t mo=fp8(fminf(fmaxf(Fm(x),-448.f),448.f));if(mo!=o1){if(model_bad<10)printf("MODEL %08x gpu=%02x cpu=%02x\n",b,o1,mo);model_bad++;}}
   bool negzero=(b==0x80000000u);
   if(o1!=n1){m1++;if(negzero)m1z++;else{m1o++;if(m1o<10)printf("AV %08x O=%02x N=%02x\n",b,o1,n1);}}
   if(o2!=n2){m2++;m2o++;if(m2o<10)printf("QKV %08x O=%02x N=%02x\n",b,o2,n2);}
   if(o2!=n3){m3++;if(negzero)m3z++;else{m3o++;if(m3o<10)printf("QKVraw %08x O=%02x N3=%02x\n",b,o2,n3);}}}
  fprintf(stderr,"chunk %u done\n",c);}
 printf("model_vs_gpu_mismatch(finite)=%llu\n",(unsigned long long)model_bad);
 printf("AV  fp8(F(x)) vs fp8(x): diff=%llu (x=-0: %llu, other: %llu)\n",(unsigned long long)m1,(unsigned long long)m1z,(unsigned long long)m1o);
 printf("QKV q8(F(x)) vs q8(med3(x+0)): diff=%llu\n",(unsigned long long)m2);
 printf("QKV q8(F(x)) vs q8(med3(x)) [info]: diff=%llu (x=-0: %llu, other: %llu)\n",(unsigned long long)m3,(unsigned long long)m3z,(unsigned long long)m3o);
 return (model_bad||m1o||m2)?1:0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
