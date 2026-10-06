#include "hip_reference_network.h"
#include "production_options.generated.h"
#include <cstdio>
#include <chrono>
#include <fstream>
using namespace hip_reference;
static std::vector<char> read(const char*p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("input missing");std::vector<char>b(size_t(f.tellg()));f.seekg(0);if(!f.read(b.data(),b.size()))throw std::runtime_error("input short");return b;}
static void flags(const char*p){std::ifstream f(p);if(!f)throw std::runtime_error("flags missing");std::string s;while(std::getline(f,s)){if(s.empty()||s[0]=='#')continue;auto q=s.find('=');if(q==s.npos)continue;auto k=s.substr(0,q),v=s.substr(q+1);if(!v.empty()&&v.back()=='\r')v.pop_back();if(k.rfind("DLSS5_",0)==0)_putenv_s(k.c_str(),v.c_str());}}
int main(int argc,char**argv){try{
 if(argc!=9)throw std::runtime_error("bench ASSETS MODULES FLAGS PROCESSING_F32 OUTDIR WARM MEASURED PH");flags(argv[3]);
 const U w=1920,h=std::stoul(argv[8]),valid=1080,warm=std::stoul(argv[6]),measured=std::stoul(argv[7]);if((h!=1088&&h!=1152)||!warm||!measured||measured>1000)throw std::runtime_error("bounded sample count");
 for(const char*k:{"DLSS5_MULTI_PASS_PREDICT","DLSS5_MULTI_PASS_SKIN_PROTECT","DLSS5_HIP_GRAPH","DLSS5_OVERLAP","DLSS5_VIT_ADAPTIVE","DLSS5_VIT_REUSE_HOTKEY","DLSS5_TEMPORAL_HISTORY_EXPERIMENT","DLSS5_TEMPORAL_MV_UNJITTERED"})_putenv_s(k,"0");_putenv_s("DLSS5_MULTI_PASS","1");_putenv_s("DLSS5_STYLE","1");_putenv_s("DLSS5_SKIP_BLOCKS","");
 auto input=read(argv[4]);if(input.size()!=size_t(w)*h*16)throw std::runtime_error("input footprint");auto opt=production_options(argv[1],argv[2],w,h,false);opt.experimental_temporal=false;opt.skip_blocks.clear();if(!opt.wave_owned||!opt.c512_m32||!opt.pdl||opt.vit_stream!=3||!opt.swin_run)throw std::runtime_error("production profile missing");printf("SYNC_PROFILE wave_owned=%u c512_m32=%u pdl=%u vit_stream=%u swin_run=%u FAST=%s full71=%u\n",unsigned(opt.wave_owned),unsigned(opt.c512_m32),unsigned(opt.pdl),opt.vit_stream,unsigned(opt.swin_run),std::getenv("DLSS5_FAST_NUMERIC"),unsigned(opt.skip_blocks.empty()));Network net(opt);net.SetNoise({});auto&api=net.Runtime();auto stream=net.Stream();void*in{},*out{};api.Check(api.hipMalloc(&in,input.size()),"allocate input");api.Check(api.hipMalloc(&out,size_t(w)*h*12),"allocate output");api.Check(api.hipMemcpy(in,input.data(),input.size(),1),"upload input once");
 Handle begin{},end{};api.Check(api.hipEventCreate(&begin),"create begin");api.Check(api.hipEventCreate(&end),"create end");
 auto run=[&](){net.Enqueue(in,nullptr,out,0);net.Synchronize();};
 auto download=[&](const char*name){std::vector<float>v(size_t(w)*h*3);api.Check(api.hipMemcpy(v.data(),out,v.size()*4,2),"read output");for(float x:v)if(!std::isfinite(x))throw std::runtime_error("nonfinite output");std::ofstream f(std::string(argv[5])+"/"+name,std::ios::binary);if(!f.write(reinterpret_cast<char*>(v.data()),v.size()*4))throw std::runtime_error("output write");return v;};
 run();auto first=download("first.rgb32f");
 api.Load(api.hipModuleGetGlobal,"hipModuleGetGlobal");void*trace{};size_t bytes{};api.Check(api.hipModuleGetGlobal(&trace,&bytes,net.C32DiagnosticModule(),"c32_prefix_norm_trace"),"actual prefix trace global");if(bytes!=3072*4)throw std::runtime_error("trace footprint");std::vector<unsigned>words(3072);api.Check(api.hipMemcpy(words.data(),trace,bytes,2),"prefix trace read");std::ofstream(std::string(argv[5])+"/prefix-norm.u32",std::ios::binary).write((char*)words.data(),bytes);printf("ACTUAL_PREFIX_NORM_CAPTURE tracebytes=%zu once_full71\n",bytes);

 api.hipEventDestroy(begin);api.hipEventDestroy(end);api.hipFree(in);api.hipFree(out);return 0;
}catch(const std::exception&e){fprintf(stderr,"SYNC_NETWORK_FAIL %s\n",e.what());return 1;}}
