// Original 310.8 plugin SHA e16bcf15e16e13f527491cdf7845b2fe6521a738d8f7c9c721866a8496e1fc8e only.
// Observe scalar launch packets. No seed patch, GPU capture, synchronization or module load in hooks.
#include <map>
#include <mutex>
#include <cuda.h>
namespace temporal_observe {
using Get=void*(*)(void*,const char*,uint32_t,uint32_t,uint32_t,uint64_t);
using Launch=int64_t(*)(void*,void*,uint32_t,uint32_t,uint32_t,void*,uint64_t,uint8_t);
static Get get;static Launch launch;static std::map<void*,std::string> names;static std::mutex guard;
static std::wstring path;static unsigned eval_id=0;
static HMODULE cuda_module;static decltype(&cuCtxGetCurrent) get_context;
static decltype(&cuTexObjectGetResourceDesc) get_resource;
static decltype(&cuTexObjectGetTextureDesc) get_sampler;
using ArrayDesc=CUresult(CUDAAPI*)(CUDA_ARRAY_DESCRIPTOR*,CUarray);
static ArrayDesc get_array;
static void texture_description(FILE*f,const char*name,uint64_t object){
 if(!object){fprintf(f,"TEXTURE name=%s object=0\n",name);return;}
 CUcontext ctx=nullptr;CUresult cr=get_context?get_context(&ctx):CUDA_ERROR_NOT_INITIALIZED;
 fprintf(f,"TEXTURE name=%s object=%llx current_context=%p context_result=%d",name,(unsigned long long)object,ctx,int(cr));
 if(cr!=CUDA_SUCCESS||!ctx){fprintf(f," descriptor_unavailable_no_current_context\n");return;}
 CUDA_RESOURCE_DESC rd{};CUDA_TEXTURE_DESC td{};
 CUresult rr=get_resource?get_resource(&rd,object):CUDA_ERROR_NOT_INITIALIZED;
 CUresult tr=get_sampler?get_sampler(&td,object):CUDA_ERROR_NOT_INITIALIZED;
 fprintf(f," resource_result=%d sampler_result=%d",int(rr),int(tr));
 if(rr==CUDA_SUCCESS){fprintf(f," resource_type=%d",int(rd.resType));if(rd.resType==CU_RESOURCE_TYPE_ARRAY){CUDA_ARRAY_DESCRIPTOR ad{};auto ar=get_array?get_array(&ad,rd.res.array.hArray):CUDA_ERROR_NOT_INITIALIZED;fprintf(f," array_result=%d",int(ar));if(ar==CUDA_SUCCESS)fprintf(f," width=%llu height=%llu format=%d channels=%u",(unsigned long long)ad.Width,(unsigned long long)ad.Height,int(ad.Format),ad.NumChannels);}}
 if(tr==CUDA_SUCCESS)fprintf(f," filter=%d normalized=%u address=%d,%d flags=%u",int(td.filterMode),unsigned(bool(td.flags&CU_TRSF_NORMALIZED_COORDINATES)),int(td.addressMode[0]),int(td.addressMode[1]),td.flags);
 fprintf(f,"\n");
}
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
    for(auto v:data)fprintf(f,"%02x",v);fprintf(f,"\n");
    if(bytes==0xb8){uint64_t object;for(auto pair:{std::pair<const char*,size_t>{"color",0x38},{"history",0x58},{"motion",0x60}}){memcpy(&object,data.data()+pair.second,8);texture_description(f,pair.first,object);}}
    fclose(f);
   }
  }
 }
 return launch(self,k,x,y,z,wrapper,bytes,flag);
}
}
static void TemporalObserveFrame(unsigned id){temporal_observe::eval_id=id;}
static int TemporalObserveInstall(HMODULE plugin,const wchar_t*path){
 using namespace temporal_observe;temporal_observe::path=path;
 cuda_module=LoadLibraryW(L"nvcuda.dll");if(cuda_module){auto init=reinterpret_cast<decltype(&cuInit)>(GetProcAddress(cuda_module,"cuInit"));if(init)init(0);get_context=reinterpret_cast<decltype(get_context)>(GetProcAddress(cuda_module,"cuCtxGetCurrent"));get_resource=reinterpret_cast<decltype(get_resource)>(GetProcAddress(cuda_module,"cuTexObjectGetResourceDesc"));get_sampler=reinterpret_cast<decltype(get_sampler)>(GetProcAddress(cuda_module,"cuTexObjectGetTextureDesc"));get_array=reinterpret_cast<ArrayDesc>(GetProcAddress(cuda_module,"cuArrayGetDescriptor_v2"));}
 auto init=MH_Initialize();if(init!=MH_OK&&init!=MH_ERROR_ALREADY_INITIALIZED)return int(init);
 auto base=reinterpret_cast<unsigned char*>(plugin);
 if(MH_CreateHook(base+0x44830,reinterpret_cast<void*>(on_get),reinterpret_cast<void**>(&get))!=MH_OK)return 1;
 if(MH_CreateHook(base+0x449a0,reinterpret_cast<void*>(on_launch),reinterpret_cast<void**>(&launch))!=MH_OK)return 2;
 return int(MH_EnableHook(MH_ALL_HOOKS));
}
