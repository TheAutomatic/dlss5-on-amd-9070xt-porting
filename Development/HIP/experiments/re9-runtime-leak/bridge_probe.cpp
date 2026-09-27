// Real bridge lifecycle probe: create D3D12Bridge per session at cycling tiers, run one staged network frame, destroy; log memory.
#include "hip_d3d12_bridge.h"
#include "LmxxfProductionOptions.h"
#include <psapi.h>
static void C(HRESULT h,const char*w){if(FAILED(h)){std::fprintf(stderr,"FAIL %s %08lx\n",w,(unsigned long)h);std::exit(1);}}
int main(int argc,char**argv){
 if(argc<3){std::fprintf(stderr,"usage: bridge_probe <assets_dir> <sessions>\n");return 2;}
 std::string assets=argv[1];int N=atoi(argv[2]);
 IDXGIFactory4*f{};C(CreateDXGIFactory1(IID_PPV_ARGS(&f)),"factory");IDXGIAdapter1*ad{};ID3D12Device*dev{};
 for(UINT i=0;f->EnumAdapters1(i,&ad)!=DXGI_ERROR_NOT_FOUND;i++){DXGI_ADAPTER_DESC1 d{};ad->GetDesc1(&d);if(d.VendorId==0x1002&&SUCCEEDED(D3D12CreateDevice(ad,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&dev))))break;ad->Release();ad=nullptr;}
 IDXGIAdapter3*a3{};ad->QueryInterface(IID_PPV_ARGS(&a3));
 D3D12_COMMAND_QUEUE_DESC qd{};qd.Type=D3D12_COMMAND_LIST_TYPE_DIRECT;ID3D12CommandQueue*q{};C(dev->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)),"queue");
 auto report=[&](int it,unsigned w,unsigned h,const char*tag){DXGI_QUERY_VIDEO_MEMORY_INFO vi{};a3->QueryVideoMemoryInfo(0,DXGI_MEMORY_SEGMENT_GROUP_LOCAL,&vi);PROCESS_MEMORY_COUNTERS_EX pm{};pm.cb=sizeof pm;GetProcessMemoryInfo(GetCurrentProcess(),(PROCESS_MEMORY_COUNTERS*)&pm,sizeof pm);
  std::printf("it=%d %s %ux%u dxgi_local_MiB=%.1f private_MiB=%.1f\n",it,tag,w,h,vi.CurrentUsage/1048576.,pm.PrivateUsage/1048576.);std::fflush(stdout);};
 const unsigned tiers[][2]={{1920,1152},{1600,960},{1280,768},{1920,1152}};
 report(-1,0,0,"start");
 for(int it=0;it<N;it++){auto&t=tiers[it%4];
  {hip_reference::D3D12Bridge b;auto o=LmxxfProductionOptions(t[0],t[1],assets+"\\HIP",assets);
   b.Create(q,o,std::vector<float>());b.PrepareStagedKernels();
   report(it,t[0],t[1],"live");}
  report(it,t[0],t[1],"after-destroy");}
 return 0;}
