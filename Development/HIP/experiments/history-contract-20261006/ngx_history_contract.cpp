#ifndef ORACLE_REPEATS
#define ORACLE_REPEATS 2
#endif
#ifndef ORACLE_HEIGHT
#define ORACLE_HEIGHT 1080
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d12.h>
#include <dxgi1_4.h>
#include <cstdio>
#include <string>
#include <vector>
#include <fstream>
#include <cmath>
#include "../issue13-original-oracle/ngx_direct_abi.h"
#include "MinHook.h"
#include "observe_history.inc"
#include "nvsdk_ngx.h"
static void ck(HRESULT h,const char*k){if(FAILED(h)){printf("D3D_FAIL %s %08x\n",k,unsigned(h));ExitProcess(1);}}
template<class T>T sym(HMODULE m,const char*n){auto p=GetProcAddress(m,n);if(!p){printf("EXPORT_MISSING %s\n",n);ExitProcess(2);}return reinterpret_cast<T>(p);}
void su(void*p,const char*k,unsigned n){auto v=*reinterpret_cast<void***>(p);reinterpret_cast<void(*)(void*,const char*,unsigned)>(v[4])(p,k,n);}
void sf(void*p,const char*k,float n){auto v=*reinterpret_cast<void***>(p);reinterpret_cast<void(*)(void*,const char*,float)>(v[6])(p,k,n);}
void logngx(const char*m,NVSDK_NGX_Logging_Level l,NVSDK_NGX_Feature f){printf("NGX[%d][%d] %s\n",int(l),int(f),m);}
int wmain(int argc,wchar_t**argv){setvbuf(stdout,nullptr,_IONBF,0);if(argc<5)return 2;CreateDirectoryW(argv[4],nullptr);IDXGIFactory4*f=nullptr;ck(CreateDXGIFactory1(IID_PPV_ARGS(&f)),"factory");ID3D12Device*d=nullptr;IDXGIAdapter1*a=nullptr;for(unsigned i=0;f->EnumAdapters1(i,&a)!=DXGI_ERROR_NOT_FOUND;i++){DXGI_ADAPTER_DESC1 ad{};a->GetDesc1(&ad);if(ad.VendorId==0x10de&&SUCCEEDED(D3D12CreateDevice(a,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d))))break;a->Release();a=nullptr;}if(!d)return 3;D3D12_COMMAND_QUEUE_DESC qd{};ID3D12CommandQueue*q=nullptr;ck(d->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)),"queue");ID3D12CommandAllocator*al=nullptr;ID3D12GraphicsCommandList*l=nullptr;ck(d->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT,IID_PPV_ARGS(&al)),"alloc");ck(d->CreateCommandList(0,D3D12_COMMAND_LIST_TYPE_DIRECT,al,nullptr,IID_PPV_ARGS(&l)),"list");
 temporal_observe::path=std::wstring(argv[4])+L"/launch-observe.txt";TemporalD3DInstall(d,l);
 SetDllDirectoryW(argv[2]);
 HMODULE core=LoadLibraryW(argv[1]);if(!core){printf("LOAD_FAIL %lu\n",GetLastError());return 4;}
 using Init=NVSDK_NGX_Result(*)(unsigned long long,const wchar_t*,ID3D12Device*,NVSDK_NGX_Version,const NVSDK_NGX_FeatureCommonInfo*);auto init=sym<Init>(core,"NVSDK_NGX_D3D12_Init_Ext");using Caps=NVSDK_NGX_Result(*)(NVSDK_NGX_Parameter**);auto caps=sym<Caps>(core,"NVSDK_NGX_D3D12_GetCapabilityParameters");using Create=NVSDK_NGX_Result(*)(ID3D12GraphicsCommandList*,NVSDK_NGX_Feature,NVSDK_NGX_Parameter*,NVSDK_NGX_Handle**);auto create=sym<Create>(core,"NVSDK_NGX_D3D12_CreateFeature");
 const wchar_t*paths[]={argv[2]};NVSDK_NGX_FeatureCommonInfo fc{};fc.PathListInfo.Path=paths;fc.PathListInfo.Length=1;fc.LoggingInfo.LoggingCallback=logngx;fc.LoggingInfo.MinimumLoggingLevel=NVSDK_NGX_LOGGING_LEVEL_VERBOSE;auto r=init(0x24480451ull,argv[4],d,NVSDK_NGX_Version(0x15),&fc);printf("INIT=%08x\n",unsigned(r));if(r!=1)return 5;NVSDK_NGX_Parameter*p=nullptr;r=caps(&p);printf("CAPS=%08x params=%p\n",unsigned(r),p);if(r!=1||!p)return 6;
 auto vt=*reinterpret_cast<void***>(p);sf(p,"DLSSNR.Probe",.3125f);float value=0;auto gr=reinterpret_cast<NVSDK_NGX_Result(*)(void*,const char*,float*)>(vt[14])(p,"DLSSNR.Probe",&value);printf("FLOAT_ABI=%08x value=%g\n",unsigned(gr),value);
 su(p,"DLSSNR.Enabled",1);su(p,"DLSSNR.Width",1920);su(p,"DLSSNR.Height",ORACLE_HEIGHT);su(p,"Width",1920);su(p,"Height",ORACLE_HEIGHT);su(p,"CreationNodeMask",1);su(p,"VisibilityNodeMask",1);su(p,"DLSSNR.Hint.Render.Preset",0);su(p,"DLSSNR.Style",1);sf(p,"DLSSNR.Intensity",1);sf(p,"DLSSNR.LocalStructureStrength",1);sf(p,"DLSSNR.LocalToneStrength",1);sf(p,"DLSSNR.SkinStructureStrength",-1);su(p,"DLSSNR.UseAutoMask",1);su(p,"DLSSNR.UICorrection",0);
 CreateDirectoryW(argv[4],nullptr);
 HMODULE plugin=GetModuleHandleW(L"nvngx_dlssnr.dll");if(!plugin)plugin=LoadLibraryW((std::wstring(argv[2])+L"/nvngx_dlssnr.dll").c_str());if(TemporalObserveInstall(plugin,(std::wstring(argv[4])+L"/launch-observe.txt").c_str()))return 14;
 NVSDK_NGX_Handle*h=nullptr;r=create(l,NVSDK_NGX_Feature(18),p,&h);printf("CREATE18=%08x handle=%p\n",unsigned(r),h);if(r!=1)return 7;l->Close();ID3D12CommandList*ls[]={l};q->ExecuteCommandLists(1,ls);ID3D12Fence*fe=nullptr;ck(d->CreateFence(0,D3D12_FENCE_FLAG_NONE,IID_PPV_ARGS(&fe)),"fence");HANDLE e=CreateEventW(nullptr,FALSE,FALSE,nullptr);q->Signal(fe,1);fe->SetEventOnCompletion(1,e);printf("CREATE_FENCE_WAIT=%lu\n",WaitForSingleObject(e,30000));if(argc<5)return 0;
 auto wait=[&](){static UINT64 fv=1;q->Signal(fe,++fv);fe->SetEventOnCompletion(fv,e);if(WaitForSingleObject(e,30000)!=WAIT_OBJECT_0){puts("WAIT_TIMEOUT");ExitProcess(9);}};
 auto buffer=[&](UINT64 n,D3D12_HEAP_TYPE type){D3D12_HEAP_PROPERTIES hp{};hp.Type=type;D3D12_RESOURCE_DESC rd{};rd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;rd.Width=n;rd.Height=1;rd.DepthOrArraySize=rd.MipLevels=1;rd.SampleDesc.Count=1;rd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;ID3D12Resource*r=nullptr;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&rd,type==D3D12_HEAP_TYPE_UPLOAD?D3D12_RESOURCE_STATE_GENERIC_READ:D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&r)),"buffer");return r;};
 auto texture=[&](DXGI_FORMAT format,D3D12_RESOURCE_STATES state){D3D12_HEAP_PROPERTIES hp{};hp.Type=D3D12_HEAP_TYPE_DEFAULT;D3D12_RESOURCE_DESC rd{};rd.Dimension=D3D12_RESOURCE_DIMENSION_TEXTURE2D;rd.Width=1920;rd.Height=ORACLE_HEIGHT;rd.DepthOrArraySize=rd.MipLevels=1;rd.SampleDesc.Count=1;rd.Format=format;rd.Flags=D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;ID3D12Resource*r=nullptr;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&rd,state,nullptr,IID_PPV_ARGS(&r)),"texture");return r;};
 auto color=texture(DXGI_FORMAT_R16G16B16A16_FLOAT,D3D12_RESOURCE_STATE_COPY_DEST),output=texture(DXGI_FORMAT_R32G32B32A32_FLOAT,D3D12_RESOURCE_STATE_UNORDERED_ACCESS),depth=texture(DXGI_FORMAT_R32_FLOAT,D3D12_RESOURCE_STATE_COPY_DEST),motion=texture(DXGI_FORMAT_R16G16_FLOAT,D3D12_RESOURCE_STATE_COPY_DEST);
 auto upload=[&](ID3D12Resource*r,const void*src,size_t bytes_per_pixel){auto rd=r->GetDesc();D3D12_PLACED_SUBRESOURCE_FOOTPRINT fp{};UINT64 bytes=0;d->GetCopyableFootprints(&rd,0,1,0,&fp,nullptr,nullptr,&bytes);auto up=buffer(bytes,D3D12_HEAP_TYPE_UPLOAD);void*dst=nullptr;D3D12_RANGE z{0,0};up->Map(0,&z,&dst);for(unsigned y=0;y<ORACLE_HEIGHT;y++)memcpy(static_cast<char*>(dst)+fp.Offset+size_t(y)*fp.Footprint.RowPitch,static_cast<const char*>(src)+size_t(y)*1920*bytes_per_pixel,1920*bytes_per_pixel);up->Unmap(0,nullptr);al->Reset();l->Reset(al,nullptr);D3D12_TEXTURE_COPY_LOCATION a{},b{};a.pResource=r;a.Type=D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;b.pResource=up;b.Type=D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;b.PlacedFootprint=fp;l->CopyTextureRegion(&a,0,0,0,&b,nullptr);D3D12_RESOURCE_BARRIER br{};br.Transition={r,D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,D3D12_RESOURCE_STATE_COPY_DEST,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE};l->ResourceBarrier(1,&br);l->Close();ID3D12CommandList*ls[]={l};q->ExecuteCommandLists(1,ls);wait();up->Release();};
 std::vector<float>dep(1920*ORACLE_HEIGHT,1.f);std::vector<unsigned>mv(1920*ORACLE_HEIGHT,0);upload(depth,dep.data(),4);upload(motion,mv.data(),4);
 auto evaluate=sym<ngx_direct::Eval>(core,"NVSDK_NGX_D3D12_EvaluateFeature");CreateDirectoryW(argv[4],nullptr);
 
 auto dump_textures=[&](unsigned frame){
  auto targets=history_d3d::textures;
  for(unsigned ti=0;ti<targets.size();ti++){auto*r=targets[ti];auto rd=r->GetDesc();if(rd.Width!=1920||rd.Height!=ORACLE_HEIGHT||(rd.Format!=DXGI_FORMAT_R16G16B16A16_FLOAT&&rd.Format!=DXGI_FORMAT_R32G32B32A32_FLOAT))continue;
   auto prev=history_d3d::states[r];D3D12_PLACED_SUBRESOURCE_FOOTPRINT fp{};UINT64 size=0;d->GetCopyableFootprints(&rd,0,1,0,&fp,nullptr,nullptr,&size);auto rb=buffer(size,D3D12_HEAP_TYPE_READBACK);
   al->Reset();l->Reset(al,nullptr);D3D12_RESOURCE_BARRIER br{};br.Type=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;br.Transition={r,D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,prev,D3D12_RESOURCE_STATE_COPY_SOURCE};if(prev!=D3D12_RESOURCE_STATE_COPY_SOURCE)l->ResourceBarrier(1,&br);
   D3D12_TEXTURE_COPY_LOCATION dst{},src{};dst.pResource=rb;dst.Type=D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;dst.PlacedFootprint=fp;src.pResource=r;src.Type=D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;l->CopyTextureRegion(&dst,0,0,0,&src,nullptr);
   if(prev!=D3D12_RESOURCE_STATE_COPY_SOURCE){std::swap(br.Transition.StateBefore,br.Transition.StateAfter);l->ResourceBarrier(1,&br);}l->Close();ID3D12CommandList*lists[]={l};q->ExecuteCommandLists(1,lists);wait();
   unsigned bpp=rd.Format==DXGI_FORMAT_R16G16B16A16_FLOAT?8:16;std::vector<unsigned char> raw(size_t(1920)*ORACLE_HEIGHT*bpp);void*map=nullptr;D3D12_RANGE rr{0,size_t(size)};ck(rb->Map(0,&rr,&map),"dump map");for(unsigned y=0;y<ORACLE_HEIGHT;y++)memcpy(raw.data()+size_t(y)*1920*bpp,static_cast<unsigned char*>(map)+fp.Offset+size_t(y)*fp.Footprint.RowPitch,size_t(1920)*bpp);rb->Unmap(0,nullptr);
   auto path=std::wstring(argv[4])+L"/frame"+std::to_wstring(frame)+L"-tex"+std::to_wstring(ti)+(bpp==8?L".rgba16f":L".rgba32f");std::ofstream f(path.c_str(),std::ios::binary);f.write(reinterpret_cast<char*>(raw.data()),raw.size());printf("DUMP frame=%u tex=%u resource=%p format=%u state=%u bytes=%llu\n",frame,ti,r,unsigned(rd.Format),unsigned(prev),(unsigned long long)raw.size());rb->Release();
  }
 };

 unsigned frame_id=0;for(const wchar_t*frame:{L"8678",L"8680"}){std::wstring path=std::wstring(argv[3])+L"/"+frame+L".rgba16f";std::ifstream inf(path.c_str(),std::ios::binary);std::vector<unsigned short>data(1920*ORACLE_HEIGHT*4);if(!inf.read(reinterpret_cast<char*>(data.data()),data.size()*2))return 11;
 if(frame[3]=='0'){al->Reset();l->Reset(al,nullptr);D3D12_RESOURCE_BARRIER b{};b.Transition={color,D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,D3D12_RESOURCE_STATE_COPY_DEST};l->ResourceBarrier(1,&b);l->Close();ID3D12CommandList*ls[]={l};q->ExecuteCommandLists(1,ls);wait();}upload(color,data.data(),8);
 for(int repeat=1;repeat<=1;repeat++){al->Reset();l->Reset(al,nullptr);ngx_direct::Evaluation(p,color,output,depth,motion,1920,ORACLE_HEIGHT);su(p,"DLSSNR.Style",1);su(p,"DLSSNR.UICorrection",0);su(p,"DLSSNR.Reset",frame_id==0?1:0);TemporalObserveFrame(frame_id);auto er=evaluate(l,reinterpret_cast<ngx_direct::Handle*>(h),p,nullptr);printf("EVAL frame=%ls repeat=%d result=%08x\n",frame,repeat,unsigned(er));if(er!=1)return 12;
l->Close();ID3D12CommandList*submitted[]={l};q->ExecuteCommandLists(1,submitted);wait();dump_textures(frame_id);
 }frame_id++;}return 0;}
