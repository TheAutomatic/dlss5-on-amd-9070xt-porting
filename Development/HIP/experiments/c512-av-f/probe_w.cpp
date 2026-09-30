#include "hip_api.h"
#include <cstdio>
#include <cstdint>
int main(int argc,char**argv){try{hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 void*d;a.Check(a.hipMalloc(&d,8),"m");uint64_t neg=0,pos=0,cells=0;
 for(uint32_t s=0;s<16;s++){uint32_t z[2]={0,0};a.Check(a.hipMemcpy(d,z,8,1),"h");void*args[]={&d,&s};
  a.Check(a.hipModuleLaunchKernel(f,4096,1,1,256,1,1,0,{},args,nullptr),"l");a.Check(a.hipDeviceSynchronize(),"s");
  a.Check(a.hipMemcpy(z,d,8,2),"b");neg+=z[0];pos+=z[1];cells+=4096ull*256*64*8;}
 printf("results=%llu  -0=%llu  +0=%llu\n",(unsigned long long)cells,(unsigned long long)neg,(unsigned long long)pos);return neg?1:0;}
 catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
