#define wmain unused_texture_test_wmain
#include "d3d12_native_game_rgb_test.cpp"
#undef wmain
#include "native_actual_network70.h"
#include "native_temporal_coordinates.h"
#include "native_temporal_sample.h"
#ifdef MATRIX_BENCH
extern "C" {__declspec(dllexport) extern const UINT D3D12SDKVersion=721;__declspec(dllexport) const char*D3D12SDKPath=".\\D3D12\\";}
#endif

int wmain(int argc,wchar_t**argv){try{if(argc!=4)return 2;std::wstring dir=argv[1];
 auto read=[](const std::wstring&path){std::ifstream f(path.c_str(),std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error("fixture missing");auto n=f.tellg();if(n<=0||size_t(n)%4)throw std::runtime_error("fixture size");std::vector<float>v(size_t(n)/4);f.seekg(0);if(!f.read(reinterpret_cast<char*>(v.data()),n))throw std::runtime_error("fixture truncated");return v;};
 auto history=read(std::wstring(argv[2])+L"\\history.f32"),motion=read(std::wstring(argv[2])+L"\\motion.f32"),reciprocals=read(std::wstring(argv[2])+L"\\normalized-output.f32");
 if(history.size()!=1920ull*1080*4||motion.size()!=history.size()||reciprocals.size()!=8388608)throw std::runtime_error("fixture sizes");
 IDXGIFactory6*f=nullptr;ck(CreateDXGIFactory2(0,IID_PPV_ARGS(&f)));ID3D12Device*d=nullptr;
 for(UINT i=0;;i++){IDXGIAdapter1*a=nullptr;if(f->EnumAdapterByGpuPreference(i,DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE,IID_PPV_ARGS(&a))==DXGI_ERROR_NOT_FOUND)break;DXGI_ADAPTER_DESC1 info{};a->GetDesc1(&info);if(info.VendorId==0x1002){ck(D3D12CreateDevice(a,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d)));a->Release();break;}a->Release();}if(!d)throw std::runtime_error("AMD missing");
 auto upload=[&](const std::vector<float>&v){auto*r=buf(d,v.size()*4,D3D12_HEAP_TYPE_UPLOAD,D3D12_RESOURCE_STATE_GENERIC_READ);void*p=nullptr;D3D12_RANGE none{};ck(r->Map(0,&none,&p));std::memcpy(p,v.data(),v.size()*4);r->Unmap(0,nullptr);return r;};
  NativeTemporalCoordinates*coordinates=nullptr;NativeTemporalSample*sampler=nullptr;
 {
  auto*mv=upload(motion);auto*h=upload(history);auto*rcp=upload(reciprocals);
  coordinates=new NativeTemporalCoordinates;const float transform[]={0,0,1920,1080,1.f/1920,1.f/1080};
  coordinates->Create(d,mv,1920,1080,1920,1152,1920,1080,transform,dir,true);
  sampler=new NativeTemporalSample;sampler->Create(d,h,coordinates->Output(),1920,1080,1920*1152,dir,true,rcp);
  mv->Release();h->Release();rcp->Release();
 }

 ID3D12CommandQueue*q=nullptr;D3D12_COMMAND_QUEUE_DESC qd{};ck(d->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)));NativeGameSubmission submit;submit.Create(q);
 auto*rb=buf(d,1920ull*1152*16,D3D12_HEAP_TYPE_READBACK,D3D12_RESOURCE_STATE_COPY_DEST);
 submit.Submit([&](ID3D12GraphicsCommandList*c){coordinates->Record(c);sampler->Record(c);auto*out=sampler->Output();D3D12_RESOURCE_BARRIER b{};b.Type=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;b.Transition={out,D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,D3D12_RESOURCE_STATE_COPY_SOURCE};c->ResourceBarrier(1,&b);c->CopyBufferRegion(rb,0,out,0,1920ull*1152*16);});
 void*p=nullptr;D3D12_RANGE range{0,1920ull*1152*16},none{};ck(rb->Map(0,&range,&p));std::ofstream out(argv[3],std::ios::binary);out.write((char*)p,range.End);if(!out)throw std::runtime_error("write");rb->Unmap(0,&none);puts("exact-shader sampled history written");return 0;
 }catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 1;}}
