#include "hip_reference_network.h"
#include <fstream>
#include <vector>
#include <cstdio>
using namespace hip_reference;
static std::vector<char> read(const std::string&p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("read "+p);std::vector<char>b(size_t(f.tellg()));f.seekg(0);if(!f.read(b.data(),b.size()))throw std::runtime_error("short read");return b;}
int main(int argc,char**argv){try{if(argc!=6)throw std::runtime_error("warp_probe WARP GATE RECIP_TABLE NV_SIG CASE_DIR");Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle stream;a.Check(a.hipStreamCreate(&stream),"stream");std::vector<void*>owned;
 auto alloc=[&](size_t bytes){void*p;a.Check(a.hipMalloc(&p,bytes),"alloc");owned.push_back(p);return p;};auto load=[&](const std::vector<char>&b){void*p=alloc(b.size());a.Check(a.hipMemcpy(p,b.data(),b.size(),1),"upload");return p;};
 Handle wm,gm;a.Check(a.LoadModule(&wm,argv[1]),"warp module");a.Check(a.LoadModule(&gm,argv[2]),"gate module");Handle wf,gf;a.Check(a.hipModuleGetFunction(&wf,wm,"temporal_warp"),"warp fn");a.Check(a.hipModuleGetFunction(&gf,gm,"hip_gate_resolve"),"resolve fn");
 unsigned w=16,h=16,p=16,n=256;float blend=.73974609375f;void *hist=load(read(std::string(argv[5])+"/history.f32")),*rgb=alloc(n*12),*motion=alloc(n*8),*prefix=alloc(n*16),*raw=alloc(n*16),*logit=alloc(n*2),*sig=load(read(argv[4])),*recip=load(read(argv[3])),*out=alloc(n*12);
 std::vector<float>cv(n*3);for(unsigned i=0;i<n;i++){cv[i*3]=.25f;cv[i*3+1]=.5f;cv[i*3+2]=.75f;}a.Check(a.hipMemcpy(rgb,cv.data(),cv.size()*4,1),"rgb");a.Check(a.hipMemsetAsync(logit,0,n*2,stream),"logit0");
 const char*names[]={"closed-history","zero-motion","one-pixel-motion","subpixel-diagonal"};
 for(unsigned c=0;c<4;c++){
  std::vector<float>mv(n*2);if(c==2)for(unsigned i=0;i<n;i++)mv[i*2]=1.f;if(c==3)for(unsigned i=0;i<n;i++){mv[i*2]=.25f;mv[i*2+1]=.375f;}
  a.Check(a.hipMemcpy(motion,mv.data(),mv.size()*4,1),"mv");void*wa[]={&hist,&motion,&prefix,&raw,&recip,&w,&h,&p};a.Check(a.hipModuleLaunchKernel(wf,1,1,1,256,1,1,0,stream,wa,nullptr),"warp");unsigned enabled=c?1:0;void*ga[]={&rgb,&raw,&logit,&sig,&out,&n,&blend,&enabled};a.Check(a.hipModuleLaunchKernel(gf,1,1,1,256,1,1,0,stream,ga,nullptr),"resolve");a.Check(a.hipStreamSynchronize(stream),"ready");
  auto gold=read(std::string(argv[5])+"/"+names[c]+"-output.f32");if(gold.size()!=n*16)throw std::runtime_error("gold shape");std::vector<float>actual(n*3);a.Check(a.hipMemcpy(actual.data(),out,actual.size()*4,2),"readback");size_t diff=0;double maximum=0;for(unsigned i=0;i<n;i++)for(unsigned ch=0;ch<3;ch++){float g;memcpy(&g,gold.data()+(i*4+ch)*4,4);auto v=actual[i*3+ch];diff+=memcmp(&g,&v,4)!=0;maximum=std::max(maximum,double(std::abs(g-v)));}
  printf("WARP_GOLD case=%s float_bit_diff=%zu maxabs=%.12g\n",names[c],diff,maximum);std::ofstream file(std::string(argv[5])+"/hip-"+names[c]+".rgb32",std::ios::binary);file.write(reinterpret_cast<const char*>(actual.data()),actual.size()*4);if(diff)return 1;
 }
 for(auto ptr:owned)a.hipFree(ptr);a.hipModuleUnload(wm);a.hipModuleUnload(gm);a.hipStreamDestroy(stream);return 0;
}catch(const std::exception&e){fprintf(stderr,"warp FAIL %s\n",e.what());return 2;}}
