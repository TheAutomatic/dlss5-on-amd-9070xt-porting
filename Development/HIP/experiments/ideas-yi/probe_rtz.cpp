#include "hip_api.h"
#include <cstdio>
#include <cstdint>
int main(int argc,char**argv){try{hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");
 hip_probe::Handle m{},f{};a.Check(a.hipModuleLoad(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"fn");
 const float cs[][2]={{0.25f,-0.5f},{0.125f,0.0625f},{-1.5f,1.0f},{0x1p-15f,-0x1p-20f},{1.0f,-0.0f},{3.14159f,-2.71828f},{-0x1p-130f,0x1p-126f},{65504.f,-1e30f}};
 void*dc;void*db;void*df;a.Check(a.hipMalloc(&dc,8),"m");a.Check(a.hipMalloc(&db,4),"m");a.Check(a.hipMalloc(&df,4),"m");unsigned long long total=0;int rc=0;
 for(auto&c:cs){a.Check(a.hipMemcpy(dc,c,8,1),"c");uint32_t z=0,big=0xffffffffu;a.Check(a.hipMemcpy(db,&z,4,1),"z");a.Check(a.hipMemcpy(df,&big,4,1),"z");
  for(uint32_t k=0;k<16;k++){uint32_t base=k<<28;void*args[]={&dc,&db,&df,&base};a.Check(a.hipModuleLaunchKernel(f,(1u<<28)/256,1,1,256,1,1,0,{},args,nullptr),"l");}
  a.Check(a.hipDeviceSynchronize(),"s");uint32_t bad,first;a.Check(a.hipMemcpy(&bad,db,4,2),"b");a.Check(a.hipMemcpy(&first,df,4,2),"b");
  printf("w=%g y=%g: 2^32 x, mismatches=%u first=%08x\n",c[0],c[1],bad,bad?first:0);total+=bad;if(bad)rc=1;}
 printf("TOTAL mismatches=%llu\n",total);return rc;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
