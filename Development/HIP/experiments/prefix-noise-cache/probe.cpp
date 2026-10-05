#include "hip_reference_network.h"
#include "production_options.generated.h"
#include <fstream>
#include <cstring>
#include <chrono>
using namespace hip_reference;
static std::vector<char>load(const char*p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("input read");std::vector<char>b(size_t(f.tellg()));f.seekg(0);if(!f.read(b.data(),b.size()))throw std::runtime_error("input short");return b;}
static void flags(const char*p){std::ifstream f(p);if(!f)throw std::runtime_error("flags missing");std::string s;while(std::getline(f,s)){if(!s.empty()&&s.back()=='\r')s.pop_back();if(s.empty()||s[0]=='#')continue;auto q=s.find('=');if(q!=s.npos&&s.rfind("DLSS5_",0)==0)_putenv_s(s.substr(0,q).c_str(),s.substr(q+1).c_str());}}
int main(int argc,char**argv){try{
 if(argc!=10)throw std::runtime_error("probe ASSETS MODULES FLAGS INPUT OUTDIR W H MODE(gold|0|1) FRAMES");flags(argv[3]);U W=std::stoul(argv[6]),H=std::stoul(argv[7]),frames=std::stoul(argv[9]);if(W%64||H%64||!frames||frames>400)throw std::runtime_error("geometry/frame bound");
 for(const char*k:{"DLSS5_MULTI_PASS_PREDICT","DLSS5_MULTI_PASS_SKIN_PROTECT","DLSS5_HIP_GRAPH","DLSS5_OVERLAP","DLSS5_VIT_ADAPTIVE","DLSS5_VIT_REUSE_HOTKEY","DLSS5_TEMPORAL_HISTORY_EXPERIMENT","DLSS5_TEMPORAL_MV_UNJITTERED"})_putenv_s(k,"0");_putenv_s("DLSS5_MULTI_PASS","1");_putenv_s("DLSS5_STYLE","1");_putenv_s("DLSS5_SKIP_BLOCKS","");
 auto data=load(argv[4]);if(data.size()!=size_t(W)*H*16)throw std::runtime_error("input size");auto o=production_options(argv[1],argv[2],W,H,false);o.experimental_temporal=false;o.skip_blocks.clear();Network net(o);net.SetNoise({});auto&api=net.Runtime();auto stream=net.Stream();void*in{},*out{};api.Check(api.hipMalloc(&in,data.size()),"input alloc");api.Check(api.hipMalloc(&out,size_t(W)*H*12),"output alloc");api.Check(api.hipMemcpy(in,data.data(),data.size(),1),"input once");
 auto bytes=[&](void*p,size_t n){std::vector<char>b(n);api.Check(api.hipMemcpy(b.data(),p,n,2),"probe readback");return b;};
 auto save=[&](const char*name,const std::vector<char>&b){std::ofstream f(std::string(argv[5])+"/"+name,std::ios::binary);if(!f.write(b.data(),b.size()))throw std::runtime_error("output write");};
 const std::string mode=argv[8];if(mode=="gold"){
  void*a{},*b{},*ma{},*mb{},*da{},*db{};api.Check(api.hipMalloc(&a,size_t(W)*H*8),"half gold");api.Check(api.hipMalloc(&b,size_t(W)*H*8),"half cache");for(auto p:{&ma,&mb})api.Check(api.hipMalloc(p,size_t(W)*H*32),"prefix main");for(auto p:{&da,&db})api.Check(api.hipMalloc(p,size_t(W)*H*8),"prefix down");
  for(U seed:{0u,1u,0xffffffffu}){net.PrefixNoiseHalfGold(a,seed);net.PrefixNoiseBuildProbe(b,seed);net.Synchronize();auto x=bytes(a,size_t(W)*H*8),y=bytes(b,x.size());if(x!=y)throw std::runtime_error("noise half-domain bits differ");size_t negative_zero=0;for(size_t j=0;j<x.size();j+=2){uint16_t h;memcpy(&h,x.data()+j,2);if((h&0x7c00)==0x7c00)throw std::runtime_error("nonfinite noise half");negative_zero+=h==0x8000;}
   printf("NOISE_HALF_GOLD seed=%u bytes=%zu bitdiff=0 negative_zero=%zu layout=raster_g1_g2_g0_pad\n",seed,x.size(),negative_zero);}
  for(bool temporal:{false,true})for(float exposure:{1.f,2.f})for(U epoch:{0u,1u}){
   net.PrefixNoiseExperiment(false,exposure,epoch);net.PrefixNoisePrefixProbe(in,temporal?in:nullptr,ma,da,0,false);net.Synchronize();
   net.PrefixNoiseExperiment(true,exposure,epoch);net.PrefixNoisePrefixProbe(in,temporal?in:nullptr,mb,db,0,true);net.Synchronize();
   if(bytes(ma,size_t(W)*H*32)!=bytes(mb,size_t(W)*H*32)||bytes(da,size_t(W)*H*8)!=bytes(db,size_t(W)*H*8))throw std::runtime_error("complete prefix main/down bitdiff");printf("PREFIX_GOLD temporal=%u exposure=%g reset_epoch=%u main_down_bitdiff=0\n",unsigned(temporal),exposure,epoch);
  }
  net.PrefixNoiseExperiment(true,1.f,1);net.PrefixNoisePrefixProbe(in,nullptr,ma,da,1,true);net.PrefixNoisePrefixProbe(in,nullptr,mb,db,1,false);net.Synchronize();if(bytes(ma,size_t(W)*H*32)!=bytes(mb,size_t(W)*H*32)||bytes(da,size_t(W)*H*8)!=bytes(db,size_t(W)*H*8))throw std::runtime_error("nonzero seed fallback bitdiff");
  net.PrefixNoiseReport();for(void*p:{a,b,ma,mb,da,db})api.hipFree(p);
 }else{
  if(mode!="0"&&mode!="1")throw std::runtime_error("mode");net.PrefixNoiseExperiment(mode=="1",1.f,0);for(unsigned i=0;i<80;i++){net.Enqueue(in,nullptr,out,0);net.Synchronize();}
  auto first=bytes(out,size_t(W)*H*12);auto finite=[&](const std::vector<char>&v){for(size_t i=0;i<v.size();i+=4){float x;memcpy(&x,v.data()+i,4);if(!std::isfinite(x))throw std::runtime_error("nonfinite network output");}};finite(first);save("first.rgb32f",first);Handle a{},b{};api.Check(api.hipEventCreate(&a),"event a");api.Check(api.hipEventCreate(&b),"event b");std::ofstream csv(std::string(argv[5])+"/timing.csv");csv<<"frame,gpu_ms,cpu_ms\n";double total=0;
  for(U i=0;i<frames;i++){auto begin=std::chrono::steady_clock::now();api.Check(api.hipEventRecord(a,stream),"start");net.Enqueue(in,nullptr,out,0);api.Check(api.hipEventRecord(b,stream),"end");net.Synchronize();float ms=0;api.Check(api.hipEventElapsedTime(&ms,a,b),"elapsed");if(!std::isfinite(ms)||ms<=0||ms>10000)throw std::runtime_error("bad events");total+=ms;double cpu=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count();csv<<i<<','<<ms<<','<<cpu<<'\n';}
  auto last=bytes(out,size_t(W)*H*12);finite(last);if(first!=last)throw std::runtime_error("frozen output changes inside slot");save("last.rgb32f",last);net.PrefixNoiseReport();printf("PREFIX_CACHE_NETWORK mode=%s W=%u H=%u frames=%u gpu_mean_ms=%.9f\n",mode.c_str(),W,H,frames,total/frames);api.hipEventDestroy(a);api.hipEventDestroy(b);
 }
 api.hipFree(in);api.hipFree(out);return 0;
}catch(const std::exception&e){fprintf(stderr,"PREFIX_CACHE_FAIL %s\n",e.what());return 1;}}
