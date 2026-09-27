// Isolate D3D12 fence import/destruction; optional HIP wait/signal exercises the real bridge path.
#include "hip_api.h"
#include <d3d12.h>
#include <dxgi1_4.h>
#include <psapi.h>
using namespace hip_probe;
static void ck(HRESULT h){if(FAILED(h))throw std::runtime_error("D3D failure");}
int main(int argc,char**argv){try{
 setvbuf(stdout,nullptr,_IONBF,0);int n=argc>1?atoi(argv[1]):100;bool run=argc>2&&atoi(argv[2]);
 IDXGIFactory4*f{};ck(CreateDXGIFactory1(IID_PPV_ARGS(&f)));IDXGIAdapter1*a{};ID3D12Device*d{};
 for(UINT i=0;f->EnumAdapters1(i,&a)!=DXGI_ERROR_NOT_FOUND;++i){DXGI_ADAPTER_DESC1 p{};a->GetDesc1(&p);if(p.VendorId==0x1002&&SUCCEEDED(D3D12CreateDevice(a,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d))))break;a->Release();a=nullptr;}
 if(!d)throw std::runtime_error("no AMD adapter");IDXGIAdapter3*a3{};ck(a->QueryInterface(IID_PPV_ARGS(&a3)));
 Api api;api.Check(api.hipInit(0),"init");api.Check(api.hipSetDevice(0),"dev");Handle stream{};api.Check(api.hipStreamCreate(&stream),"stream");
 for(int i=0;i<n;++i){ID3D12Fence*fe{};HANDLE sh{};ck(d->CreateFence(0,D3D12_FENCE_FLAG_SHARED,IID_PPV_ARGS(&fe)));ck(d->CreateSharedHandle(fe,nullptr,GENERIC_ALL,nullptr,&sh));
 SemaphoreDesc sd{};sd.type=4;sd.handle.win32.handle=sh;Handle sem{};api.Check(api.hipImportExternalSemaphore(&sem,&sd),"import");
 if(run){ck(fe->Signal(1));WaitParams w{};w.params.fence.value=1;SignalParams s{};s.params.fence.value=2;api.Check(api.hipWaitExternalSemaphoresAsync(&sem,&w,1,stream),"wait");api.Check(api.hipSignalExternalSemaphoresAsync(&sem,&s,1,stream),"signal");api.Check(api.hipStreamSynchronize(stream),"sync");if(fe->GetCompletedValue()!=2)throw std::runtime_error("wrong fence value");}
 api.Check(api.hipDestroyExternalSemaphore(sem),"destroy");CloseHandle(sh);fe->Release();
 DXGI_QUERY_VIDEO_MEMORY_INFO vm{};ck(a3->QueryVideoMemoryInfo(0,DXGI_MEMORY_SEGMENT_GROUP_LOCAL,&vm));PROCESS_MEMORY_COUNTERS_EX pm{};pm.cb=sizeof(pm);GetProcessMemoryInfo(GetCurrentProcess(),(PROCESS_MEMORY_COUNTERS*)&pm,sizeof(pm));
 printf("iteration=%d live=%d vram_mib=%.3f private_mib=%.3f\n",i,run,vm.CurrentUsage/1048576.,pm.PrivateUsage/1048576.);
 }api.hipStreamDestroy(stream);return 0;
}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 1;}}
