// Synthetic finite-FP8 launch/guard/timing probe. Not actual model latency or output equivalence.
#include "hip_api.h"
#include "ffwd-abi.h"
#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <memory>
#include <cmath>
using hip_probe::Handle;
struct Buffer{hip_probe::Api&a;void*base{};size_t n;static constexpr size_t guard=256;Buffer(hip_probe::Api&api,size_t bytes):a(api),n(bytes){a.Check(a.hipMalloc(&base,n+2*guard),"malloc");}~Buffer(){if(base)a.hipFree(base);}void*ptr(){return static_cast<unsigned char*>(base)+guard;}
 void fill(unsigned seed,unsigned code,bool output=false){std::vector<unsigned char>v(n+2*guard,0xa5);uint32_t x=seed;for(size_t i=0;i<n;i++){x^=x<<13;x^=x>>17;x^=x<<5;v[guard+i]=output?0x7f:code|((x>>31)<<7);}a.Check(a.hipMemcpy(base,v.data(),v.size(),1),"upload");}
 bool check(bool output){std::vector<unsigned char>v(n+2*guard);a.Check(a.hipMemcpy(v.data(),base,v.size(),2),"readback");size_t bad=0,nan=0,nonzero=0;uint64_t hash=1469598103934665603ull;for(size_t i=0;i<guard;i++)bad+=(v[i]!=0xa5)+(v[guard+n+i]!=0xa5);for(size_t i=0;i<n;i++){auto b=v[guard+i];nan+=(b&127)==127;nonzero+=(b&127)!=0;hash=(hash^b)*1099511628211ull;}printf("check output=%d bytes=%zu guard_bad=%zu invalid_fp8=%zu nonzero=%zu hash=%016llx\n",output,n,bad,nan,nonzero,(unsigned long long)hash);return !bad&&(!output||!nan);}
};
int main(int argc,char**argv){try{
 if(argc<2)throw std::runtime_error("microbench.exe DANIEL_GFX1201_HSACO [width=60] [height=36] [launches=200] [rounds=3] [OUR_MODULE_DIR optional]");
 unsigned width=argc>2?std::stoul(argv[2]):60,height=argc>3?std::stoul(argv[3]):36,launches=argc>4?std::stoul(argv[4]):200,rounds=argc>5?std::stoul(argv[5]):3;
 if(!width||!height||width%4||height%4||!launches||!rounds)throw std::runtime_error("positive dimensions divisible by4 and positive batch counts required");unsigned P=(width/4)*(height/4);
 hip_probe::Api api;api.Check(api.hipInit(0),"init");api.Check(api.hipSetDevice(0),"device");auto prop=api.Properties(0);char name[256]{};api.Check(api.hipDeviceGetName(name,256,0),"name");printf("SYNTHETIC_ONLY device=%s W=%u H=%u P=%u input=+-0.25 weights=+-1/64\n",name,width,height,P);
 Handle module{},fn[2]{},stream{},begin{},end{};api.Check(api.LoadModule(&module,argv[1]),"load");
 const char*symbols[]={"_Z14k_reg_vit_ffwdILi1ELb0ELb0EEv13VitFfwdParams","_Z14k_reg_vit_ffwdILi2ELb0ELb0EEv13VitFfwdParams"};for(int i=0;i<2;i++)api.Check(api.hipModuleGetFunction(&fn[i],module,symbols[i]),"function");
 api.Check(api.hipStreamCreate(&stream),"stream");api.Check(api.hipEventCreate(&begin),"event");api.Check(api.hipEventCreate(&end),"event");
 Buffer input(api,size_t(P)*8192),weights(api,524288),output(api,size_t(P)*8192);input.fill(0x12345678,0x28);weights.fill(0x98abcdef,0x08);output.fill(1,0,true);
 DanielVitFfwdParams params{input.ptr(),nullptr,output.ptr(),weights.ptr(),int(width),int(height),int(P),0};void*args[]={&params};
 unsigned tokens=width*height;const bool ours=argc>6;const int variants=ours?3:2;Handle ourModules[2]{},ourFn[2]{};
 std::unique_ptr<Buffer> fi,fw,mix,fo,fb;
 if(ours){
  std::string dir=argv[6];api.Check(api.LoadModule(&ourModules[0],(dir+"/c512-m32-deep.hsaco").c_str()),"our mix load");api.Check(api.LoadModule(&ourModules[1],(dir+"/deep_fast-packed.hsaco").c_str()),"our ffn load");
  api.Check(api.hipModuleGetFunction(&ourFn[0],ourModules[0],"split_mix_blocked_h16w_m32"),"our mix fn");api.Check(api.hipModuleGetFunction(&ourFn[1],ourModules[1],"split_ffn_fused_fp8_t8"),"our ffn fn");
  fi.reset(new Buffer(api,size_t(tokens)*512*4));fw.reset(new Buffer(api,524288*4));mix.reset(new Buffer(api,size_t(tokens)*512*4));fo.reset(new Buffer(api,size_t(tokens)*512*4));fb.reset(new Buffer(api,size_t(tokens)*512));
  for(auto*b:{fi.get(),fw.get(),mix.get(),fo.get(),fb.get()})b->fill(1,0,true);
  uint32_t rng=0x12345678;auto next=[&](){rng^=rng<<13;rng^=rng>>17;rng^=rng<<5;return rng>>31;};std::vector<float>x(size_t(tokens)*512);for(auto&v:x)v=next()?-.25f:.25f;api.Check(api.hipMemcpy(fi->ptr(),x.data(),x.size()*4,1),"our input");
  std::vector<unsigned char>w(524288*4,0);auto half=[&](size_t offset,size_t count){for(size_t j=0;j<count;j++){uint16_t v=uint16_t(0x2400|(next()<<15));std::memcpy(w.data()+offset+j*2,&v,2);}};half(0,262144);half(4*262144,131072);for(size_t j=0;j<131072;j++)w[4*393216+j]=uint8_t(0x08|(next()<<7));api.Check(api.hipMemcpy(fw->ptr(),w.data(),w.size(),1),"our weights");
 }
 auto checkOurs=[&](){bool ok=true;for(auto*b:{fi.get(),fw.get(),mix.get(),fo.get()})ok=b->check(false)&&ok;ok=fb->check(true)&&ok;for(auto*b:{mix.get(),fo.get()}){std::vector<float>x(b->n/4);api.Check(api.hipMemcpy(x.data(),b->ptr(),b->n,2),"our float read");size_t bad=0;for(float v:x)bad+=!std::isfinite(v);printf("our_float_finite bad=%zu values=%zu\n",bad,x.size());ok=ok&&!bad;}return ok;};
 auto launch=[&](int variant){if(variant==2){void*ip=fi->ptr(),*wp=fw->ptr(),*mp=mix->ptr(),*op=fo->ptr(),*bp=fb->ptr();void*ma[]={&ip,&wp,&mp,&tokens};void*fa[]={&mp,&wp,&op,&bp,&tokens};api.Check(api.hipModuleLaunchKernel(ourFn[0],((tokens+31)/32)*8,1,1,32,1,1,0,stream,ma,nullptr),"our mix");api.Check(api.hipModuleLaunchKernel(ourFn[1],tokens/2,1,1,128,1,1,0,stream,fa,nullptr),"our ffn");return;}api.Check(api.hipModuleLaunchKernel(fn[variant],(P+variant)/(variant+1),8,1,32,1,1,0,stream,args,nullptr),"launch");};
 for(int variant=0;variant<variants;variant++){output.fill(1,0,true);launch(variant);api.Check(api.hipStreamSynchronize(stream),"validation sync");printf("variant=%c ",'A'+variant);if(variant==2){if(!checkOurs())throw std::runtime_error("our finite/guard failed");}else if(!output.check(true)||!input.check(false)||!weights.check(false))throw std::runtime_error("guard/finite failed");for(int i=0;i<20;i++)launch(variant);api.Check(api.hipStreamSynchronize(stream),"warmup");}
 api.EnableGraphs();Handle graphs[3]{},executables[3]{};for(int v=0;v<variants;v++){api.Check(api.hipStreamBeginCapture(stream,0),"capture begin");for(unsigned i=0;i<launches;i++)launch(v);api.Check(api.hipStreamEndCapture(stream,&graphs[v]),"capture end");api.Check(api.hipGraphInstantiate(&executables[v],graphs[v],nullptr,nullptr,0),"graph instantiate");api.Check(api.hipGraphLaunch(executables[v],stream),"graph warmup");api.Check(api.hipStreamSynchronize(stream),"graph warmup sync");}
 for(int comparison=1;comparison<variants;comparison++)for(unsigned round=0;round<rounds;round++)for(int slot=0;slot<4;slot++){int variant=(slot==1||slot==2)?comparison:0;api.Check(api.hipEventRecord(begin,stream),"record");api.Check(api.hipGraphLaunch(executables[variant],stream),"graph launch");api.Check(api.hipEventRecord(end,stream),"record");api.Check(api.hipEventSynchronize(end),"event sync");float ms=0;api.Check(api.hipEventElapsedTime(&ms,begin,end),"elapsed");printf("timing round=%u slot=%d variant=%c launches=%u total_ms=%.6f us_per_launch=%.6f\n",round,slot,'A'+variant,launches,ms,1000.*ms/launches);}
 if(!output.check(true)||!input.check(false)||!weights.check(false))throw std::runtime_error("final guard/finite failed");if(ours&&!checkOurs())throw std::runtime_error("our final check");for(int v=0;v<variants;v++){api.hipGraphExecDestroy(executables[v]);api.hipGraphDestroy(graphs[v]);}api.hipEventDestroy(begin);api.hipEventDestroy(end);api.hipStreamDestroy(stream);api.hipModuleUnload(module);return 0;
 }catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 1;}}
