// Original 310.8 plugin SHA e16bcf15e16e13f527491cdf7845b2fe6521a738d8f7c9c721866a8496e1fc8e only.
// Isolated diagnostic hooks: CPU packet/resource observation only; no GPU copies, waits, or context switches inside hooks.
// Optional HISTORY_PROBE_CLOSE_POST closes only Eval1 post history/MV in a local packet; default is observe-only.
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
static void dump_backend(FILE*f,void*self){
 void*ctx=nullptr;SIZE_T got=0;ReadProcessMemory(GetCurrentProcess(),static_cast<unsigned char*>(self)+8,&ctx,8,&got);
 fprintf(f,"BACKEND self=%p ctx=%p\n",self,ctx);void*vt=nullptr;if(!ctx||!ReadProcessMemory(GetCurrentProcess(),ctx,&vt,8,&got))return;
 for(unsigned j=0;j<64;j++){void*fn=nullptr;if(!ReadProcessMemory(GetCurrentProcess(),static_cast<unsigned char*>(vt)+j*8,&fn,8,&got))break;HMODULE module=nullptr;wchar_t name[1024]{};
 if(fn&&GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,reinterpret_cast<LPCWSTR>(fn),&module))GetModuleFileNameW(module,name,1024);
 fprintf(f,"VT index=%u fn=%p module=%ls rva=%llx\n",j,fn,name,(unsigned long long)((uintptr_t)fn-(uintptr_t)module));}
}
using Tex= int64_t(*)(void*,void*,uint64_t*,uint32_t);static Tex texture;
using Surf= int64_t(*)(void*,void*,uint64_t*);static Surf surface;
static void dump_wrapper(FILE*f,void*w){fprintf(f," WRAPPER ptr=%p",w);for(unsigned j=0;j<16;j++){uint64_t q=0;SIZE_T n=0;if(!w||!ReadProcessMemory(GetCurrentProcess(),static_cast<unsigned char*>(w)+j*8,&q,8,&n)||n!=8)break;fprintf(f," q%u=%llx",j,(unsigned long long)q);}fprintf(f,"\n");}
static int64_t on_tex(void*self,void*w,uint64_t*out,uint32_t mode){auto r=texture(self,w,out,mode);if(FILE*f=_wfopen(path.c_str(),L"ab")){fprintf(f,"BACKEND_TEX eval=%u mode=%u result=%lld object=%llx\n",eval_id,mode,(long long)r,(unsigned long long)(out?*out:0));dump_wrapper(f,w);fclose(f);}return r;}
static int64_t on_surface(void*self,void*w,uint64_t*out){auto r=surface(self,w,out);if(FILE*f=_wfopen(path.c_str(),L"ab")){fprintf(f,"BACKEND_SURFACE eval=%u result=%lld object=%llx\n",eval_id,(long long)r,(unsigned long long)(out?*out:0));dump_wrapper(f,w);fclose(f);}return r;}
static void* on_get(void*self,const char*n,uint32_t x,uint32_t y,uint32_t z,uint64_t flag){
 void*k=get(self,n,x,y,z,flag);std::lock_guard<std::mutex> l(guard);names[k]=n?n:"?";return k;
}
static int64_t on_launch(void*self,void*k,uint32_t x,uint32_t y,uint32_t z,void*wrapper,uint64_t bytes,uint8_t flag){
 std::string name;{std::lock_guard<std::mutex> l(guard);name=names.count(k)?names[k]:"?";}
 if(FILE*f=_wfopen(path.c_str(),L"ab")){fprintf(f,"ALL_LAUNCH eval=%u kernel=%s grid=%u,%u,%u bytes=%llu\n",eval_id,name.c_str(),x,y,z,(unsigned long long)bytes);fclose(f);}
 if(bytes==0x108||bytes==0xb8){
  void*blob=nullptr;SIZE_T read=0;ReadProcessMemory(GetCurrentProcess(),wrapper,&blob,sizeof(blob),&read);
  std::vector<unsigned char> data(static_cast<size_t>(bytes),0);
  if(blob&&ReadProcessMemory(GetCurrentProcess(),blob,data.data(),data.size(),&read)&&read==data.size()){
   if(FILE*f=_wfopen(path.c_str(),L"ab")){
    dump_backend(f,self);fprintf(f,"eval=%u kernel=%s grid=%u,%u,%u bytes=%llu\nPARAMHEX ",eval_id,name.c_str(),x,y,z,(unsigned long long)bytes);
    for(auto v:data)fprintf(f,"%02x",v);fprintf(f,"\n");
    if(bytes==0xb8){uint64_t object;for(auto pair:{std::pair<const char*,size_t>{"color",0x38},{"history",0x58},{"motion",0x60}}){memcpy(&object,data.data()+pair.second,8);texture_description(f,pair.first,object);}}
    fclose(f);
   }
  }
 }
 if(bytes==0xb8&&eval_id==1&&std::getenv("HISTORY_PROBE_CLOSE_POST")){void*blob=nullptr;SIZE_T n=0;ReadProcessMemory(GetCurrentProcess(),wrapper,&blob,8,&n);std::vector<unsigned char> packet(size_t(bytes),0);if(blob&&ReadProcessMemory(GetCurrentProcess(),blob,packet.data(),packet.size(),&n)&&n==packet.size()){memset(packet.data()+0x58,0,16);void*replacement=packet.data();if(FILE*f=_wfopen(path.c_str(),L"ab")){fprintf(f,"CONTROLLED_CLOSE_POST eval=1 prefix_unchanged=1 seed_unchanged=1\n");fclose(f);}return launch(self,k,x,y,z,&replacement,bytes,flag);}return -1;}
 return launch(self,k,x,y,z,wrapper,bytes,flag);
}
}
static void TemporalObserveFrame(unsigned id){temporal_observe::eval_id=id;}
static int TemporalObserveInstall(HMODULE plugin,const wchar_t*path){
 using namespace temporal_observe;temporal_observe::path=path;
 cuda_module=LoadLibraryW(L"nvcuda.dll");if(cuda_module){auto init=reinterpret_cast<decltype(&cuInit)>(GetProcAddress(cuda_module,"cuInit"));if(init)init(0);get_context=reinterpret_cast<decltype(get_context)>(GetProcAddress(cuda_module,"cuCtxGetCurrent"));get_resource=reinterpret_cast<decltype(get_resource)>(GetProcAddress(cuda_module,"cuTexObjectGetResourceDesc"));get_sampler=reinterpret_cast<decltype(get_sampler)>(GetProcAddress(cuda_module,"cuTexObjectGetTextureDesc"));get_array=reinterpret_cast<ArrayDesc>(GetProcAddress(cuda_module,"cuArrayGetDescriptor_v2"));}
 auto init=MH_Initialize();if(init!=MH_OK&&init!=MH_ERROR_ALREADY_INITIALIZED)return int(init);
 auto base=reinterpret_cast<unsigned char*>(plugin);
 if(MH_CreateHook(base+0x5d640,reinterpret_cast<void*>(on_tex),reinterpret_cast<void**>(&texture))!=MH_OK)return 3;
 if(MH_CreateHook(base+0x5d5d0,reinterpret_cast<void*>(on_surface),reinterpret_cast<void**>(&surface))!=MH_OK)return 4;
 if(MH_CreateHook(base+0x44830,reinterpret_cast<void*>(on_get),reinterpret_cast<void**>(&get))!=MH_OK)return 1;
 if(MH_CreateHook(base+0x449a0,reinterpret_cast<void*>(on_launch),reinterpret_cast<void**>(&launch))!=MH_OK)return 2;
 return int(MH_EnableHook(MH_ALL_HOOKS));
}

namespace history_d3d {
using Create=HRESULT(STDMETHODCALLTYPE*)(ID3D12Device*,const D3D12_HEAP_PROPERTIES*,D3D12_HEAP_FLAGS,const D3D12_RESOURCE_DESC*,D3D12_RESOURCE_STATES,const D3D12_CLEAR_VALUE*,REFIID,void**);
using Copy=void(STDMETHODCALLTYPE*)(ID3D12GraphicsCommandList*,const D3D12_TEXTURE_COPY_LOCATION*,UINT,UINT,UINT,const D3D12_TEXTURE_COPY_LOCATION*,const D3D12_BOX*);
using CopyResource=void(STDMETHODCALLTYPE*)(ID3D12GraphicsCommandList*,ID3D12Resource*,ID3D12Resource*);
static Create create;static Copy copy;static CopyResource copy_resource;
static std::map<ID3D12Resource*,D3D12_RESOURCE_STATES> states;static std::vector<ID3D12Resource*> textures;
using Dispatch=void(STDMETHODCALLTYPE*)(ID3D12GraphicsCommandList*,UINT,UINT,UINT);static Dispatch dispatch;
static void STDMETHODCALLTYPE on_dispatch(ID3D12GraphicsCommandList*l,UINT x,UINT y,UINT z){if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_DISPATCH eval=%u xyz=%u,%u,%u\n",temporal_observe::eval_id,x,y,z);fclose(f);}dispatch(l,x,y,z);}
using Barrier=void(STDMETHODCALLTYPE*)(ID3D12GraphicsCommandList*,UINT,const D3D12_RESOURCE_BARRIER*);static Barrier barrier;
static void STDMETHODCALLTYPE on_barrier(ID3D12GraphicsCommandList*l,UINT n,const D3D12_RESOURCE_BARRIER*b){for(UINT j=0;j<n;j++)if(b[j].Type==D3D12_RESOURCE_BARRIER_TYPE_TRANSITION&&b[j].Flags!=D3D12_RESOURCE_BARRIER_FLAG_BEGIN_ONLY){states[b[j].Transition.pResource]=b[j].Transition.StateAfter;}barrier(l,n,b);}

struct Heap {SIZE_T cpu;UINT64 gpu;UINT count;UINT step;};static std::vector<Heap>heaps;
using CreateHeap=HRESULT(STDMETHODCALLTYPE*)(ID3D12Device*,const D3D12_DESCRIPTOR_HEAP_DESC*,REFIID,void**);static CreateHeap create_heap;
using SRV=void(STDMETHODCALLTYPE*)(ID3D12Device*,ID3D12Resource*,const D3D12_SHADER_RESOURCE_VIEW_DESC*,D3D12_CPU_DESCRIPTOR_HANDLE);static SRV srv;
using UAV=void(STDMETHODCALLTYPE*)(ID3D12Device*,ID3D12Resource*,ID3D12Resource*,const D3D12_UNORDERED_ACCESS_VIEW_DESC*,D3D12_CPU_DESCRIPTOR_HANDLE);static UAV uav;
static UINT64 gpu_for(SIZE_T cpu){for(auto&h:heaps)if(cpu>=h.cpu&&cpu<h.cpu+size_t(h.count)*h.step)return h.gpu+(cpu-h.cpu);return 0;}
static HRESULT STDMETHODCALLTYPE on_heap(ID3D12Device*d,const D3D12_DESCRIPTOR_HEAP_DESC*h,REFIID iid,void**o){auto r=create_heap(d,h,iid,o);if(SUCCEEDED(r)){auto p=static_cast<ID3D12DescriptorHeap*>(*o);auto c=p->GetCPUDescriptorHandleForHeapStart();auto g=p->GetGPUDescriptorHandleForHeapStart();auto step=d->GetDescriptorHandleIncrementSize(h->Type);heaps.push_back({c.ptr,g.ptr,h->NumDescriptors,step});if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_HEAP ptr=%p type=%u flags=%u cpu=%llx gpu=%llx count=%u step=%u\n",p,unsigned(h->Type),unsigned(h->Flags),(unsigned long long)c.ptr,(unsigned long long)g.ptr,h->NumDescriptors,step);fclose(f);}}return r;}

static void describe(FILE*f,ID3D12Resource*r){if(!r)return;auto d=r->GetDesc();fprintf(f," RESOURCE ptr=%p dim=%u w=%llu h=%u fmt=%u flags=%u\n",r,unsigned(d.Dimension),(unsigned long long)d.Width,d.Height,unsigned(d.Format),unsigned(d.Flags));}
static void STDMETHODCALLTYPE on_srv(ID3D12Device*d,ID3D12Resource*r,const D3D12_SHADER_RESOURCE_VIEW_DESC*v,D3D12_CPU_DESCRIPTOR_HANDLE h){if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_SRV eval=%u cpu=%llx gpu=%llx fmt=%u dimension=%u\n",temporal_observe::eval_id,(unsigned long long)h.ptr,(unsigned long long)gpu_for(h.ptr),v?unsigned(v->Format):0,v?unsigned(v->ViewDimension):0);describe(f,r);fclose(f);}srv(d,r,v,h);}
static void STDMETHODCALLTYPE on_uav(ID3D12Device*d,ID3D12Resource*r,ID3D12Resource*c,const D3D12_UNORDERED_ACCESS_VIEW_DESC*v,D3D12_CPU_DESCRIPTOR_HANDLE h){if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_UAV eval=%u cpu=%llx gpu=%llx fmt=%u dimension=%u\n",temporal_observe::eval_id,(unsigned long long)h.ptr,(unsigned long long)gpu_for(h.ptr),v?unsigned(v->Format):0,v?unsigned(v->ViewDimension):0);describe(f,r);fclose(f);}uav(d,r,c,v,h);}
static HRESULT STDMETHODCALLTYPE on_create(ID3D12Device*d,const D3D12_HEAP_PROPERTIES*h,D3D12_HEAP_FLAGS fl,const D3D12_RESOURCE_DESC*r,D3D12_RESOURCE_STATES st,const D3D12_CLEAR_VALUE*c,REFIID iid,void**o){auto result=create(d,h,fl,r,st,c,iid,o);if(SUCCEEDED(result)&&o&&*o&&r->Dimension==D3D12_RESOURCE_DIMENSION_TEXTURE2D){auto resource=static_cast<ID3D12Resource*>(*o);resource->AddRef();textures.push_back(resource);states[resource]=st;if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_CREATE eval=%u heap=%u state=%u\n",temporal_observe::eval_id,unsigned(h->Type),unsigned(st));describe(f,static_cast<ID3D12Resource*>(*o));fclose(f);}}return result;}
static void STDMETHODCALLTYPE on_copy(ID3D12GraphicsCommandList*l,const D3D12_TEXTURE_COPY_LOCATION*d,UINT x,UINT y,UINT z,const D3D12_TEXTURE_COPY_LOCATION*s,const D3D12_BOX*b){if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_COPY eval=%u dsttype=%u srctype=%u xyz=%u,%u,%u\n",temporal_observe::eval_id,unsigned(d->Type),unsigned(s->Type),x,y,z);describe(f,d->pResource);describe(f,s->pResource);fclose(f);}copy(l,d,x,y,z,s,b);}
static void STDMETHODCALLTYPE on_copy_resource(ID3D12GraphicsCommandList*l,ID3D12Resource*d,ID3D12Resource*s){if(FILE*f=_wfopen(temporal_observe::path.c_str(),L"ab")){fprintf(f,"D3D_COPY_RESOURCE eval=%u\n",temporal_observe::eval_id);describe(f,d);describe(f,s);fclose(f);}copy_resource(l,d,s);}
}
static void TemporalD3DInstall(ID3D12Device*d,ID3D12GraphicsCommandList*l){using namespace history_d3d;auto r=MH_Initialize();auto dv=*reinterpret_cast<void***>(d),lv=*reinterpret_cast<void***>(l);MH_CreateHook(dv[14],reinterpret_cast<void*>(on_heap),reinterpret_cast<void**>(&create_heap));MH_CreateHook(dv[18],reinterpret_cast<void*>(on_srv),reinterpret_cast<void**>(&srv));MH_CreateHook(dv[19],reinterpret_cast<void*>(on_uav),reinterpret_cast<void**>(&uav));MH_CreateHook(dv[27],reinterpret_cast<void*>(on_create),reinterpret_cast<void**>(&create));MH_CreateHook(lv[14],reinterpret_cast<void*>(on_dispatch),reinterpret_cast<void**>(&dispatch));MH_CreateHook(lv[26],reinterpret_cast<void*>(on_barrier),reinterpret_cast<void**>(&barrier));MH_CreateHook(lv[16],reinterpret_cast<void*>(on_copy),reinterpret_cast<void**>(&copy));MH_CreateHook(lv[17],reinterpret_cast<void*>(on_copy_resource),reinterpret_cast<void**>(&copy_resource));MH_EnableHook(MH_ALL_HOOKS);}
