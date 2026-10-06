#include "hip_api.h"
#include <cstdio>
#include <cstdint>
#include <cstring>
int main(int argc,char**argv){try{hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 float flo=1.f/256,fhi=624.f;uint32_t lo,hi;memcpy(&lo,&flo,4);memcpy(&hi,&fhi,4);void*d;a.Check(a.hipMalloc(&d,4),"m");uint32_t z=0;a.Check(a.hipMemcpy(d,&z,4,1),"h");
 void*args[]={&d,&lo,&hi};uint32_t n=hi-lo+1;a.Check(a.hipModuleLaunchKernel(f,(n+255)/256,1,1,256,1,1,0,{},args,nullptr),"l");a.Check(a.hipDeviceSynchronize(),"s");
 a.Check(a.hipMemcpy(&z,d,4,2),"b");printf("divisors=%u [%08x,%08x] mismatch=%u\n",n,lo,hi,z);return z?1:0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
