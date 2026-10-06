#include "hip_api.h"
#include <fstream>
#include <cmath>
#include <cstring>
using namespace hip_probe;
static std::vector<float>read(const std::string&p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f||f.tellg()!=4096)throw std::runtime_error("store gold must be16x16 float4");std::vector<float>v(1024);f.seekg(0);f.read(reinterpret_cast<char*>(v.data()),4096);return v;}
int main(int argc,char**argv){try{
 if(argc!=3)throw std::runtime_error("store_probe WARP_HSACO GOLD_DIR");Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle stream,module,fn;a.Check(a.hipStreamCreate(&stream),"stream");a.Check(a.LoadModule(&module,argv[1]),"module");a.Check(a.hipModuleGetFunction(&fn,module,"temporal_store"),"store");void*input=nullptr,*out=nullptr;a.Check(a.hipMalloc(&input,3072),"input");a.Check(a.hipMalloc(&out,4096),"output");
 for(const char*name:{"closed-history","zero-motion","one-pixel-motion","subpixel-diagonal"}){
  auto source=read(std::string(argv[2])+"/"+name+"-float-output.f32"),gold=read(std::string(argv[2])+"/"+name+"-half-output.f32");std::vector<float>rgb(768),actual(1024);for(unsigned i=0;i<256;i++)for(unsigned c=0;c<3;c++)rgb[i*3+c]=source[i*4+c];a.Check(a.hipMemcpy(input,rgb.data(),3072,1),"upload");unsigned w=16,h=16;void*args[]={&input,&out,&w,&h};a.Check(a.hipModuleLaunchKernel(fn,1,1,1,256,1,1,0,stream,args,nullptr),"store launch");a.Check(a.hipStreamSynchronize(stream),"ready");a.Check(a.hipMemcpy(actual.data(),out,4096,2),"readback");unsigned diff=0;for(unsigned i=0;i<1024;i++)diff+=memcmp(&actual[i],&gold[i],4)!=0;printf("STORE_GOLD case=%s float_bit_diff=%u\n",name,diff);if(diff)return 1;
 }
 a.hipFree(out);a.hipFree(input);a.hipModuleUnload(module);a.hipStreamDestroy(stream);return 0;
}catch(const std::exception&e){fprintf(stderr,"STORE_FAIL %s\n",e.what());return 2;}}
