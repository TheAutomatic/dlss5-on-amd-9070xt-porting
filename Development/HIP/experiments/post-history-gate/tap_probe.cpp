#define DLSS5_LAYER_BENCH 1
#include "hip_reference_network.h"
#include <cstring>
#include <fstream>
namespace hip_reference {struct LayerBenchmark{
static bool Check(Network&n,const char*module,const char*dir){
 Handle m{};n.api.Check(n.api.hipModuleLoad(&m,module),"tap module");Handle oldfn{},newfn{};n.api.Check(n.api.hipModuleGetFunction(&oldfn,m,"c32_wave1_post_b8"),"old post");n.api.Check(n.api.hipModuleGetFunction(&newfn,m,"c32_wave1_post_b8_features"),"new post");
 auto fw=n.PackedC32Weight("post70-ffn.f32",false),aw=n.PackedC32Weight("post70-attention.f32",true),sc=n.Weight("post70-scales.f32"),head=n.Weight("post70-head.f32");
 for(auto wh:{std::pair<U,U>{32,32},{64,48}})for(U shift:{0u,4u})for(U pattern=0;pattern<3;pattern++){
 U w=wh.first,h=wh.second,sx=shift,sy=shift,windows=(w+2*sx)*(h+2*sy)/64;float scale=.03125f;size_t pixels=size_t(w)*h;
 std::vector<unsigned char>lv(pixels/4*32),sv(pixels*32);for(size_t i=0;i<sv.size();i++){unsigned q=(i*131+i/32*17+pattern*71)%127;sv[i]=pattern==2?0:static_cast<unsigned char>((pattern? q:q%32+16)|((i&1)<<7));}for(size_t i=0;i<lv.size();i++)lv[i]=sv[i*4];
 std::vector<float>color(pixels*4);for(size_t i=0;i<pixels;i++){color[i*4]=float(i%29)/29;color[i*4+1]=.4f;color[i*4+2]=.7f;color[i*4+3]=1;}
 auto l=n.Upload(lv.data(),lv.size()),s=n.Upload(sv.data(),sv.size()),c=n.Upload(color.data(),color.size()*4),a=n.New(pixels*3),b=n.New(pixels*3);std::vector<unsigned short>sentinel(pixels*32,0xffff);auto f=n.Upload(sentinel.data(),sentinel.size()*2);
 void*pl=n.P(l),*ps=n.P(s),*pc=n.P(c),*pa=n.P(a),*pb=n.P(b),*pf=n.P(f);void*oa[]={&pl,&ps,&sc,&fw,&aw,&pc,&head,&pa,&windows,&w,&h,&sx,&sy,&scale};void*na[]={&pl,&ps,&sc,&fw,&aw,&pc,&head,&pb,&windows,&w,&h,&sx,&sy,&scale,&pf};
 n.api.Check(n.api.hipModuleLaunchKernel(oldfn,windows,1,1,32,1,1,0,n.stream,oa,nullptr),"old launch");n.api.Check(n.api.hipModuleLaunchKernel(newfn,windows,1,1,32,1,1,0,n.stream,na,nullptr),"tap launch");n.Synchronize();
 std::vector<float>va(pixels*3),vb(va.size());n.api.Check(n.api.hipMemcpy(va.data(),pa,va.size()*4,2),"old read");n.api.Check(n.api.hipMemcpy(vb.data(),pb,vb.size()*4,2),"tap read");n.api.Check(n.api.hipMemcpy(sentinel.data(),pf,sentinel.size()*2,2),"features read");size_t diff=0,nf=0;for(size_t i=0;i<va.size();i++)diff+=memcmp(&va[i],&vb[i],4)!=0;for(auto v:sentinel)nf+=((v>>10)&31)==31;printf("TAP %ux%u shift=%u pattern=%u RGB_bitdiff=%zu feature_nonfinite=%zu half_count=%zu\n",w,h,shift,pattern,diff,nf,sentinel.size());if(diff||nf)return false;
 char path[1024];snprintf(path,sizeof path,"%s/features-%ux%u-s%u-p%u.f16",dir,w,h,shift,pattern);std::ofstream out(path,std::ios::binary);out.write((const char*)sentinel.data(),sentinel.size()*2);if(!out)throw std::runtime_error("feature output");
 }
 return true;
}};}
int main(int argc,char**argv){try{if(argc!=5)throw std::runtime_error("tap_probe ASSETS MODULES TAP_MODULE OUTPUT_DIR");hip_reference::Options o;o.assets=argv[1];o.modules=argv[2];o.packed_weights=o.pooled=true;hip_reference::Network n(o);return hip_reference::LayerBenchmark::Check(n,argv[3],argv[4])?0:1;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
