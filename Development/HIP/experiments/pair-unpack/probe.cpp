#include "hip_api.h"
#include <vector>
#include <cstdio>
int main(int argc,char**argv){try{
 hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 void*dout;a.Check(a.hipMalloc(&dout,(1024+8)*4),"m");void*args[]={&dout};
 a.Check(a.hipModuleLaunchKernel(f,1,1,1,256,1,1,0,{},args,nullptr),"launch");a.Check(a.hipDeviceSynchronize(),"sync");
 std::vector<unsigned> o(1024+8);a.Check(a.hipMemcpy(o.data(),dout,(1024+8)*4,2),"back");
 unsigned rt_bad=0,lo_bad=0,hi_bad=0;
 for(unsigned b=0;b<256;b++){if(o[b*4]!=b){rt_bad++;printf("roundtrip byte 0x%02x -> 0x%02x (f32 bits 0x%08x)\n",b,o[b*4],o[b*4+3]);}if(!o[b*4+1])lo_bad++;if(!o[b*4+2])hi_bad++;}
 printf("b=5 w=%08x s0=%08x s1=%08x lo=%08x,%08x hi=%08x,%08x\n",o[1030],o[1024],o[1025],o[1026],o[1027],o[1028],o[1029]);
 printf("roundtrip mismatches %u, pair lo mismatches %u, pair hi mismatches %u\n",rt_bad,lo_bad,hi_bad);return 0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
