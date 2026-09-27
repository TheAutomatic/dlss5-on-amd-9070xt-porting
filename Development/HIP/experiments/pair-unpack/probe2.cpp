#include "hip_api.h"
#include <vector>
#include <cstdio>
#include <cstring>
int main(int argc,char**argv){try{hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 void*d;a.Check(a.hipMalloc(&d,64),"m");void*args[]={&d};a.Check(a.hipModuleLaunchKernel(f,1,1,1,32,1,1,0,{},args,nullptr),"l");a.Check(a.hipDeviceSynchronize(),"s");
 unsigned o[10];a.Check(a.hipMemcpy(o,d,40,2),"b");const char*n[]={"asm lo.x","asm lo.y","asm hi.x","asm hi.y","builtin.x","builtin.y","byte0","byte1","byte2","byte3"};
 for(int i=0;i<10;i++){float v;memcpy(&v,&o[i],4);printf("%-10s %08x %g\n",n[i],o[i],v);}return 0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
