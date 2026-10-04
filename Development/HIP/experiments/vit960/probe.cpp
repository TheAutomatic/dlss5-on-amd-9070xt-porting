#include "hip_api.h"
#include <cstdio>
#include <vector>
#include <chrono>
using hip_probe::Handle;
static Handle fn(hip_probe::Api&a,Handle m,const char*n){Handle f{};a.Check(a.hipModuleGetFunction(&f,m,n),n);return f;}
int main(int argc,char**argv){try{
 if(argc!=4){fprintf(stderr,"probe baseline candidate fastnum\n");return 2;}
 hip_probe::Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle mods[2]{},kernels[2]{},stream{};a.Check(a.hipStreamCreate(&stream),"stream");for(int j=0;j<2;j++){a.Check(a.hipModuleLoad(&mods[j],argv[j+1]),"module");kernels[j]=fn(a,mods[j],j?"vit_attention_fused_960_bytein_bout":"vit_attention_fused_640_bytein_bout");}
 unsigned tokens=960;void*dx{},*dout{};void*gate{};a.Check(a.hipMalloc(&dx,size_t(tokens)*3072),"input");a.Check(a.hipMalloc(&dout,size_t(tokens)*1024),"out");void*args[]={&dx,&dout,&tokens,&gate};auto run=[&](int j){a.Check(a.hipModuleLaunchKernel(kernels[j],tokens/16*32,1,1,32,1,1,0,stream,args,nullptr),"attention");};
 for(unsigned pattern:{0u,1u}){
  std::vector<unsigned char>x(size_t(tokens)*3072);for(unsigned part=0;part<3;part++)for(unsigned t=0;t<tokens;t++)for(unsigned c=0;c<1024;c++){unsigned u=(t*131+c*73+part*199)%251;unsigned sign=(u&1)<<7;unsigned v=pattern?((part<2?0x08:0x20)+(u%32)):u%127;x[(size_t(part)*tokens+t)*1024+c]=sign|v;}
  a.Check(a.hipMemcpy(dx,x.data(),x.size(),1),"upload");std::vector<unsigned char>o[2];for(int j=0;j<2;j++){run(j);a.Check(a.hipStreamSynchronize(stream),"readready");o[j].resize(size_t(tokens)*1024);a.Check(a.hipMemcpy(o[j].data(),dout,o[j].size(),2),"read");}size_t diff=0;for(size_t i=0;i<o[0].size();i++)diff+=o[0][i]!=o[1][i];printf("COMPARE fast=%s tokens=960 pattern=%u byte_diff=%zu bytes=%zu\n",argv[3],pattern,diff,o[0].size());if(diff)return 3;
  for(int warm=0;warm<3;warm++)for(int j:{0,1}){for(int q=0;q<100;q++)run(j);a.Check(a.hipStreamSynchronize(stream),"steady");}
  for(int round=0;round<3;round++)for(int j:{0,1,1,0}){for(int q=0;q<20;q++)run(j);a.Check(a.hipStreamSynchronize(stream),"warm");Handle start{},end{};a.Check(a.hipEventCreate(&start),"start");a.Check(a.hipEventCreate(&end),"end");const int repeats=150;auto t=std::chrono::steady_clock::now();a.Check(a.hipEventRecord(start,stream),"startrecord");for(int q=0;q<repeats;q++)run(j);a.Check(a.hipEventRecord(end,stream),"endrecord");a.Check(a.hipEventSynchronize(end),"endready");float ms=0;a.Check(a.hipEventElapsedTime(&ms,start,end),"elapsed");double wall=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-t).count();printf("TIME fast=%s pattern=%u round=%d variant=%d n=%d event_ms=%.6f wall_ms=%.6f per_event_us=%.6f per_wall_us=%.6f\n",argv[3],pattern,round,j,repeats,ms,wall,ms*1000/repeats,wall*1000/repeats);if(!(ms>0&&wall>0))return 4;a.hipEventDestroy(start);a.hipEventDestroy(end);}
 }
 return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 2;}}
