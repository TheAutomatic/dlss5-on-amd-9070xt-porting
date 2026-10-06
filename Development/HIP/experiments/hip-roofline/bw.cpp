// 9070 XT achievable bandwidth: hipMemcpyAsync D2D and read/write/copy kernels, sizes inside and outside the 64MB MALL.
#include "../../hip_api.h"
#include <vector>
#include <algorithm>
using namespace hip_probe;
int main(int argc,char**argv){try{
 if(argc!=2)throw std::runtime_error("bw BW_HSACO");
 Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");
 Handle s{},m{},frd{},fwr{},fcp{};a.Check(a.hipStreamCreate(&s),"stream");a.Check(a.hipModuleLoad(&m,argv[1]),"module");
 a.Check(a.hipModuleGetFunction(&frd,m,"rd"),"rd");a.Check(a.hipModuleGetFunction(&fwr,m,"wr"),"wr");a.Check(a.hipModuleGetFunction(&fcp,m,"cp"),"cp");
 const size_t MAX=size_t(1)<<30;void*A{},*B{};float*sink{};a.Check(a.hipMalloc(&A,MAX),"A");a.Check(a.hipMalloc(&B,MAX),"B");a.Check(a.hipMalloc((void**)&sink,256),"sink");
 a.Check(a.hipMemsetAsync(A,0,MAX,s),"ms");a.Check(a.hipMemsetAsync(B,0,MAX,s),"ms");a.Check(a.hipStreamSynchronize(s),"sync");
 Handle e0{},e1{};a.Check(a.hipEventCreate(&e0),"e");a.Check(a.hipEventCreate(&e1),"e");
 auto timeit=[&](auto body,int reps){std::vector<float>t;for(int r=0;r<3;r++)body();a.Check(a.hipStreamSynchronize(s),"w");
  for(int r=0;r<reps;r++){a.Check(a.hipEventRecord(e0,s),"r");body();a.Check(a.hipEventRecord(e1,s),"r");a.Check(a.hipEventSynchronize(e1),"s");float ms=0;a.Check(a.hipEventElapsedTime(&ms,e0,e1),"el");t.push_back(ms);}
  std::sort(t.begin(),t.end());return double(t[t.size()/2]);};
 unsigned grids[]={256,1024,4096,16384};
 for(size_t bytes:{size_t(16)<<20,size_t(18432000),size_t(26542080),size_t(48)<<20,size_t(128)<<20,size_t(256)<<20,size_t(1)<<30}){
  size_t n=bytes/16;int reps=bytes>(size_t(256)<<20)?11:31;
  double mc=timeit([&]{a.Check(a.hipMemcpyAsync(B,A,bytes,3,s),"cpy");},reps);
  printf("size_MB=%.1f memcpyD2D ms=%.4f GBs_rw=%.1f\n",bytes/1048576.0,mc,2*bytes/mc/1e6);
  for(unsigned g:grids){
   unsigned long long st=g*256ull;void*ar[]={&A,&n,&sink,&st};void*aw[]={&B,&n,&st};void*ac[]={&A,&B,&n,&st};
   double r=timeit([&]{a.Check(a.hipModuleLaunchKernel(frd,g,1,1,256,1,1,0,s,ar,nullptr),"rd");},reps);
   double w=timeit([&]{a.Check(a.hipModuleLaunchKernel(fwr,g,1,1,256,1,1,0,s,aw,nullptr),"wr");},reps);
   double c=timeit([&]{a.Check(a.hipModuleLaunchKernel(fcp,g,1,1,256,1,1,0,s,ac,nullptr),"cp");},reps);
   printf("size_MB=%.1f grid=%u read GBs=%.1f write GBs=%.1f copy GBs_rw=%.1f (ms %.4f/%.4f/%.4f)\n",bytes/1048576.0,g,bytes/r/1e6,bytes/w/1e6,2*bytes/c/1e6,r,w,c);}
 }
 return 0;}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
