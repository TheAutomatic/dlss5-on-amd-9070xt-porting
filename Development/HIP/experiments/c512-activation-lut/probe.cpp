#include "hip_api.h"
#include <cstdio>
#include <vector>
#include <fstream>
#include <chrono>
#include <cstring>
using hip_probe::Handle;
static Handle fn(hip_probe::Api&a,Handle m,const char*n){Handle f{};a.Check(a.hipModuleGetFunction(&f,m,n),n);return f;}
static std::vector<float> read(const char*p){std::ifstream f(p,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("weight missing");auto n=f.tellg();std::vector<float>v(size_t(n)/4);f.seekg(0);f.read((char*)v.data(),n);return v;}
int main(int argc,char**argv){try{
 if(argc!=4){fprintf(stderr,"probe baseline.hsaco candidate.hsaco block23-ffwd.f32\n");return 2;}
 hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle mods[2]{},kernels[2]{},stream{};
 a.Check(a.hipStreamCreate(&stream),"stream");for(int j=0;j<2;j++){a.Check(a.hipModuleLoad(&mods[j],argv[j+1]),"module");kernels[j]=fn(a,mods[j],"split_ffn_one_w2f8");}
 Handle prepare=fn(a,mods[1],"c512_activation_prepare");a.Check(a.hipModuleLaunchKernel(prepare,256,1,1,256,1,1,0,stream,nullptr,nullptr),"LUT prepare");a.Check(a.hipStreamSynchronize(stream),"LUT ready");
 void*dr{},*dl{};a.Check(a.hipMalloc(&dr,65536),"ref");a.Check(a.hipMalloc(&dl,65536),"lut");void*ca[]={&dr,&dl};a.Check(a.hipModuleLaunchKernel(fn(a,mods[1],"act_compare"),256,1,1,256,1,1,0,stream,ca,nullptr),"compare");a.Check(a.hipStreamSynchronize(stream),"compare sync");std::vector<unsigned char>r(65536),l(65536);a.Check(a.hipMemcpy(r.data(),dr,r.size(),2),"refread");a.Check(a.hipMemcpy(l.data(),dl,l.size(),2),"lutread");size_t bad=0,finitebad=0;for(unsigned h=0;h<65536;h++)if(r[h]!=l[h]){bad++;if((h&0x7c00)!=0x7c00)finitebad++;if(bad<12)printf("half_mismatch %04x %02x %02x\n",h,r[h],l[h]);}printf("ALL_HALF total=65536 mismatch=%zu finite_mismatch=%zu\n",bad,finitebad);FILE*f=fopen("activation-gpu-table.bin","wb");fwrite(r.data(),1,r.size(),f);fclose(f);if(bad)return 3;
 auto weights=read(argv[3]);if(weights.size()<524288)throw std::runtime_error("weightshape");void*dw{},*dp{};a.Check(a.hipMalloc(&dw,weights.size()*4),"weightfloat");a.Check(a.hipMalloc(&dp,weights.size()*4),"weightpacked");a.Check(a.hipMemcpy(dw,weights.data(),weights.size()*4,1),"weightupload");a.Check(a.hipMemsetAsync(dp,0,weights.size()*4,stream),"weightclear");void*pa[]={&dw,&dp};a.Check(a.hipModuleLaunchKernel(fn(a,mods[1],"fp8_pack_weights"),2048,1,1,256,1,1,0,stream,pa,nullptr),"weightpack");a.Check(a.hipStreamSynchronize(stream),"packedready");
 for(unsigned tokens:{1792u,2240u}){
  std::vector<float>x(size_t(tokens)*512);for(size_t i=0;i<x.size();i++)x[i]=float(int((i*131u+i/512*17u)%33u)-16)*.25f;
  void*dx{},*dout{};a.Check(a.hipMalloc(&dx,x.size()*4),"input");a.Check(a.hipMalloc(&dout,size_t(tokens)*512),"out");a.Check(a.hipMemcpy(dx,x.data(),x.size()*4,1),"inputupload");void*args[]={&dx,&dp,&dout,&tokens};auto run=[&](int j){a.Check(a.hipModuleLaunchKernel(kernels[j],(tokens+31)/32*8,1,1,64,1,1,0,stream,args,nullptr),"ffn");};
  std::vector<unsigned char>outs[2];for(int j=0;j<2;j++){run(j);a.Check(a.hipStreamSynchronize(stream),"outready");outs[j].resize(size_t(tokens)*512);a.Check(a.hipMemcpy(outs[j].data(),dout,outs[j].size(),2),"outread");}size_t diff=0;for(size_t i=0;i<outs[0].size();i++)diff+=outs[0][i]!=outs[1][i];printf("FFN tokens=%u byte_diff=%zu bytes=%zu\n",tokens,diff,outs[0].size());if(diff)return 4;
  for(int warm=0;warm<20;warm++){for(int j:{0,1}){for(int q=0;q<100;q++)run(j);a.Check(a.hipStreamSynchronize(stream),"steady warm");}}
  for(int round=0;round<3;round++)for(int j:{0,1,1,0}){for(int q=0;q<50;q++)run(j);a.Check(a.hipStreamSynchronize(stream),"warm");Handle start{},end{};a.Check(a.hipEventCreate(&start),"start");a.Check(a.hipEventCreate(&end),"end");const int repeats=600;auto t=std::chrono::steady_clock::now();a.Check(a.hipEventRecord(start,stream),"startrecord");for(int q=0;q<repeats;q++)run(j);a.Check(a.hipEventRecord(end,stream),"endrecord");a.Check(a.hipEventSynchronize(end),"endready");float ms=0;a.Check(a.hipEventElapsedTime(&ms,start,end),"elapsed");double wall=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-t).count();printf("TIME tokens=%u round=%d variant=%d n=%d event_ms=%.6f wall_ms=%.6f per_event_us=%.6f per_wall_us=%.6f\n",tokens,round,j,repeats,ms,wall,ms*1000/repeats,wall*1000/repeats);if(!(ms>0&&wall>0))return 5;a.hipEventDestroy(start);a.hipEventDestroy(end);}
  a.hipFree(dx);a.hipFree(dout);
 }
 return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 2;}}
