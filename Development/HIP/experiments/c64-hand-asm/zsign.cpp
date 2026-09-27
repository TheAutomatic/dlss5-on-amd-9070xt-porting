#include "hip_api.h"
#include <vector>
#include <cstdio>
int main(int argc,char**argv){try{
 hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 void*d;a.Check(a.hipMalloc(&d,32*5*4),"m");void*args[]={&d};
 a.Check(a.hipModuleLaunchKernel(f,1,1,1,32,1,1,0,{},args,nullptr),"launch");a.Check(a.hipDeviceSynchronize(),"sync");
 std::vector<unsigned>o(32*5);a.Check(a.hipMemcpy(o.data(),d,32*5*4,2),"back");
 const char*n[5]={"A=-0,B=1,C=+0","A=-0,B=1,C=-0","+1/-1 cancel,C=+0","chain C=r0,A=-0","+1/-1 cancel,C=-0"};
 for(int k=0;k<5;k++){unsigned x=0;for(int l=0;l<32;l++)x|=o[l*5+k];printf("%-22s OR of all output bits = 0x%08x (%s)\n",n[k],x,x==0?"all +0":x==0x80000000u?"-0 present":"nonzero");}
 return 0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
