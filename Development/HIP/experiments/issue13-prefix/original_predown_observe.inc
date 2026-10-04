// Include after windows.h, MinHook.h; call OriginalObserveInstall(plugin,logpath) BEFORE CreateFeature.
// Only for SHA e16bcf15e16e13f527491cdf7845b2fe6521a738d8f7c9c721866a8496e1fc8e.
#include <cstdint>
#include <map>
#include <string>
#include <mutex>
#include <cstdio>
#include <cstring>
#include "../../../capture_raw_buffer_cubin.inc"
namespace original_observe {
using GetKernel=void*(*)(void*,const char*,uint32_t,uint32_t,uint32_t,uint64_t);
using Launch=int64_t(*)(void*,void*,uint32_t,uint32_t,uint32_t,void*,uint64_t,uint8_t);
static GetKernel get{};static Launch launch{};static std::map<void*,std::string> names;static std::mutex guard;
template<class T>T at(const void*p,size_t o){T v{};SIZE_T n{};if(p)ReadProcessMemory(GetCurrentProcess(),static_cast<const char*>(p)+o,&v,sizeof(v),&n);return v;}
static uintptr_t plugin_base{};static uint64_t capture_va{};static void*cap_backend{},*cap_copy{},*pre_backend{};
static void prepare(void*self){if(cap_backend)return;void*ctx=at<void*>(self,8);void*cmd=at<void*>(self,16);auto cb=reinterpret_cast<void*(*)(void*)>(plugin_base+0x447b0);auto sc=reinterpret_cast<void(*)(void*,void*)>(plugin_base+0x44b70);auto sm=reinterpret_cast<void(*)(void*,void*,uint32_t)>(plugin_base+0x44b60);cap_backend=cb(ctx);sc(cap_backend,cmd);sm(cap_backend,_tmp_capture_raw_buffer_cubin,_tmp_capture_raw_buffer_cubin_len);cap_copy=get(cap_backend,"capture_raw_buffer",256,1,1,0);printf("CAPTURE_PREPARED copy=%p\n",cap_copy);}
static void capture_down(void*self,void*restore,uint64_t src){if(!capture_va||!cap_copy){puts("CAPTURE_NOT_READY");return;}void*ctx=at<void*>(self,8);void*cmd=at<void*>(self,16);auto vt=*reinterpret_cast<void***>(ctx);auto bind=reinterpret_cast<int(*)(void*,void*)>(vt[0xd8/8]);auto dispatch=reinterpret_cast<int(*)(void*,void*,void*,uint32_t,uint32_t,uint32_t)>(vt[0x140/8]);struct Desc{void*vt;void*blob;uint32_t bytes,pad;};struct Copy{uint64_t src,dst;uint32_t count,pad;};constexpr uint32_t xy[4][2]={{832,528},{960,544},{0,0},{1912,1072}};bind(ctx,cap_copy);unsigned copies=0;for(unsigned tile=0;tile<4;tile++)for(unsigned slab=0;slab<2;slab++)for(unsigned dy=0;dy<4;dy++){uint64_t offset=uint64_t(slab)*960*576*16+(uint64_t(xy[tile][1]/2)+dy)*960*16+uint64_t(xy[tile][0]/2)*16;Copy c{src+offset,capture_va+uint64_t(((tile*2+slab)*4+dy))*64,4,0};Desc d{reinterpret_cast<void*>(plugin_base+0xb28b8),&c,sizeof(c),0};int e=dispatch(ctx,&d,cmd,1,1,1);if(e)printf("CAPTURE_DISPATCH error=%d\n",e);copies++;}bind(ctx,restore);printf("PREDOWN_CAPTURE copies=%u source=%llx bytes=2048\n",copies,(unsigned long long)src);}
static std::wstring path;static unsigned serial{};

static void* get_hook(void*self,const char*n,uint32_t a,uint32_t b,uint32_t c,uint64_t d){void*r=get(self,n,a,b,c,d);{std::lock_guard<std::mutex>l(guard);names[r]=n?n:"?";}return r;}
static int64_t launch_hook(void*self,void*k,uint32_t gx,uint32_t gy,uint32_t gz,void*wrapper,uint64_t bytes,uint8_t flag){
 void*blob=at<void*>(wrapper,0);std::string name;unsigned id;
 {std::lock_guard<std::mutex>l(guard);name=names.count(k)?names[k]:"?";id=serial++;
 if(FILE*f=_wfopen(path.c_str(),L"ab")){
  fprintf(f,"launch=%u kernel=%s kernelptr=%p grid=%u,%u,%u bytes=%llu flag=%u blob=%p ngxctx=%p commandctx=%p\n",id,name.c_str(),k,gx,gy,gz,(unsigned long long)bytes,flag,blob,at<void*>(self,8),at<void*>(self,16));
  if(blob&&bytes<=4096){
   if(name.find("pre_block")!=std::string::npos||bytes==0x108)fprintf(f,"PRE seed_c8=%u style_b4=%.9g texH_d0=%u texW_d4=%u procDims_f0=%llx colorTex_00=%llx historyTex_08=%llx motionTex_10=%llx\n",at<uint32_t>(blob,0xc8),at<float>(blob,0xb4),at<uint32_t>(blob,0xd0),at<uint32_t>(blob,0xd4),(unsigned long long)at<uint64_t>(blob,0xf0),(unsigned long long)at<uint64_t>(blob,0),(unsigned long long)at<uint64_t>(blob,8),(unsigned long long)at<uint64_t>(blob,16));
   if(name.find("post_block")!=std::string::npos||bytes==0xb8)fprintf(f,"POST main00=%llx skip08=%llx surface10=%llx weights18=%llx height20=%u width24=%u origin28=%d,%d scale30=%.9g rgbmode34=%u color38=%llx word70=%u\n",(unsigned long long)at<uint64_t>(blob,0),(unsigned long long)at<uint64_t>(blob,8),(unsigned long long)at<uint64_t>(blob,16),(unsigned long long)at<uint64_t>(blob,24),at<uint32_t>(blob,0x20),at<uint32_t>(blob,0x24),at<int32_t>(blob,0x28),at<int32_t>(blob,0x2c),at<float>(blob,0x30),at<uint32_t>(blob,0x34),(unsigned long long)at<uint64_t>(blob,0x38),at<uint32_t>(blob,0x70));
   fprintf(f,"PARAMHEX ");for(size_t i=0;i<size_t(bytes);i++)fprintf(f,"%02x",at<unsigned char>(blob,i));fprintf(f,"\n");
  }fclose(f);
 }}
 bool pre=name.find("pre_block")!=std::string::npos;bool post=name.find("post_block")!=std::string::npos;
 if(pre){pre_backend=self;uint32_t seed=1;printf("FORCE_SEED old=%u new=1\n",at<uint32_t>(blob,0xc8));memcpy(static_cast<char*>(blob)+0xc8,&seed,4);}
 auto result=launch(self,k,gx,gy,gz,wrapper,bytes,flag);
 if(pre){printf("PREDOWN dims=%llx ptr=%llx\n",(unsigned long long)at<uint64_t>(blob,0x100),(unsigned long long)at<uint64_t>(blob,0xf8));capture_down(self,k,at<uint64_t>(blob,0xf8));}
 return result;
}
}
static int OriginalObserveInstall(HMODULE plugin,const wchar_t*logpath){
 using namespace original_observe;path=logpath;plugin_base=reinterpret_cast<uintptr_t>(plugin);auto s=MH_Initialize();if(s!=MH_OK&&s!=MH_ERROR_ALREADY_INITIALIZED)return 1;
 auto base=reinterpret_cast<uintptr_t>(plugin);void*a=reinterpret_cast<void*>(base+0x44830),*b=reinterpret_cast<void*>(base+0x449a0);
 if(MH_CreateHook(a,reinterpret_cast<void*>(&get_hook),reinterpret_cast<void**>(&get))!=MH_OK)return 2;
 if(MH_CreateHook(b,reinterpret_cast<void*>(&launch_hook),reinterpret_cast<void**>(&launch))!=MH_OK)return 3;
 if(MH_EnableHook(a)!=MH_OK)return 4;if(MH_EnableHook(b)!=MH_OK)return 5;return 0;
}

static void OriginalCaptureDestination(uint64_t va){original_observe::capture_va=va;}

static void OriginalPrepareCapture(){if(original_observe::pre_backend)original_observe::prepare(original_observe::pre_backend);else puts("NO_PRE_BACKEND");}
