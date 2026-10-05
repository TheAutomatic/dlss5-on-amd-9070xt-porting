#include "hip_api.h"
#include <fstream>
#include <cstdio>
#include <vector>
#include <cstring>
using namespace hip_probe;
static std::vector<char>read(const std::string&p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("probe data missing");std::vector<char>b(size_t(f.tellg()));f.seekg(0);if(!f.read(b.data(),b.size()))throw std::runtime_error("probe short data");return b;}
int main(int argc,char**argv){try{
 if(argc!=4&&argc!=5)throw std::runtime_error("small_probe SCORE_MODULE DEN_MODULE DATA_DIR");Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle stream,sm,dm,sf,df;a.Check(a.hipStreamCreate(&stream),"stream");a.Check(a.LoadModule(&sm,argv[1]),"score module");a.Check(a.LoadModule(&dm,argv[2]),"den module");a.Check(a.hipModuleGetFunction(&sf,sm,"score_half_probe"),"score fn");a.Check(a.hipModuleGetFunction(&df,dm,"den_half_probe"),"den fn");
 auto check=[&](Handle fn,const std::string&inputname,const std::string&goldname,unsigned arg,unsigned groups,unsigned threads){auto input=read(std::string(argv[3])+"/"+inputname),gold=read(std::string(argv[3])+"/"+goldname);void*in=nullptr,*out=nullptr;a.Check(a.hipMalloc(&in,input.size()),"alloc input");a.Check(a.hipMalloc(&out,gold.size()),"alloc output");a.Check(a.hipMemcpy(in,input.data(),input.size(),1),"upload");void*args[]={&in,&out,&arg};a.Check(a.hipModuleLaunchKernel(fn,groups,1,1,threads,1,1,0,stream,args,nullptr),"launch");a.Check(a.hipStreamSynchronize(stream),"completion");std::vector<char>actual(gold.size());a.Check(a.hipMemcpy(actual.data(),out,actual.size(),2),"readback");size_t diff=0;for(size_t i=0;i<gold.size();i+=2)diff+=memcmp(actual.data()+i,gold.data()+i,2)!=0;printf("MATH_SMALL %s half_code_diff=%zu elements=%zu\n",inputname.c_str(),diff,gold.size()/2);a.hipFree(in);a.hipFree(out);if(diff)throw std::runtime_error("math scalar contract mismatch");};
 unsigned n=unsigned(read(std::string(argv[3])+"/scores.f32").size()/4);check(sf,"scores.f32","score-gold.f16bits",n,(n+255)/256,256);if(argc==4)for(unsigned tokens:{400,640})check(df,"den-"+std::to_string(tokens)+".f16","den-"+std::to_string(tokens)+"-gold.f16",tokens,4,32);a.hipModuleUnload(dm);a.hipModuleUnload(sm);a.hipStreamDestroy(stream);return 0;
}catch(const std::exception&e){fprintf(stderr,"MATH_SMALL_FAIL %s\n",e.what());return 1;}}
