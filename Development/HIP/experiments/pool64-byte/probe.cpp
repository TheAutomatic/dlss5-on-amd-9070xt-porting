#define DLSS5_LAYER_BENCH 1
#include "hip_reference_network.h"
#include <cstring>
namespace hip_reference { struct LayerBenchmark {
static bool Check(Network&n,const char*wave){
 Handle mod{};n.api.Check(n.api.hipModuleLoad(&mod,wave),"wave module");n.modules["c64_wave2"]=mod;
 auto old=n.New(65536),next=n.New(65536);
 auto launch=[&](const char*name,U groups,U threads,void**args){Handle f{};n.api.Check(n.api.hipModuleGetFunction(&f,n.modules["mh_fast"],name),name);n.api.Check(n.api.hipModuleLaunchKernel(f,groups,1,1,threads,1,1,0,n.stream,args,nullptr),name);};
 void*po=n.P(old),*pn=n.P(next);void*proofargs[]={&po,&pn};launch("pool64_half_proof",256,256,proofargs);n.Synchronize();
 std::vector<unsigned>a(65536),b(65536);n.api.Check(n.api.hipMemcpy(a.data(),n.P(old),a.size()*4,2),"proof old");n.api.Check(n.api.hipMemcpy(b.data(),n.P(next),b.size()*4,2),"proof new");size_t diff=0;for(size_t i=0;i<a.size();i++)diff+=a[i]!=b[i];printf("HALF_PROOF codes=65536 bitdiff=%zu\n",diff);if(diff)return false;
 for(auto g:{std::pair<U,U>{400,240},{480,288},{640,368},{17,19}})for(U pattern=0;pattern<3;pattern++){
 U w=g.first,h=g.second,c=32,M=w*h,sx=0,sy=0,ww=(w+7)&~7u,hh=(h+7)&~7u,post=4;
 std::vector<unsigned char>input(size_t(M)*32);for(size_t i=0;i<input.size();i++){unsigned x=(i*131+i/32*17+pattern*71)%127;input[i]=static_cast<unsigned char>((pattern==0?x:pattern==1?x%8:x%33+24)|((i&1)<<7));}
 auto x=n.Upload(input.data(),input.size()),f=n.New(size_t(M)*64),bytes=n.New(size_t(M)*16),fo=n.New(size_t(M)*16),bo=n.New(size_t(M)*16);
 void*px0=n.P(x),*pw0=n.PackedDsWeightCast("block4-ds.f32",32),*pf=n.P(f);U z0=0;void*baseargs[]={&px0,&pw0,&pf,&w,&h,&z0,&z0,&c};launch("mh_pool_project_c32_b8",((M+15)/16)*4,32,baseargs);
 void*px=n.P(x),*pw=n.PackedDsWeightCast("block4-ds.f32",32),*pb=n.P(bytes);U zero=0;void*poolargs[]={&px,&pw,&pb,&w,&h,&zero,&zero,&c};launch("mh_pool_project_c32_b8_out8",((M+15)/16)*4,32,poolargs);
 auto fw=n.PackedFusedMhWeightFrag("block5-ffn.f32",64),aw=n.WaveOwnedAttentionWeight("block5-attention.f32",64);
 n.Run("c64_wave2","c64_wave2_bo",ww*hh/64,n.P(f),fw,aw,n.P(fo),w,h,ww,hh,sx,sy,post);
 n.Run("c64_wave2","c64_wave2_bi_bo",ww*hh/64,n.P(bytes),fw,aw,n.P(bo),w,h,ww,hh,sx,sy,post);n.Synchronize();
 std::vector<unsigned char>oa(size_t(M)*64),ob(oa.size());n.api.Check(n.api.hipMemcpy(oa.data(),n.P(fo),oa.size(),2),"pair old");n.api.Check(n.api.hipMemcpy(ob.data(),n.P(bo),ob.size(),2),"pair new");diff=0;for(size_t i=0;i<oa.size();i++)diff+=oa[i]!=ob[i];printf("PAIR %ux%u pattern=%u byte_diff=%zu\n",w,h,pattern,diff);if(diff)return false;
 }
 return true;
}};}
int main(int argc,char**argv){try{if(argc!=4)throw std::runtime_error("probe ASSETS MODULES C64_WAVE_MODULE");hip_reference::Options o;o.assets=argv[1];o.modules=argv[2];o.fast_mh=o.mh_wave=o.packed_weights=o.pooled=true;hip_reference::Network n(o);return hip_reference::LayerBenchmark::Check(n,argv[3])?0:1;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
