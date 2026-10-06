#include "hip_reference_network.h"
#include <cstdio>
#include <vector>
#include <chrono>
#include <cmath>
using namespace hip_reference;using hip_probe::Handle;
static Handle fn(Api&a,Handle m,const char*n){Handle f{};a.Check(a.hipModuleGetFunction(&f,m,n),n);return f;}
static float fp8(unsigned b){unsigned v=b&127,e=v>>3,m=v&7;float x=e?std::ldexp(float(8+m),int(e)-10):std::ldexp(float(m),-9);return b&128?-x:x;}
int main(int argc,char**argv){try{
 if(argc!=3){fprintf(stderr,"probe module-directory assets\n");return 2;}
 Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle modules[4]{},kernels[4]{},stream{};a.Check(a.hipStreamCreate(&stream),"stream");for(int m=0;m<4;m++){std::string p=std::string(argv[1])+"/"+std::to_string(m)+".hsaco";a.Check(a.hipModuleLoad(&modules[m],p.c_str()),"load");kernels[m]=fn(a,modules[m],"split_ffn_one_w2f8");}
 auto alloc=[&](size_t n){void*p{};a.Check(a.hipMalloc(&p,n),"alloc");return p;};auto launch=[&](Handle f,unsigned groups,unsigned threads,void**args){a.Check(a.hipModuleLaunchKernel(f,groups,1,1,threads,1,1,0,stream,args,nullptr),"launch");};
 for(bool pair:{false,true}){size_t bytes=pair?65536*8:65536;void*old=alloc(bytes),*next=alloc(bytes);void*args[]={&old,&next};launch(fn(a,modules[3],pair?"direct_pack_pair_proof":"direct_pack_proof"),256,256,args);a.Check(a.hipStreamSynchronize(stream),"proofready");std::vector<unsigned char>v(bytes),w(bytes);a.Check(a.hipMemcpy(v.data(),old,bytes,2),"oldread");a.Check(a.hipMemcpy(w.data(),next,bytes,2),"newread");size_t diff=0;for(size_t i=0;i<bytes;i++)diff+=v[i]!=w[i];printf("PROOF pair=%d half_codes=65536 byte_diff=%zu bytes=%zu\n",pair,diff,bytes);if(diff)return 3;a.hipFree(old);a.hipFree(next);}
 auto weights=ReadWeights(std::string(argv[2])+"/block23-ffwd.f32");PackWeightRegions(weights,{{0,262144},{262144,131072},{393216,131072}});void*dw=alloc(weights.size()*4);a.Check(a.hipMemcpy(dw,weights.data(),weights.size()*4,1),"weights");
 for(unsigned tokens:{1504u,2160u,3680u}){
  void*dx=alloc(size_t(tokens)*512*4),*out=alloc(size_t(tokens)*512);void*args[]={&dx,&dw,&out,&tokens};auto run=[&](int m){launch(kernels[m],(tokens+31)/32*8,64,args);};std::vector<float>x(size_t(tokens)*512);std::vector<unsigned char>base(size_t(tokens)*512),next(base.size());
  for(unsigned pattern=0;pattern<3;pattern++){
   for(size_t i=0;i<x.size();i++){unsigned u=(i*131u+(i/512)*17u+pattern*71u)%251u;unsigned b=pattern==0?((u%33+0x18)|((u&1)<<7)):pattern==1?((u%8)|((u&1)<<7)):((u%127)|((u&1)<<7));x[i]=fp8(b);}
   a.Check(a.hipMemcpy(dx,x.data(),x.size()*4,1),"input");run(0);a.Check(a.hipStreamSynchronize(stream),"baseline ready");a.Check(a.hipMemcpy(base.data(),out,base.size(),2),"baseread");for(int m=1;m<4;m++){run(m);a.Check(a.hipStreamSynchronize(stream),"candidate ready");a.Check(a.hipMemcpy(next.data(),out,next.size(),2),"newread");size_t diff=0;for(size_t i=0;i<base.size();i++)diff+=base[i]!=next[i];printf("COMPARE tokens=%u pattern=%u variant=%d byte_diff=%zu bytes=%zu\n",tokens,pattern,m,diff,base.size());if(diff)return 4;}
  }
  // Time the final (wide finite-grid) pattern; fixed input for each A/B pair, all kernels warmed first.
  for(int warm=0;warm<5;warm++)for(int m=0;m<4;m++){for(int q=0;q<60;q++)run(m);a.Check(a.hipStreamSynchronize(stream),"steady warm");}
  for(int m=1;m<4;m++)for(int round=0;round<3;round++)for(int k:{0,m,m,0}){
   for(int q=0;q<30;q++)run(k);a.Check(a.hipStreamSynchronize(stream),"warm");Handle start{},end{};a.Check(a.hipEventCreate(&start),"start");a.Check(a.hipEventCreate(&end),"end");const int n=300;auto t=std::chrono::steady_clock::now();a.Check(a.hipEventRecord(start,stream),"start record");for(int q=0;q<n;q++)run(k);a.Check(a.hipEventRecord(end,stream),"end record");a.Check(a.hipEventSynchronize(end),"end ready");float ms{};a.Check(a.hipEventElapsedTime(&ms,start,end),"elapsed");double wall=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-t).count();printf("TIME tokens=%u pair=%d round=%d variant=%d n=%d event_ms=%.6f wall_ms=%.6f event_us=%.6f wall_us=%.6f\n",tokens,m,round,k,n,ms,wall,ms*1000/n,wall*1000/n);if(!(ms>0&&wall>0))return 5;a.hipEventDestroy(start);a.hipEventDestroy(end);
  }
  a.hipFree(dx);a.hipFree(out);
 }
 return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 2;}}
