// Isolated D3D12 conversion via existing codec/input/motion shaders. No neural inference.
#include <windows.h>
#include <dxgi1_6.h>
#include <fstream>
#include <map>
#include <vector>
#include <string>
#include <cmath>
#include <cstring>
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
 if(argc!=2)throw std::runtime_error("replay-convert explicit-config.txt");std::wifstream f(argv[1]);std::wstring line;while(std::getline(f,line)){if(!line.empty()&&line.back()==L'\r')line.pop_back();auto eq=line.find(L'=');if(eq!=line.npos){if(!cfg.emplace(line.substr(0,eq),line.substr(eq+1)).second)throw std::runtime_error("duplicate conversion field");}}
 // All settings are explicit controlled-replay factors, not inferred game defaults.
 for(auto k:{L"DLSS5_NETWORK_HEIGHT",L"DLSS5_NETWORK_FREE_RES",L"DLSS5_NETWORK_1080_ROWS",L"DLSS5_CODEC_SRGB",L"DLSS5_FIT_LARGE"})_wputenv_s(k,required(k).c_str());
 _wputenv_s(L"DLSS5_TEST_ASYNC_SUBMIT",L"0");_wputenv_s(L"DLSS5_FAST_TEMPORAL",L"0");_wputenv_s(L"DLSS5_MOTION_MAX_PX",L"0");
 auto assets=required(L"assets");unsigned cw=number(L"color_width"),ch=number(L"color_height"),rw=number(L"render_width"),rh=number(L"render_height");
 if(cw!=rw||ch!=rh)throw std::runtime_error("color texture differs from render extent; explicit subrect adapter required");
 auto ng=NativeResolveNetworkGeometry(cw,ch);if(ng.processing_width!=ng.valid_width)throw std::runtime_error("current HIP warp cannot replay padded width");
 IDXGIFactory6*factory=nullptr;ck(CreateDXGIFactory2(0,IID_PPV_ARGS(&factory)));ID3D12Device*d=nullptr;
 for(UINT i=0;!d;i++){IDXGIAdapter1*a=nullptr;if(factory->EnumAdapterByGpuPreference(i,DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE,IID_PPV_ARGS(&a))==DXGI_ERROR_NOT_FOUND)break;DXGI_ADAPTER_DESC1 desc{};a->GetDesc1(&desc);if(desc.VendorId==0x1002)ck(D3D12CreateDevice(a,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d)));a->Release();}factory->Release();if(!d)throw std::runtime_error("AMD adapter unavailable");
 ID3D12CommandQueue*q=nullptr;D3D12_COMMAND_QUEUE_DESC qd{};ck(d->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)));NativeGameSubmission submit;submit.Create(q);
 auto*color=upload(d,submit,L"color"),*motion=upload(d,submit,L"motion");ID3D12Resource*exposure=nullptr;if(number(L"use_exposure"))exposure=upload(d,submit,L"exposure");
 {NativeGameCodec codec;codec.Create(d,{color},assets,false,exposure);NativeGameRgbInput input;input.Create(d,codec.Output(),assets,false);
 NativeCodecParameters parameters;parameters.pre_exposure=scalar(L"pre_exposure");parameters.exposure_scale=scalar(L"exposure_scale");parameters.transfer_strength=scalar(L"transfer_strength");parameters.color_strength=scalar(L"color_strength");float white=scalar(L"paper_white");
 const auto fit=codec.Geometry();float sign=scalar(L"motion_sign");if(sign!=1.f&&sign!=-1.f)throw std::runtime_error("explicit motion sign must be +/-1");float sx=scalar(L"motion_scale_x")*float(fit.fit_width)/rw*sign,sy=scalar(L"motion_scale_y")*float(fit.fit_height)/rh*sign;
 NativeTemporalFeed feed;unsigned mw=number(L"motion_width"),mh=number(L"motion_height");feed.Create(d,mw,mh,sx,sy,assets);
 float rx=float(rw)/fit.fit_width,ry=float(rh)/fit.fit_height;const float transform[]={-float(fit.x)*rx,-float(fit.y)*ry,fit.Adapted()?ng.valid_width*rx:float(rw),fit.Adapted()?ng.valid_height*ry:float(rh),1.f/ng.valid_width,1.f/ng.valid_height};const float viewport[]={float(fit.x),float(fit.y),float(fit.fit_width),float(fit.fit_height)};
 NativeTemporalCoordinates coords;coords.Create(d,feed.Motion(),ng.valid_width,ng.valid_height,ng.processing_width,ng.processing_height,mw,mh,transform,assets,true,fit.Adapted()?viewport:nullptr);
 submit.Submit([&](ID3D12GraphicsCommandList*c){std::vector<D3D12_RESOURCE_STATES> states{D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE};if(exposure)states.push_back(D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);codec.Record(c,states,white,parameters);input.Record(c,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);feed.RecordMotion(c,motion);coords.Record(c);});submit.Flush();
 auto encoded=readback(d,submit,input.PostBase(),size_t(ng.processing_width)*ng.processing_height*4);auto uv=readback(d,submit,coords.Output(),size_t(ng.processing_width)*ng.processing_height*2);std::vector<float>mv(size_t(ng.valid_width)*ng.valid_height*2);
 for(unsigned y=0;y<ng.valid_height;y++)for(unsigned x=0;x<ng.valid_width;x++){size_t a=(size_t(y)*ng.processing_width+x)*2,b=(size_t(y)*ng.valid_width+x)*2;mv[b]=uv[a]*ng.valid_width-(float(x)+.5f);mv[b+1]=uv[a+1]*ng.valid_height-(float(y)+.5f);}save(required(L"encoded_output"),encoded);save(required(L"motion_output"),mv);save(required(L"coordinates_output"),uv);
 std::ofstream receipt(required(L"receipt_output").c_str());receipt<<"valid_width="<<ng.valid_width<<"\nvalid_height="<<ng.valid_height<<"\nprocessing_height="<<ng.processing_height<<"\ncolor_policy=existing_codec_direct_fit_raw_FFX_not_FSR\nmotion_policy=existing_native_coordinates_UV_direct_for_replay_diagnostic_pixel_displacement_separate\nprivate_history_verified=false\nsource_seed_verified=false\ntiming_valid=false\n";if(!receipt)throw std::runtime_error("receipt write");}
 submit.Flush();if(exposure)exposure->Release();motion->Release();color->Release();q->Release();d->Release();std::puts("REPLAY_CONVERSION_PASS: controlled conversion only; not game/pre-FSR parity");return 0;
}catch(const std::exception&e){std::fprintf(stderr,"REPLAY_CONVERSION_FAIL %s\n",e.what());return 1;}}
