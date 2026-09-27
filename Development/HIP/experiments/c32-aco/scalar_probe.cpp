#include "hip_api.h"
#include <vector>
int main(int argc,char**argv){try{
 if(argc!=2)return 2;hip_probe::Api a;a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");
 hip_probe::Handle m{},f{};a.Check(a.LoadModule(&m,argv[1]),"module");a.Check(a.hipModuleGetFunction(&f,m,"probe"),"function");
 void*d{};a.Check(a.hipMalloc(&d,65536*3*4),"alloc");void*args[]={&d};a.Check(a.hipModuleLaunchKernel(f,256,1,1,256,1,1,0,nullptr,args,nullptr),"launch");a.Check(a.hipDeviceSynchronize(),"sync");
 std::vector<unsigned> v(65536*3);a.Check(a.hipMemcpy(v.data(),d,v.size()*4,2),"copy");unsigned c=0,r=0;
 for(unsigned i=0;i<65536;i++){if(v[3*i]!=v[3*i+1]){if(c<8)printf("DIRECT mismatch half=%04x old=%02x new=%02x\n",i,v[3*i],v[3*i+1]);c++;}r+=v[3*i+2];}
 printf("FP16_CODES=65536 DIRECT_BAD=%u RTZ_PAIRS=1048576 RTZ_BAD=%u\n",c,r);a.hipFree(d);a.hipModuleUnload(m);return c||r?1:0;
}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
