// Standalone MP1 temporal experiment. No game files or production flags are written.
#include "hip_reference_network.h"
#include "production_options.generated.h"
#include <fstream>
#include <cstdio>
#include <chrono>
#include <memory>
using namespace hip_reference;
static std::vector<char> read(const std::string&p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("read "+p);std::vector<char>b(size_t(f.tellg()));f.seekg(0);if(!f.read(b.data(),b.size()))throw std::runtime_error("short "+p);return b;}
static void flags(const char*p){std::ifstream f(p);if(!f)throw std::runtime_error("flags missing");std::string s;while(std::getline(f,s)){if(s.empty()||s[0]=='#'||s[0]==';')continue;auto eq=s.find('=');if(eq==std::string::npos)continue;auto k=s.substr(0,eq),v=s.substr(eq+1);while(!v.empty()&&(v.back()=='\r'||v.back()==' '))v.pop_back();if(k.rfind("DLSS5_",0)==0)_putenv_s(k.c_str(),v.c_str());}}
struct Buffers{
 Api&a;Handle stream;std::vector<void*>ptr;
 void*allocate(size_t n){void*p; a.Check(a.hipMalloc(&p,n),"sequence alloc");ptr.push_back(p);return p;}
 void*load(const std::vector<char>&b){auto*p=allocate(b.size());a.Check(a.hipMemcpy(p,b.data(),b.size(),1),"sequence upload");return p;}
 ~Buffers(){a.hipStreamSynchronize(stream);for(auto p:ptr)a.hipFree(p);}
};
static void launch(Api&a,Handle stream,Handle fn,unsigned count,void**args){a.Check(a.hipModuleLaunchKernel(fn,(count+255)/256,1,1,256,1,1,0,stream,args,nullptr),"sequence kernel");}
int main(int argc,char**argv){try{
 if(argc!=8&&argc!=9)throw std::runtime_error("sequence ASSETS MODULES FLAGS WARP_HSACO GATE_HSACO NV_SIG_F32 OUTPUT_DIR");
 flags(argv[3]);_putenv_s("DLSS5_MULTI_PASS","1");_putenv_s("DLSS5_MULTI_PASS_PREDICT","0");_putenv_s("DLSS5_MULTI_PASS_SKIN_PROTECT","0");_putenv_s("DLSS5_FAST_NUMERIC","1");_putenv_s("DLSS5_STYLE","1");_putenv_s("DLSS5_HIP_GRAPH","0");_putenv_s("DLSS5_VIT_ADAPTIVE","0");_putenv_s("DLSS5_VIT_REUSE_HOTKEY","0");
 std::ofstream csv(std::string(argv[7])+"/sequence.csv");csv<<"route,seed_mode,frame,width,valid_h,proc_h,reset,mv_valid,use_history,seed,background_Y,object_Y,nonfinite,diagnostic_wall_ms,baseline_byte_diff,repeat_byte_diff\n";
 const float blend=.73974609375f;
 for(unsigned seedmode=0;seedmode<2;seedmode++)for(unsigned route=0;route<3;route++){
  const bool large=argc==9;unsigned W=large?1920:512,H=large?1152:512,VH=large?1080:512,epochseed=0;bool ready=false;unsigned write=0;
  std::unique_ptr<Network> net,plainnet;std::unique_ptr<Buffers> mem;Handle warpmod{},gatemod{},warp{},store{},head{},resolve{};
  void *input{},*motion{},*history[2]{},*prefix{},*raw{},*rgb{},*final{},*logit{},*weight{},*sig{},*recip{};
  auto create=[&](){net.reset(new Network(production_options(argv[1],argv[2],W,H,true)));net->SetNoise({});plainnet.reset(new Network(production_options(argv[1],argv[2],W,H,false)));plainnet->SetNoise({});auto&a=net->Runtime();auto stream=net->Stream();mem.reset(new Buffers{a,stream,{}});
   a.Check(a.LoadModule(&warpmod,argv[4]),"warp module");a.Check(a.LoadModule(&gatemod,argv[5]),"gate module");
   auto function=[&](Handle m,const char*n){Handle f;a.Check(a.hipModuleGetFunction(&f,m,n),n);return f;};warp=function(warpmod,"temporal_warp");store=function(warpmod,"temporal_store");head=function(gatemod,"hip_gate_head");resolve=function(gatemod,"hip_gate_resolve");
   input=mem->allocate(size_t(W)*H*16);motion=mem->allocate(size_t(W)*VH*8);for(auto&v:history)v=mem->allocate(size_t(W)*VH*16);prefix=mem->allocate(size_t(W)*H*16);raw=mem->allocate(size_t(W)*H*16);rgb=mem->allocate(size_t(W)*H*12);final=mem->allocate(size_t(W)*H*12);logit=mem->allocate(size_t(W)*H*2);
   weight=mem->load(read(std::string(argv[7])+"/post70-history-head.f16"));sig=mem->load(read(argv[6]));recip=mem->load(read(std::string(argv[1])+"/normalized-output.f32"));
   ready=false;write=0;epochseed=0;};
  auto destroy=[&](){if(!net)return;net->Synchronize();auto&a=net->Runtime();a.hipModuleUnload(warpmod);a.hipModuleUnload(gatemod);mem.reset();plainnet.reset();net.reset();};
  create();
  for(unsigned frame=0;frame<(large?3:8);frame++){
   if(frame==6){destroy();W=640;VH=360;H=384;create();}
   bool reset=frame==0||frame==4||frame==6,mvvalid=frame!=5;if(reset){ready=false;epochseed=0;}
   bool use=route!=0&&ready&&mvvalid&&!reset;unsigned seed=seedmode?epochseed:0;
   std::vector<float>x(size_t(W)*H*4),mv(size_t(W)*VH*2);unsigned offset=frame<2?0:frame<4?frame-1:frame==4?2:frame==5?3:frame-6;
   for(unsigned y=0;y<H;y++)for(unsigned xx=0;xx<W;xx++){unsigned yy=y<VH?y:2*VH-y-2,p=(y*W+xx)*4;bool obj=xx>=W/3+offset&&xx<W/3+offset+32&&yy>=VH/3&&yy<VH/3+32;
    float c=obj?.6f:.25f+.03125f*float((xx/16+yy/16)%2);x[p]=float((_Float16)c);x[p+1]=float((_Float16)(c+.0625f));x[p+2]=float((_Float16)(c+.125f));x[p+3]=1;
    if(y<VH&&obj&&(frame==2||frame==3||frame==5||frame==7))mv[(y*W+xx)*2]=-1;
   }
   auto&a=net->Runtime();auto stream=net->Stream();a.Check(a.hipMemcpy(input,x.data(),x.size()*4,1),"input");a.Check(a.hipMemcpy(motion,mv.data(),mv.size()*4,1),"motion");
   auto start=std::chrono::steady_clock::now();
   if(use){void*previous=history[write^1];void*args[]={&previous,&motion,&prefix,&raw,&recip,&W,&VH,&H};launch(a,stream,warp,W*H,args);}
   net->Enqueue(input,use?prefix:nullptr,rgb,seed);
   bool full=route==2&&use;unsigned enabled=full?1:0,count=full?W*VH:W*H;
   if(full)a.Check(a.hipMemcpyAsync(final,rgb,size_t(W)*H*12,3,stream),"preserve post padding");
   if(full){void*features=net->TemporalFeatureBuffer();void*ha[]={&features,&weight,&logit,&count};launch(a,stream,head,count,ha);}
   void*ga[]={&rgb,&raw,&logit,&sig,&final,&count,const_cast<float*>(&blend),&enabled};launch(a,stream,resolve,count,ga);
   void*dst=history[write];void*sa[]={&final,&dst,&W,&VH};launch(a,stream,store,W*VH,sa);net->Synchronize();
   double wall=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
   std::vector<float>out(size_t(W)*H*3);a.Check(a.hipMemcpy(out.data(),final,out.size()*4,2),"result");size_t bad=0;double bg=0,object=0;for(float v:out)bad+=!std::isfinite(v);
   auto mean=[&](unsigned ox,unsigned oy){double sum=0;for(unsigned y=oy;y<oy+16;y++)for(unsigned xx=ox;xx<ox+16;xx++){size_t p=(y*W+xx)*3;sum+=.299*out[p]+.587*out[p+1]+.114*out[p+2];}return sum/256;};bg=mean(W/2,VH/4);object=mean(W/3+offset+8,VH/3+8);
   size_t difference=0;
   if(!use){plainnet->Enqueue(input,nullptr,rgb,seed);plainnet->Synchronize();std::vector<float>plain(out.size());a.Check(a.hipMemcpy(plain.data(),rgb,plain.size()*4,2),"baseline result");for(size_t b=0;b<out.size()*4;b++)difference+=reinterpret_cast<unsigned char*>(out.data())[b]!=reinterpret_cast<unsigned char*>(plain.data())[b];}
   size_t repeat_difference=0;
   if(use){
    net->Enqueue(input,prefix,rgb,seed);
    if(full){a.Check(a.hipMemcpyAsync(final,rgb,size_t(W)*H*12,3,stream),"repeat padding");void*features=net->TemporalFeatureBuffer();void*ha[]={&features,&weight,&logit,&count};launch(a,stream,head,count,ha);}
    launch(a,stream,resolve,count,ga);net->Synchronize();std::vector<float>repeated(out.size());a.Check(a.hipMemcpy(repeated.data(),final,repeated.size()*4,2),"repeat result");for(size_t b=0;b<out.size()*4;b++)repeat_difference+=reinterpret_cast<unsigned char*>(out.data())[b]!=reinterpret_cast<unsigned char*>(repeated.data())[b];
   }
   csv<<route<<','<<seedmode<<','<<frame<<','<<W<<','<<VH<<','<<H<<','<<reset<<','<<mvvalid<<','<<use<<','<<seed<<','<<bg<<','<<object<<','<<bad<<','<<wall<<','<<difference<<','<<repeat_difference<<'\n';csv.flush();
   if(bad||difference||repeat_difference)throw std::runtime_error("Nonfinite or first/reset/off default mismatch");ready=true;write^=1;epochseed++;
  }
  destroy();
 }
 printf("SEQUENCE_PASS routes3 seeds2: diagnostic synthetic only; not video reproduction or timing benchmark\n");return 0;
}catch(const std::exception&e){fprintf(stderr,"sequence FAIL %s\n",e.what());return 1;}}
