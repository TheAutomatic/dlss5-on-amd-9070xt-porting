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
 const U w=1920,h=std::stoul(argv[8]),valid=1080,warm=std::stoul(argv[6]),measured=std::stoul(argv[7]);if((h!=1088&&h!=1152)||!warm||!measured||measured>4000)throw std::runtime_error("bounded sample count");
 for(const char*k:{"DLSS5_MULTI_PASS_PREDICT","DLSS5_MULTI_PASS_SKIN_PROTECT","DLSS5_HIP_GRAPH","DLSS5_OVERLAP","DLSS5_VIT_ADAPTIVE","DLSS5_VIT_REUSE_HOTKEY","DLSS5_TEMPORAL_HISTORY_EXPERIMENT","DLSS5_TEMPORAL_MV_UNJITTERED"})_putenv_s(k,"0");_putenv_s("DLSS5_MULTI_PASS","1");_putenv_s("DLSS5_STYLE","1");_putenv_s("DLSS5_SKIP_BLOCKS","");
 auto input=read(argv[4]);if(input.size()!=size_t(w)*h*16)throw std::runtime_error("input footprint");auto opt=production_options(argv[1],argv[2],w,h,false);opt.experimental_temporal=false;opt.profile=false;opt.skip_blocks.clear();opt.graph=false;opt.pdl=false;opt.wall_profile=false;opt.submit_pulse=0;if(!opt.wave_owned||!opt.c512_m32||opt.vit_stream!=3||!opt.swin_run)throw std::runtime_error("production profile missing");printf("SYNC_PROFILE wave_owned=%u c512_m32=%u pdl=%u vit_stream=%u swin_run=%u FAST=%s full71=%u\n",unsigned(opt.wave_owned),unsigned(opt.c512_m32),unsigned(opt.pdl),opt.vit_stream,unsigned(opt.swin_run),std::getenv("DLSS5_FAST_NUMERIC"),unsigned(opt.skip_blocks.empty()));Network net(opt);net.SetNoise({});auto&api=net.Runtime();auto stream=net.Stream();void*in{},*out{};api.Check(api.hipMalloc(&in,input.size()),"allocate input");api.Check(api.hipMalloc(&out,size_t(w)*h*12),"allocate output");api.Check(api.hipMemcpy(in,input.data(),input.size(),1),"upload input once");
 auto run=[&](){net.Enqueue(in,nullptr,out,0);net.Synchronize();};
 auto download=[&](const char*name){std::vector<float>v(size_t(w)*h*3);api.Check(api.hipMemcpy(v.data(),out,v.size()*4,2),"read output");for(float x:v)if(!std::isfinite(x))throw std::runtime_error("nonfinite output");std::ofstream f(std::string(argv[5])+"/"+name,std::ios::binary);if(!f.write(reinterpret_cast<char*>(v.data()),v.size()*4))throw std::runtime_error("output write");return v;};
 run();auto first=download("first.rgb32f");for(U i=0;i<warm;i++)run();
 api.EnableGraphs();using Nodes=int(*)(Handle,Handle*,size_t*);using Type=int(*)(Handle,int*);Nodes getnodes{};Type gettype{};api.Load(getnodes,"hipGraphGetNodes");api.Load(gettype,"hipGraphNodeGetType");
 Handle graph{},exec{};net.Synchronize();api.Check(api.hipStreamBeginCapture(stream,1),"external graph0 begin");net.LabCapturePoolGuard(true);
 try{net.Enqueue(in,nullptr,out,0);net.LabCapturePoolGuard(false);api.Check(api.hipStreamEndCapture(stream,&graph),"external graph0 end");}catch(...){net.LabCapturePoolGuard(false);Handle abandoned{};api.hipStreamEndCapture(stream,&abandoned);if(abandoned)api.hipGraphDestroy(abandoned);throw;}
 size_t n=0;api.Check(getnodes(graph,nullptr,&n),"node count");std::vector<Handle>nodes(n);api.Check(getnodes(graph,nodes.data(),&n),"node list");for(size_t i=0;i<n;i++){int type=-1;api.Check(gettype(nodes[i],&type),"node type");printf("CAPTURE_NODE index=%zu type=%d\n",i,type);}printf("CAPTURE_NODES=%zu opt_graph=0 PDL=0\n",n);
 api.Check(api.hipGraphDestroy(graph),"destroy unaudited graph");throw std::runtime_error("CPU prototype: node semantics gate pending; replay prohibited");
 api.Check(api.hipGraphInstantiate(&exec,graph,nullptr,nullptr,0),"instantiate");for(U i=0;i<2;i++){api.Check(api.hipGraphLaunch(exec,stream),"replay");net.Synchronize();auto v=download(i?"last.rgb32f":"replay0.rgb32f");if(v.size()!=first.size()||memcmp(v.data(),first.data(),v.size()*4))throw std::runtime_error("graph0 repeat raw mismatch");}
 api.Check(api.hipGraphExecDestroy(exec),"destroy exec");api.Check(api.hipGraphDestroy(graph),"destroy graph");printf("GRAPH0_SAMEWORK_RAW_PASS no_performance=1\n");

 api.hipFree(in);api.hipFree(out);return 0;
}catch(const std::exception&e){fprintf(stderr,"SYNC_NETWORK_FAIL %s\n",e.what());return 1;}}
