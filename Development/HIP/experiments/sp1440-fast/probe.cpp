#define DLSS5_LAYER_BENCH 1
#define HIP_SWIN_PERSISTENT_DIAGNOSTICS 1
#include "hip_reference_network.h"
#include <cstring>
namespace hip_reference { struct LayerBenchmark {
static bool Check(Network&n,const char*wave,const char*sp){
 Handle wm{},sm{};n.api.Check(n.api.hipModuleLoad(&wm,wave),"wave module");n.api.Check(n.api.hipModuleLoad(&sm,sp),"SP fast module");n.modules["c64_wave2"]=wm;n.modules["sp"]=sm;
 constexpr U w=160,h=92,c=256;const size_t bytes=size_t(w)*h*c;
 for(U first:{16u,49u}){
 auto &plan=n.SpGetPlan(w,h,c,first,6);if(!plan.w16)throw std::runtime_error("SP and baseline require C256 W16 pair");
 std::vector<unsigned char>v(bytes);for(size_t i=0;i<bytes;i++){U q=(i*131+i/c*17+first*7)%127;v[i]=static_cast<unsigned char>(q|((i&1)<<7));}
 auto input=n.Upload(v.data(),v.size());std::vector<Tensor> outs; // separate baseline layers: no alias
 auto src=input;
 for(auto &l:plan.layers){auto out=n.New(bytes/4);n.Run("c64_wave2","c256_wave2_bi_bo_w16",(l.ww/8)*(l.hh/8),n.P(src),l.fw,l.aw,n.P(out),l.w,l.h,l.ww,l.hh,l.sx,l.sy,l.post);outs.push_back(out);src=out;}
 n.Synchronize();std::vector<unsigned char>base(bytes),next(bytes);n.api.Check(n.api.hipMemcpy(base.data(),n.P(src),bytes,2),"baseline read");
 for(U mode:{0u,1u,2u}){
  _putenv_s("SP_FORCE_TIMEOUT",mode==1?"1":"0");_putenv_s("SP_TICKET_LIMIT",mode==2?"1488":"4294967295");
  auto candidate=n.SpStage(input,w,h,c,first,6);n.Synchronize();n.api.Check(n.api.hipMemcpy(next.data(),n.P(candidate),bytes,2),"candidate read");size_t diff=0;for(size_t i=0;i<bytes;i++)diff+=base[i]!=next[i];printf("SP_PAIR first=%u mode=%u tasks=%u initial=%u byte_diff=%zu\n",first,mode,plan.total,plan.first,diff);if(diff)return false;
 }
 }
 printf("SP_GATE runs=%llu recovery=%u rollover=%llu\n",n.sp_runs,unsigned(n.sp_error_host[1].load()),n.sp_rollovers);return n.sp_error_host[1].load()==2 && n.sp_rollovers>=2;
}
};}
int main(int argc,char**argv){try{if(argc!=5)throw std::runtime_error("probe ASSETS MODULES C64_FAST SP_FAST");hip_reference::Options o;o.width=2560;o.height=1472;o.assets=argv[1];o.modules=argv[2];o.fast_mh=o.mh_wave=o.packed_weights=o.pooled=true;hip_reference::Network n(o);return hip_reference::LayerBenchmark::Check(n,argv[3],argv[4])?0:1;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
