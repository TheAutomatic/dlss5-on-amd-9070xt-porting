// Isolate module load/unload without allocating tensors or creating codecs.
#include "hip_api.h"
#include <d3d12.h>
#include <dxgi1_4.h>
#include <psapi.h>
using namespace hip_probe;
static void ck(HRESULT h){if(FAILED(h))throw std::runtime_error("D3D failure");}
int main(int argc,char**argv){try{
 setvbuf(stdout,nullptr,_IONBF,0);int n=argc>1?atoi(argv[1]):40;bool run=true;if(argc<3)throw std::runtime_error("usage: module_probe N modules");
 IDXGIFactory4*f{};ck(CreateDXGIFactory1(IID_PPV_ARGS(&f)));IDXGIAdapter1*a{};ID3D12Device*d{};
 for(UINT i=0;f->EnumAdapters1(i,&a)!=DXGI_ERROR_NOT_FOUND;++i){DXGI_ADAPTER_DESC1 p{};a->GetDesc1(&p);if(p.VendorId==0x1002&&SUCCEEDED(D3D12CreateDevice(a,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d))))break;a->Release();a=nullptr;}
 if(!d)throw std::runtime_error("no AMD adapter");IDXGIAdapter3*a3{};ck(a->QueryInterface(IID_PPV_ARGS(&a3)));
 Api api;api.Check(api.hipInit(0),"init");api.Check(api.hipSetDevice(0),"dev");Handle stream{};api.Check(api.hipStreamCreate(&stream),"stream");
 for(int i=0;i<n;++i){std::vector<Handle> modules;
 for(const auto&entry:std::filesystem::directory_iterator(argv[2]))if(entry.path().extension()==".hsaco"){
 Handle m{};api.Check(api.LoadModule(&m,entry.path().string().c_str()),"load module");modules.push_back(m);}
 for(auto m:modules)api.Check(api.hipModuleUnload(m),"unload");
 DXGI_QUERY_VIDEO_MEMORY_INFO vm{};ck(a3->QueryVideoMemoryInfo(0,DXGI_MEMORY_SEGMENT_GROUP_LOCAL,&vm));PROCESS_MEMORY_COUNTERS_EX pm{};pm.cb=sizeof(pm);GetProcessMemoryInfo(GetCurrentProcess(),(PROCESS_MEMORY_COUNTERS*)&pm,sizeof(pm));
 printf("iteration=%d live=%d vram_mib=%.3f private_mib=%.3f\n",i,run,vm.CurrentUsage/1048576.,pm.PrivateUsage/1048576.);
 }api.hipStreamDestroy(stream);return 0;
}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 1;}}
