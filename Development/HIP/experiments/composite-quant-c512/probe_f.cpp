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
 uint64_t fin=0,nf=0,model_bad=0,mis=0,mis_negtiny=0,mis_nonfinite=0,mis_other=0,mis_domain=0;
 for(uint32_t c=0;c<32;c++){uint32_t base=c*chunk;void*args[]={&dO,&dN,&base};
  a.Check(a.hipModuleLaunchKernel(f,chunk/256,1,1,256,1,1,0,{},args,nullptr),"l");a.Check(a.hipDeviceSynchronize(),"s");
  a.Check(a.hipMemcpy(O.data(),dO,chunk*4ull,2),"b");a.Check(a.hipMemcpy(N.data(),dN,chunk*4ull,2),"b");
  for(uint32_t i=0;i<chunk;i++){uint32_t b=base+i;float x=fb(b);bool finite=std::isfinite(x);bool negtiny=(b&0x80000000u)&&std::fabs(x)<0x1p-24f;
   if(finite){fin++;uint32_t mo=bf(Fm(half_rtz(x)));if(mo!=O[i]){if(model_bad<10)printf("MODEL %08x gpu=%08x cpu=%08x\n",b,O[i],mo);model_bad++;}}else nf++;
   if(O[i]!=N[i]){mis++;if(finite&&(x==0.f||std::fabs(x)>=0x1p-18f))mis_domain++;
    if(!finite){mis_nonfinite++;if(mis_nonfinite<6)printf("NONFINITE %08x O=%08x N=%08x\n",b,O[i],N[i]);}else if(negtiny)mis_negtiny++;else{mis_other++;if(mis_other<10)printf("OTHER %08x O=%08x N=%08x\n",b,O[i],N[i]);}}}
  fprintf(stderr,"chunk %u done\n",c);}
 printf("finite=%llu nonfinite=%llu model_vs_gpu_mismatch=%llu\n",(unsigned long long)fin,(unsigned long long)nf,(unsigned long long)model_bad);
 printf("O!=N total=%llu nonfinite=%llu neg0<|x|<2^-24=%llu other=%llu in-domain(0 or |x|>=2^-18)=%llu\n",(unsigned long long)mis,(unsigned long long)mis_nonfinite,(unsigned long long)mis_negtiny,(unsigned long long)mis_other,(unsigned long long)mis_domain);
 return (model_bad||mis_other||mis_domain)?1:0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
