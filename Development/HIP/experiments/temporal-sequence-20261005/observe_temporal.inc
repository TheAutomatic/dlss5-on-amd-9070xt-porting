// Original 310.8 plugin SHA e16bcf15e16e13f527491cdf7845b2fe6521a738d8f7c9c721866a8496e1fc8e only.
// Observe scalar launch packets. No seed patch, GPU capture, synchronization or module load in hooks.
#include <map>
#include <mutex>
namespace temporal_observe {
using Get=void*(*)(void*,const char*,uint32_t,uint32_t,uint32_t,uint64_t);
using Launch=int64_t(*)(void*,void*,uint32_t,uint32_t,uint32_t,void*,uint64_t,uint8_t);
static Get get;static Launch launch;static std::map<void*,std::string> names;static std::mutex guard;
static std::wstring path;static unsigned eval_id=0;
static void* on_get(void*self,const char*n,uint32_t x,uint32_t y,uint32_t z,uint64_t flag){
 void*k=get(self,n,x,y,z,flag);std::lock_guard<std::mutex> l(guard);names[k]=n?n:"?";return k;
}
static int64_t on_launch(void*self,void*k,uint32_t x,uint32_t y,uint32_t z,void*wrapper,uint64_t bytes,uint8_t flag){
 std::string name;{std::lock_guard<std::mutex> l(guard);name=names.count(k)?names[k]:"?";}
 if(bytes==0x108||bytes==0xb8){
  void*blob=nullptr;SIZE_T read=0;ReadProcessMemory(GetCurrentProcess(),wrapper,&blob,sizeof(blob),&read);
  std::vector<unsigned char> data(static_cast<size_t>(bytes),0);
  if(blob&&ReadProcessMemory(GetCurrentProcess(),blob,data.data(),data.size(),&read)&&read==data.size()){
   if(FILE*f=_wfopen(path.c_str(),L"ab")){
    fprintf(f,"eval=%u kernel=%s grid=%u,%u,%u bytes=%llu\nPARAMHEX ",eval_id,name.c_str(),x,y,z,(unsigned long long)bytes);
    for(auto v:data)fprintf(f,"%02x",v);fprintf(f,"\n");fclose(f);
   }
  }
 }
 return launch(self,k,x,y,z,wrapper,bytes,flag);
}
}
static void TemporalObserveFrame(unsigned id){temporal_observe::eval_id=id;}
static int TemporalObserveInstall(HMODULE plugin,const wchar_t*path){
 using namespace temporal_observe;temporal_observe::path=path;
 auto init=MH_Initialize();if(init!=MH_OK&&init!=MH_ERROR_ALREADY_INITIALIZED)return int(init);
 auto base=reinterpret_cast<unsigned char*>(plugin);
 if(MH_CreateHook(base+0x44830,reinterpret_cast<void*>(on_get),reinterpret_cast<void**>(&get))!=MH_OK)return 1;
 if(MH_CreateHook(base+0x449a0,reinterpret_cast<void*>(on_launch),reinterpret_cast<void**>(&launch))!=MH_OK)return 2;
 return int(MH_EnableHook(MH_ALL_HOOKS));
}
