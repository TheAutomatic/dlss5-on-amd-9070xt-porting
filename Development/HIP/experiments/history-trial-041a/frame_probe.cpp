#define DLSS5_USE_HIP 1
#define DLSS5_BENCH_BRIDGE_ISOLATE 1
// Isolated D3D12 conversion via existing codec/input/motion shaders. No neural inference.
#include <windows.h>
#include <dxgi1_6.h>
#include <fstream>
#include <map>
#include <vector>
#include <string>
#include <cmath>
#include <cstring>
#include "native_game_frame.h"
#include "native_game_codec.h"
#include "native_game_rgb_input.h"
#include "native_temporal_feed.h"
#include "native_temporal_coordinates.h"
#include "native_game_submission.h"
static void ck(HRESULT h){if(FAILED(h))throw std::runtime_error("D3D conversion HRESULT="+std::to_string(unsigned(h)));}
static std::map<std::wstring,std::wstring> cfg;
static std::wstring required(const wchar_t*k){auto i=cfg.find(k);if(i==cfg.end()||i->second.empty())throw std::runtime_error("missing explicit conversion field");return i->second;}
static unsigned number(const wchar_t*k){return unsigned(std::stoul(required(k)));}
static float scalar(const wchar_t*k){float v=std::stof(required(k));if(!std::isfinite(v))throw std::runtime_error("nonfinite conversion field");return v;}
static std::vector<char> bytes(const std::wstring&p){std::ifstream f(p.c_str(),std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("raw read");std::vector<char>b(size_t(f.tellg()));f.seekg(0);if(!f.read(b.data(),b.size()))throw std::runtime_error("raw short read");return b;}
static void transition(ID3D12GraphicsCommandList*c,ID3D12Resource*r,D3D12_RESOURCE_STATES a,D3D12_RESOURCE_STATES b){D3D12_RESOURCE_BARRIER x{};x.Type=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;x.Transition={r,D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,a,b};c->ResourceBarrier(1,&x);}
static ID3D12Resource*buffer(ID3D12Device*d,UINT64 n,D3D12_HEAP_TYPE ht){D3D12_HEAP_PROPERTIES hp{};hp.Type=ht;D3D12_RESOURCE_DESC rd{};rd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;rd.Width=n;rd.Height=1;rd.DepthOrArraySize=rd.MipLevels=1;rd.SampleDesc.Count=1;rd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;ID3D12Resource*r=nullptr;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&rd,ht==D3D12_HEAP_TYPE_UPLOAD?D3D12_RESOURCE_STATE_GENERIC_READ:D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&r)));return r;}
static ID3D12Resource*upload(ID3D12Device*d,NativeGameSubmission&s,const wchar_t*role){
 const auto name=std::wstring(role);auto key=[&](const wchar_t*tail){return name+tail;};
 unsigned w=number(key(L"_width").c_str()),h=number(key(L"_height").c_str()),row=number(key(L"_row_bytes").c_str());
 auto b=bytes(required(key(L"_path").c_str()));if(b.size()!=size_t(row)*h)throw std::runtime_error("raw byte geometry");
 D3D12_RESOURCE_DESC rd{};rd.Dimension=D3D12_RESOURCE_DIMENSION_TEXTURE2D;rd.Width=w;rd.Height=h;rd.DepthOrArraySize=rd.MipLevels=1;rd.Format=DXGI_FORMAT(number(key(L"_format").c_str()));rd.SampleDesc.Count=1;
 D3D12_HEAP_PROPERTIES hp{};hp.Type=D3D12_HEAP_TYPE_DEFAULT;ID3D12Resource*r=nullptr;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&rd,D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&r)));
 D3D12_PLACED_SUBRESOURCE_FOOTPRINT fp{};UINT rows{};UINT64 rowbytes{},size{};d->GetCopyableFootprints(&rd,0,1,0,&fp,&rows,&rowbytes,&size);if(rows!=h||rowbytes!=row)throw std::runtime_error("unsupported texture row layout");
 auto*u=buffer(d,size,D3D12_HEAP_TYPE_UPLOAD);void*p;D3D12_RANGE none{};ck(u->Map(0,&none,&p));for(unsigned y=0;y<h;y++)memcpy(static_cast<char*>(p)+fp.Offset+size_t(y)*fp.Footprint.RowPitch,b.data()+size_t(y)*row,row);u->Unmap(0,nullptr);
 s.Submit([&](ID3D12GraphicsCommandList*c){D3D12_TEXTURE_COPY_LOCATION a{},z{};a.pResource=r;a.Type=D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;z.pResource=u;z.Type=D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;z.PlacedFootprint=fp;c->CopyTextureRegion(&a,0,0,0,&z,nullptr);transition(c,r,D3D12_RESOURCE_STATE_COPY_DEST,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);});s.Flush();u->Release();return r;
}
static std::vector<float>readback(ID3D12Device*d,NativeGameSubmission&s,ID3D12Resource*src,size_t count){auto*rb=buffer(d,count*4,D3D12_HEAP_TYPE_READBACK);s.Submit([&](ID3D12GraphicsCommandList*c){transition(c,src,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,D3D12_RESOURCE_STATE_COPY_SOURCE);c->CopyBufferRegion(rb,0,src,0,count*4);transition(c,src,D3D12_RESOURCE_STATE_COPY_SOURCE,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);});s.Flush();void*p;D3D12_RANGE range{0,count*4};ck(rb->Map(0,&range,&p));std::vector<float>v(count);memcpy(v.data(),p,count*4);rb->Unmap(0,nullptr);rb->Release();for(float x:v)if(!std::isfinite(x))throw std::runtime_error("nonfinite converted input");return v;}
static void save(const std::wstring&path,const std::vector<float>&v){std::ofstream f(path.c_str(),std::ios::binary);if(!f.write(reinterpret_cast<const char*>(v.data()),v.size()*4))throw std::runtime_error("converted output write");}
int wmain(int argc,wchar_t**argv){try{
 if(argc!=2)throw std::runtime_error("frame-gate fixture config");std::wifstream file(argv[1]);std::wstring line;while(std::getline(file,line)){if(!line.empty()&&line.back()==L'\r')line.pop_back();if(line.empty()||line[0]==L'#')continue;auto eq=line.find(L'=');if(eq!=line.npos)cfg[line.substr(0,eq)]=line.substr(eq+1);}
 for(auto&entry:cfg)if(entry.first.rfind(L"DLSS5_",0)==0)_wputenv_s(entry.first.c_str(),entry.second.c_str());
 auto assets=required(L"assets");IDXGIFactory6*factory=nullptr;ck(CreateDXGIFactory2(0,IID_PPV_ARGS(&factory)));ID3D12Device*d=nullptr;
 for(UINT i=0;!d;i++){IDXGIAdapter1*a=nullptr;if(factory->EnumAdapterByGpuPreference(i,DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE,IID_PPV_ARGS(&a))==DXGI_ERROR_NOT_FOUND)break;DXGI_ADAPTER_DESC1 desc{};a->GetDesc1(&desc);if(desc.VendorId==0x1002)ck(D3D12CreateDevice(a,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d)));a->Release();}factory->Release();if(!d)throw std::runtime_error("AMD adapter");ID3D12CommandQueue*q=nullptr;D3D12_COMMAND_QUEUE_DESC qd{};ck(d->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)));NativeGameSubmission submit;submit.Create(q);
 auto*color=upload(d,submit,L"color"),*motion=upload(d,submit,L"motion");unsigned w=number(L"color_width"),h=number(L"color_height");std::vector<std::vector<float>>baseline;
 auto restore=[&](){auto*fresh=upload(d,submit,L"color");submit.Submit([&](ID3D12GraphicsCommandList*c){transition(c,color,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,D3D12_RESOURCE_STATE_COPY_DEST);transition(c,fresh,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,D3D12_RESOURCE_STATE_COPY_SOURCE);c->CopyResource(color,fresh);transition(c,color,D3D12_RESOURCE_STATE_COPY_DEST,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);transition(c,fresh,D3D12_RESOURCE_STATE_COPY_SOURCE,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);});submit.Flush();fresh->Release();};
 const unsigned nframes=9;for(unsigned side=0;side<2;side++){
  _wputenv_s(L"DLSS5_TEMPORAL_HISTORY_EXPERIMENT",side?L"1":L"0");_wputenv_s(L"DLSS5_TEMPORAL_MV_UNJITTERED",L"1");_wputenv_s(L"DLSS5_MULTI_PASS",L"1");
  NativeGameFrame frame;NativeGameFrame::TemporalConfig tc{number(L"motion_width"),number(L"motion_height"),w,h,true,scalar(L"motion_scale_x"),scalar(L"motion_scale_y")};std::vector<float>noise;frame.Create(q,color,noise,assets,nullptr,side?&tc:nullptr);
  for(unsigned i=0;i<nframes;i++){
   restore();bool reset=i==0||i==2;bool missing=i==3;
   NativeTemporalFrameMetadata metadata;metadata.ffx_pre=true;metadata.frame_id=i>=6?i+1:i;metadata.pre_exposure=i>=5?2.f:1.f;metadata.motion_scale[0]=scalar(L"motion_scale_x");metadata.motion_scale[1]=scalar(L"motion_scale_y");frame.ExperimentalFrameMetadata(metadata);
   if(i==7)_wputenv_s(L"DLSS5_MULTI_PASS",L"3");if(i==8)_wputenv_s(L"DLSS5_MULTI_PASS",L"1");
   frame.ProcessSubmittedFrame(color,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,0,false,side&&!missing?motion:nullptr,reset);
   submit.Submit([](ID3D12GraphicsCommandList*){});submit.Flush();auto geometry=NativeCurrentNetworkGeometry();auto result=readback(d,submit,frame.DiagnosticOutput(),size_t(geometry.processing_width)*geometry.processing_height*3);
   if(!side)baseline.push_back(result);else if(i==0||i==2||i==3||i==4||i==5||i==6||i==7||i==8){size_t diff=0;for(size_t j=0;j<result.size();j++)diff+=memcmp(&result[j],&baseline[i][j],4)!=0;printf("FRAME_CONTRACT frame=%u first_reset_gap_missing_hot=%u float_bitdiff=%zu\n",i,1u,diff);if(diff)throw std::runtime_error("frame cold/fallback mismatch");}
  }
 }
 submit.Flush();motion->Release();color->Release();q->Release();d->Release();puts("FRAME_CONTRACT_PASS synthetic FFX metadata; no game deployment");return 0;
}catch(const std::exception&e){fprintf(stderr,"FRAME_CONTRACT_FAIL %s\n",e.what());return 1;}}
