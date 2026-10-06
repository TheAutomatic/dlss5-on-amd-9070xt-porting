#include "hip_reference_network.h"
#include "production_options.generated.h"
#include <fstream>
using namespace hip_reference;
static std::vector<char> read(const char*p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("input");std::vector<char>b(size_t(f.tellg()));f.seekg(0);f.read(b.data(),b.size());return b;}
static void flags(const char*p){std::ifstream f(p);std::string s;while(std::getline(f,s)){auto q=s.find('=');if(q==s.npos||s.empty()||s[0]=='#')continue;auto k=s.substr(0,q),v=s.substr(q+1);if(!v.empty()&&v.back()=='\r')v.pop_back();if(k.rfind("DLSS5_",0)==0)_putenv_s(k.c_str(),v.c_str());}}
int main(int argc,char**argv){try{if(argc!=7)throw std::runtime_error("gold ASSETS STOCKMODULES FLAGS PROCESSING NEWMODULE OUTDIR");flags(argv[3]);auto op=production_options(argv[1],argv[2],1920,1088,false);op.submit_pulse=0;op.experimental_temporal=false;op.graph=false;op.profile=false;op.wall_profile=false;op.skip_blocks.clear();Network net(op);net.SetNoise({});auto&a=net.Runtime();auto stream=net.Stream();auto v=read(argv[4]);if(v.size()!=1920ull*1088*16)throw std::runtime_error("encoded input footprint");void *input{},*output{},*savedLow{},*savedSkip{},*bodyMain{},*bodyTrace{},*upTap{};
 a.Check(a.hipMalloc(&input,v.size()),"input");a.Check(a.hipMemcpy(input,v.data(),v.size(),1),"upload");a.Check(a.hipMalloc(&output,1920ull*1088*12),"out");
 a.Check(a.hipMalloc(&savedLow,60ull*34*512*4),"saved low physicalF32");a.Check(a.hipMalloc(&savedSkip,120ull*68*256*4),"saved skip F32");
 for(void**p:{&bodyMain,&bodyTrace,&upTap})a.Check(a.hipMalloc(p,120ull*68*256),"shadow bytes");Handle module{},fn{},trace{};a.Check(a.LoadModule(&module,argv[5]),"candidate module");
 a.Check(a.hipModuleGetFunction(&fn,module,"c256_up48_body48_bi_bo_w16_local"),"sole main export");a.Check(a.hipModuleGetFunction(&trace,module,"c256_up48_body48_bi_bo_w16_local_trace"),"separate diagnostic tap export");
 auto dump=[&](void*p,size_t n,const char*name){std::vector<char>b(n);a.Check(a.hipMemcpy(b.data(),p,n,2),"read necessary gold");std::ofstream(std::string(argv[6])+"/"+name,std::ios::binary).write(b.data(),b.size());return b;};
 auto ptr=[](void**p,unsigned i){void*v{};std::memcpy(&v,p[i],sizeof(v));return v;};auto u=[](void**p,unsigned i){U v{};std::memcpy(&v,p[i],4);return v;};void *uw{},*upRef{};bool up=false,done=false;std::vector<char>upBytes;
 net.DiagnosticDownHook([&](const char*name,void**p,unsigned n){
  if(std::string(name)=="decoder_project2x_h16w_byteout_w"&&n==10){
   if(up||u(p,4)!=60||u(p,5)!=34||u(p,6)!=120||u(p,7)!=68||u(p,8)!=512||u(p,9)!=256)throw std::runtime_error("actual Up ABI/shape");
   uw=ptr(p,1);upRef=ptr(p,3);a.Check(a.hipMemcpyAsync(savedLow,ptr(p,0),60ull*34*512*4,3,stream),"snapshot low before allocator reuse");a.Check(a.hipMemcpyAsync(savedSkip,ptr(p,2),120ull*68*256*4,3,stream),"snapshot rawskip3 before reuse");net.Synchronize();
   dump(savedLow,60ull*34*512*4,"low-input.f32");dump(savedSkip,120ull*68*256*4,"skip3.f32");dump(uw,net.DiagnosticWeightBytes(uw),"up-weights.bin");upBytes=dump(upRef,120ull*68*256,"reference-up.fp8");up=true;
  }
  if(up&&!done&&std::string(name)=="c256_wave2_bi_bo_w16"&&n==11&&ptr(p,0)==upRef){
   if(u(p,4)!=120||u(p,5)!=68||u(p,6)!=120||u(p,7)!=72||u(p,8)||u(p,9)||u(p,10)!=0)throw std::runtime_error("actual Body48 post0/shape");
   net.Synchronize();auto ref=dump(ptr(p,3),120ull*68*256,"reference-body.fp8");void*fw=ptr(p,1),*aw=ptr(p,2);dump(fw,net.DiagnosticWeightBytes(fw),"body-fw.bin");dump(aw,net.DiagnosticWeightBytes(aw),"body-aw.bin");U w=120,h=68,ww=120,hh=72,sx=0,sy=0,post=u(p,10);
   void*args[]={&savedLow,&fw,&aw,&bodyMain,&w,&h,&ww,&hh,&sx,&sy,&post,&uw,&savedSkip};a.Check(a.hipModuleLaunchKernel(fn,135,1,1,256,1,1,0,stream,args,nullptr),"main new-only shadow");
   void*ta[]={&savedLow,&fw,&aw,&bodyTrace,&w,&h,&ww,&hh,&sx,&sy,&post,&uw,&savedSkip,&upTap};a.Check(a.hipModuleLaunchKernel(trace,135,1,1,256,1,1,0,stream,ta,nullptr),"separate trace shadow");net.Synchronize();
   auto bm=dump(bodyMain,ref.size(),"candidate-body.fp8"),bt=dump(bodyTrace,ref.size(),"trace-body.fp8"),ut=dump(upTap,upBytes.size(),"trace-up.fp8");size_t md=0,td=0,ud=0;for(size_t i=0;i<ref.size();i++){md+=ref[i]!=bm[i];td+=ref[i]!=bt[i];ud+=upBytes[i]!=ut[i];}
   printf("UP48_BODY48_GOLD main_body_byte_diff=%zu trace_body_byte_diff=%zu trace_up_byte_diff=%zu actual_post=%u low_physical_f32=1 snapshots_owned=1 new_main_userargs=13 new_trace_userargs=14 timing=none\n",md,td,ud,post);if(md||td||ud)throw std::runtime_error("actual Up/Body byte gold differs");done=true;
  }
 });
 net.Enqueue(input,nullptr,output,0);net.Synchronize();if(!done)throw std::runtime_error("eligible path never hit");dump(output,1920ull*1088*12,"whole-stock.rgb32f");net.DiagnosticDownHook({});a.hipModuleUnload(module);a.hipFree(upTap);a.hipFree(bodyTrace);a.hipFree(bodyMain);a.hipFree(savedSkip);a.hipFree(savedLow);a.hipFree(output);a.hipFree(input);return 0;}catch(const std::exception&e){std::fprintf(stderr,"UP48_BODY48_FAIL %s\n",e.what());return 1;}}
