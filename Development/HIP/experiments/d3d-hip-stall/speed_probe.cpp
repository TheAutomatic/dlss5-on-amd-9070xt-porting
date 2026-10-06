// HIP<->D3D12 handoff cost probe (2026-09-30, handoff-poll).
// Same mechanism as hip_d3d12_bridge.h Enqueue: D3D Signal(shared fence) -> HIP WaitExternalSemaphore
// -> HIP work -> HIP SignalExternalSemaphore -> D3D queue Wait -> D3D work.
// D3D timestamps (one clock) bracket the HIP section: gap = t(after D3D Wait) - t(before D3D Signal).
// HIP events bracket the HIP work only (after the wait, before the signal), like DLSS5_HIP_SPAN_PROBE.
// handoff = gap - hip_work. Control mode: same D3D lists back to back without HIP (list boundary cost).
// usage: handoff_probe.exe <mode> <memset MiB> <iterations>
// modes: 0 control (no HIP), 1 fence both ways (current bridge), 2 HIP unsynced (time only),
//        3 D3D->HIP by WriteBufferImmediate + hipStreamWaitValue32 (GPU poll), HIP->D3D fence,
//        4 D3D->HIP fence, HIP->D3D by hipStreamWriteValue32 + D3D spin compute shader (GPU poll),
//        5 both directions GPU poll,
//        6 D3D->HIP fence, HIP->D3D by hipStreamWriteValue32 + predicated 1-pixel draw spin slices (Daniel's SpinDraw),
//        7 both directions GPU poll with draw slices. Env: PROBE_SLICES (64), PROBE_ITER (per slice, 4096).
//        Slice timeouts (frames whose last slice gave up) are counted at flag+128 and printed.
#define WIN32_LEAN_AND_MEAN
#include "hip_api.h"
#include <d3d12.h>
#include <dxgi1_6.h>
#include <vector>
#include <chrono>
#include <cmath>
#include <algorithm>
#include <cstring>
#include <cstdio>
#include <d3dcompiler.h>
using namespace hip_probe;
static void ck(HRESULT h,const char*s){if(FAILED(h))throw std::runtime_error(std::string(s)+" hr="+std::to_string(unsigned(h)));}
static double pct(std::vector<double>v,double p){std::sort(v.begin(),v.end());return v[std::min(v.size()-1,size_t(p*(v.size()-1)+.5))];}
int main(int argc,char**argv){try{
 const int mode=argc>1?std::stoi(argv[1]):1;const size_t mib=argc>2?std::stoul(argv[2]):64;const unsigned iters=argc>3?unsigned(std::stoul(argv[3])):1000;
 if(mode!=1)throw std::runtime_error("this speed experiment only permits correct fence mode1; no GPU polling/spin modes");
 const unsigned pacing_ms=getenv("STALL_PACE_MS")?unsigned(std::stoul(getenv("STALL_PACE_MS"))):0;
 Api hip(7);auto queryEvent=reinterpret_cast<int(*)(Handle)>(GetProcAddress(hip.dll,"hipEventQuery"));if(getenv("STALL_QUERY_END")&&!queryEvent)throw std::runtime_error("hipEventQuery missing");hip.Check(hip.hipInit(0),"hipInit");int count=0;hip.Check(hip.hipGetDeviceCount(&count),"count");
 IDXGIFactory4*factory=nullptr;ck(CreateDXGIFactory1(IID_PPV_ARGS(&factory)),"factory");IDXGIAdapter1*adapter=nullptr;int ordinal=-1;
 for(unsigned i=0;!adapter;i++){IDXGIAdapter1*a=nullptr;if(factory->EnumAdapters1(i,&a)==DXGI_ERROR_NOT_FOUND)break;DXGI_ADAPTER_DESC1 desc{};a->GetDesc1(&desc);if(desc.VendorId==0x1002){char dn[256]{};WideCharToMultiByte(CP_UTF8,0,desc.Description,-1,dn,256,nullptr,nullptr);for(int n=0;n<count;n++){char hn[256]{};hip.Check(hip.hipDeviceGetName(hn,256,n),"name");if(!strcmp(dn,hn)){adapter=a;ordinal=n;break;}}}if(!adapter)a->Release();}
 if(!adapter)throw std::runtime_error("no AMD adapter");hip.Check(hip.hipSetDevice(ordinal),"set device");
 ID3D12Device*d=nullptr;ck(D3D12CreateDevice(adapter,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d)),"device");
 D3D12_COMMAND_QUEUE_DESC qd{};ID3D12CommandQueue*q=nullptr;ck(d->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)),"queue");UINT64 freq=0;ck(q->GetTimestampFrequency(&freq),"freq");
 ID3D12Fence*fence=nullptr;ck(d->CreateFence(0,D3D12_FENCE_FLAG_SHARED,IID_PPV_ARGS(&fence)),"fence");HANDLE fh=nullptr;ck(d->CreateSharedHandle(fence,nullptr,GENERIC_ALL,nullptr,&fh),"fence handle");
 SemaphoreDesc sd{};sd.type=4;sd.handle.win32.handle=fh;Handle sem=nullptr;hip.Check(hip.hipImportExternalSemaphore(&sem,&sd),"import fence");Handle stream=nullptr;hip.Check(hip.hipStreamCreate(&stream),"stream");
 void*buf=nullptr;hip.Check(hip.hipMalloc(&buf,mib<<20),"hip buffer");
 // Shared flag buffer (D3D-owned, imported into HIP), 256 B: [0]=D3D->HIP flag, [64]=HIP->D3D flag.
 D3D12_RESOURCE_DESC fd{};fd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;fd.Width=65536;fd.Height=1;fd.DepthOrArraySize=fd.MipLevels=1;fd.SampleDesc.Count=1;fd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;fd.Flags=D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
 D3D12_HEAP_PROPERTIES dp{};dp.Type=D3D12_HEAP_TYPE_DEFAULT;ID3D12Resource*flagbuf=nullptr;ck(d->CreateCommittedResource(&dp,D3D12_HEAP_FLAG_SHARED,&fd,D3D12_RESOURCE_STATE_COMMON,nullptr,IID_PPV_ARGS(&flagbuf)),"flag buffer");HANDLE flh=nullptr;ck(d->CreateSharedHandle(flagbuf,nullptr,GENERIC_ALL,nullptr,&flh),"flag handle");
 auto finfo=d->GetResourceAllocationInfo(0,1,&fd);MemoryDesc md{};md.type=5;md.handle.win32.handle=flh;md.size=finfo.SizeInBytes;md.flags=1;Handle fext=nullptr;hip.Check(hip.hipImportExternalMemory(&fext,&md),"import flag");BufferDesc bd{};bd.size=65536;void*flag=nullptr;hip.Check(hip.hipExternalMemoryGetMappedBuffer(&flag,fext,&bd),"map flag");hip.Check(hip.hipMemsetAsync(flag,0,65536,stream),"zero flag");hip.Check(hip.hipStreamSynchronize(stream),"zero sync");
 HMODULE hm=GetModuleHandleA("amdhip64_7.dll");if(!hm)hm=GetModuleHandleA("amdhip64_6.dll");if(!hm)throw std::runtime_error("amdhip64 module");
 auto waitValue=reinterpret_cast<int(*)(Handle,void*,unsigned,unsigned,unsigned)>(GetProcAddress(hm,"hipStreamWaitValue32"));auto writeValue=reinterpret_cast<int(*)(Handle,void*,unsigned,unsigned)>(GetProcAddress(hm,"hipStreamWriteValue32"));auto memsetD32=reinterpret_cast<int(*)(void*,int,size_t,Handle)>(GetProcAddress(hm,"hipMemsetD32Async"));const bool useMemset=getenv("PROBE_MEMSET_FLAG")!=nullptr;if(!waitValue||!writeValue||!memsetD32)throw std::runtime_error("stream value API missing");
 const char*hlsl="RWByteAddressBuffer F:register(u0);cbuffer C:register(b0){uint target;};[numthreads(1,1,1)]void main(){uint v=0;[allow_uav_condition]for(uint i=0;i<(1u<<22);i++){F.InterlockedAdd(64,0,v);if(v>=target)break;}if(v<target)F.InterlockedAdd(128,1);}";
 ID3DBlob*cs=nullptr,*er=nullptr;ck(D3DCompile(hlsl,strlen(hlsl),"spin",nullptr,nullptr,"main","cs_5_0",0,0,&cs,&er),"compile spin");
 D3D12_ROOT_PARAMETER rp[2]{};rp[0].ParameterType=D3D12_ROOT_PARAMETER_TYPE_UAV;rp[0].Descriptor.ShaderRegister=0;rp[1].ParameterType=D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;rp[1].Constants.ShaderRegister=0;rp[1].Constants.Num32BitValues=1;
 D3D12_ROOT_SIGNATURE_DESC rsd{};rsd.NumParameters=2;rsd.pParameters=rp;ID3DBlob*rsb=nullptr;ck(D3D12SerializeRootSignature(&rsd,D3D_ROOT_SIGNATURE_VERSION_1,&rsb,&er),"serialize rs");ID3D12RootSignature*rs=nullptr;ck(d->CreateRootSignature(0,rsb->GetBufferPointer(),rsb->GetBufferSize(),IID_PPV_ARGS(&rs)),"rs");
 D3D12_COMPUTE_PIPELINE_STATE_DESC pd{};pd.pRootSignature=rs;pd.CS={cs->GetBufferPointer(),cs->GetBufferSize()};ID3D12PipelineState*pso=nullptr;ck(d->CreateComputePipelineState(&pd,IID_PPV_ARGS(&pso)),"pso");
 const bool pollIn=mode==3||mode==5||mode==7,pollOut=mode==4||mode==5,slices=mode==6||mode==7;
 const unsigned nSlices=getenv("PROBE_SLICES")?unsigned(atoi(getenv("PROBE_SLICES"))):64,sliceIter=getenv("PROBE_ITER")?unsigned(atoi(getenv("PROBE_ITER"))):4096;
 // Draw-slice spin: VS covers pixel (0,0); PS spins <=iter atomic reads of flag+64; on success stores 1 to the frame's
 // predication word (flag+256), so the remaining slices are predicated away (NOT_EQUAL_ZERO skips). Last slice counts timeouts.
 const char*vsh="float4 main(uint id:SV_VertexID):SV_Position{return float4(id==1?3:-1,id==2?3:-1,0,1);}";
 const char*psh="RWByteAddressBuffer F:register(u0);cbuffer C:register(b0){uint target;uint iter;uint last;};void main(){uint v=0;F.InterlockedAdd(64,0,v);[allow_uav_condition]for(uint i=0;i<iter&&v<target;i++)F.InterlockedAdd(64,0,v);if(v>=target)F.Store(256,1u);else if(last)F.InterlockedAdd(128,1);}";
 ID3DBlob*vsb=nullptr,*psb=nullptr;ck(D3DCompile(vsh,strlen(vsh),"vs",nullptr,nullptr,"main","vs_5_0",0,0,&vsb,&er),"compile vs");ck(D3DCompile(psh,strlen(psh),"ps",nullptr,nullptr,"main","ps_5_0",0,0,&psb,&er),"compile ps");
 D3D12_ROOT_PARAMETER gp[2]{};gp[0].ParameterType=D3D12_ROOT_PARAMETER_TYPE_UAV;gp[0].Descriptor.ShaderRegister=0;gp[1].ParameterType=D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;gp[1].Constants.ShaderRegister=0;gp[1].Constants.Num32BitValues=3;
 D3D12_ROOT_SIGNATURE_DESC gsd{};gsd.NumParameters=2;gsd.pParameters=gp;ID3DBlob*gsb=nullptr;ck(D3D12SerializeRootSignature(&gsd,D3D_ROOT_SIGNATURE_VERSION_1,&gsb,&er),"serialize grs");ID3D12RootSignature*grs=nullptr;ck(d->CreateRootSignature(0,gsb->GetBufferPointer(),gsb->GetBufferSize(),IID_PPV_ARGS(&grs)),"grs");
 D3D12_GRAPHICS_PIPELINE_STATE_DESC gd{};gd.pRootSignature=grs;gd.VS={vsb->GetBufferPointer(),vsb->GetBufferSize()};gd.PS={psb->GetBufferPointer(),psb->GetBufferSize()};gd.SampleMask=~0u;gd.RasterizerState.FillMode=D3D12_FILL_MODE_SOLID;gd.RasterizerState.CullMode=D3D12_CULL_MODE_NONE;gd.RasterizerState.DepthClipEnable=TRUE;gd.PrimitiveTopologyType=D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;gd.SampleDesc.Count=1;gd.BlendState.RenderTarget[0].RenderTargetWriteMask=0;
 ID3D12PipelineState*gpso=nullptr;ck(d->CreateGraphicsPipelineState(&gd,IID_PPV_ARGS(&gpso)),"graphics pso");
 D3D12_QUERY_HEAP_DESC hd{};hd.Type=D3D12_QUERY_HEAP_TYPE_TIMESTAMP;hd.Count=2*iters;ID3D12QueryHeap*heap=nullptr;ck(d->CreateQueryHeap(&hd,IID_PPV_ARGS(&heap)),"query heap");
 D3D12_RESOURCE_DESC rd{};rd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;rd.Width=16ull*iters;rd.Height=1;rd.DepthOrArraySize=rd.MipLevels=1;rd.SampleDesc.Count=1;rd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;D3D12_HEAP_PROPERTIES hp{};hp.Type=D3D12_HEAP_TYPE_READBACK;ID3D12Resource*rb=nullptr;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&rd,D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&rb)),"readback");
 std::vector<ID3D12CommandAllocator*>al(2*iters+1);std::vector<ID3D12GraphicsCommandList*>cl(2*iters+1);
 for(size_t i=0;i<cl.size();i++){ck(d->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT,IID_PPV_ARGS(&al[i])),"alloc");ck(d->CreateCommandList(0,D3D12_COMMAND_LIST_TYPE_DIRECT,al[i],nullptr,IID_PPV_ARGS(&cl[i])),"list");
  if(i<2*iters){const unsigned it=unsigned(i/2)+1;
   if(i%2==1&&pollOut){cl[i]->SetComputeRootSignature(rs);cl[i]->SetPipelineState(pso);cl[i]->SetComputeRootUnorderedAccessView(0,flagbuf->GetGPUVirtualAddress());cl[i]->SetComputeRoot32BitConstant(1,it,0);cl[i]->Dispatch(1,1,1);D3D12_RESOURCE_BARRIER ub{};ub.Type=D3D12_RESOURCE_BARRIER_TYPE_UAV;ub.UAV.pResource=flagbuf;cl[i]->ResourceBarrier(1,&ub);}
   if(i%2==1&&slices){ID3D12GraphicsCommandList2*c2=nullptr;ck(cl[i]->QueryInterface(IID_PPV_ARGS(&c2)),"list2");D3D12_WRITEBUFFERIMMEDIATE_PARAMETER wp[2]{{flagbuf->GetGPUVirtualAddress()+256,0},{flagbuf->GetGPUVirtualAddress()+260,0}};D3D12_WRITEBUFFERIMMEDIATE_MODE wm[2]{};c2->WriteBufferImmediate(2,wp,wm);c2->Release();
    D3D12_RESOURCE_BARRIER ub{};ub.Type=D3D12_RESOURCE_BARRIER_TYPE_UAV;ub.UAV.pResource=flagbuf;cl[i]->ResourceBarrier(1,&ub);
    cl[i]->SetGraphicsRootSignature(grs);cl[i]->SetPipelineState(gpso);cl[i]->SetGraphicsRootUnorderedAccessView(0,flagbuf->GetGPUVirtualAddress());cl[i]->SetGraphicsRoot32BitConstant(1,it,0);cl[i]->SetGraphicsRoot32BitConstant(1,sliceIter,1);
    cl[i]->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);D3D12_VIEWPORT vp{0,0,1,1,0,1};D3D12_RECT sc{0,0,1,1};cl[i]->RSSetViewports(1,&vp);cl[i]->RSSetScissorRects(1,&sc);cl[i]->OMSetRenderTargets(0,nullptr,FALSE,nullptr);
    cl[i]->SetPredication(flagbuf,256,D3D12_PREDICATION_OP_NOT_EQUAL_ZERO);
    for(unsigned k=0;k<nSlices;k++){cl[i]->SetGraphicsRoot32BitConstant(1,k+1==nSlices,2);cl[i]->DrawInstanced(3,1,0,0);cl[i]->ResourceBarrier(1,&ub);}
    cl[i]->SetPredication(nullptr,0,D3D12_PREDICATION_OP_EQUAL_ZERO);}
   cl[i]->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,UINT(i));
   if(i%2==0&&pollIn){ID3D12GraphicsCommandList2*c2=nullptr;ck(cl[i]->QueryInterface(IID_PPV_ARGS(&c2)),"list2");D3D12_WRITEBUFFERIMMEDIATE_PARAMETER wp{flagbuf->GetGPUVirtualAddress(),it};D3D12_WRITEBUFFERIMMEDIATE_MODE wm=D3D12_WRITEBUFFERIMMEDIATE_MODE_MARKER_OUT;c2->WriteBufferImmediate(1,&wp,&wm);c2->Release();}}
  else cl[i]->ResolveQueryData(heap,D3D12_QUERY_TYPE_TIMESTAMP,0,2*iters,rb,0);ck(cl[i]->Close(),"close");}
 std::vector<Handle>eb(iters),ee(iters);for(unsigned i=0;i<iters;i++){hip.Check(hip.hipEventCreate(&eb[i]),"ev");hip.Check(hip.hipEventCreate(&ee[i]),"ev");}
 UINT64 v=0;HANDLE done=CreateEventW(nullptr,FALSE,FALSE,nullptr);
 // Pace like a game: CPU waits for iteration i-2 before submitting i (two frames in flight).
 std::vector<UINT64>endv(iters);
 auto cpu_start=std::chrono::steady_clock::now();
 for(unsigned i=0;i<iters;i++){if(pacing_ms)Sleep(pacing_ms);
  if(i>=2){if(fence->GetCompletedValue()<endv[i-2]){ck(fence->SetEventOnCompletion(endv[i-2],done),"event");if(WaitForSingleObject(done,10000)!=WAIT_OBJECT_0)throw std::runtime_error("timeout");}}
  ID3D12CommandList*a[]={cl[2*i]};q->ExecuteCommandLists(1,a);
  if(mode==1||mode>=3){
   if(pollIn)hip.Check(waitValue(stream,flag,i+1,0/*GEQ*/,0xffffffffu),"wait value");
   else{ck(q->Signal(fence,++v),"signal in");WaitParams w{};w.params.fence.value=v;hip.Check(hip.hipWaitExternalSemaphoresAsync(&sem,&w,1,stream),"hip wait");}
   hip.Check(hip.hipEventRecord(eb[i],stream),"eb");hip.Check(hip.hipMemsetAsync(buf,int(i&255),mib<<20,stream),"memset");hip.Check(hip.hipEventRecord(ee[i],stream),"ee");if(getenv("STALL_QUERY_END"))queryEvent(ee[i]);
   if(pollOut||slices){if(useMemset)hip.Check(memsetD32(static_cast<char*>(flag)+64,int(i+1),1,stream),"memsetD32 flag");else hip.Check(writeValue(stream,static_cast<char*>(flag)+64,i+1,0),"write value");}
   else{SignalParams s{};s.params.fence.value=++v;hip.Check(hip.hipSignalExternalSemaphoresAsync(&sem,&s,1,stream),"hip signal");ck(q->Wait(fence,v),"d3d wait");}}
  else if(mode==2){ // HIP work unsynchronised with D3D (no handoff), just to time it
   hip.Check(hip.hipEventRecord(eb[i],stream),"eb");hip.Check(hip.hipMemsetAsync(buf,int(i&255),mib<<20,stream),"memset");hip.Check(hip.hipEventRecord(ee[i],stream),"ee");if(getenv("STALL_QUERY_END"))queryEvent(ee[i]);}
  if(getenv("PROBE_PRESYNC"))hip.Check(hip.hipStreamSynchronize(stream),"presync");
  ID3D12CommandList*b[]={cl[2*i+1]};q->ExecuteCommandLists(1,b);ck(q->Signal(fence,++v),"signal end");endv[i]=v;
 }
 ID3D12CommandList*r[]={cl[2*iters]};q->ExecuteCommandLists(1,r);ck(q->Signal(fence,++v),"final");ck(fence->SetEventOnCompletion(v,done),"final ev");if(WaitForSingleObject(done,30000)!=WAIT_OBJECT_0)throw std::runtime_error("final timeout");hip.Check(hip.hipStreamSynchronize(stream),"hip sync");
 if(slices){ID3D12Resource*rb2=nullptr;D3D12_RESOURCE_DESC r2=rd;r2.Width=512;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&r2,D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&rb2)),"rb2");ID3D12CommandAllocator*a2=nullptr;ID3D12GraphicsCommandList*l2=nullptr;ck(d->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT,IID_PPV_ARGS(&a2)),"a2");ck(d->CreateCommandList(0,D3D12_COMMAND_LIST_TYPE_DIRECT,a2,nullptr,IID_PPV_ARGS(&l2)),"l2");l2->CopyBufferRegion(rb2,0,flagbuf,0,512);ck(l2->Close(),"c2");ID3D12CommandList*x[]={l2};q->ExecuteCommandLists(1,x);ck(q->Signal(fence,++v),"s2");ck(fence->SetEventOnCompletion(v,done),"e2");WaitForSingleObject(done,10000);unsigned*u=nullptr;D3D12_RANGE r0{0,512};ck(rb2->Map(0,&r0,(void**)&u),"m2");printf("slice_timeouts=%u flag=%u slices=%u iter=%u ",u[32],u[16],nSlices,sliceIter);}
 UINT64*t=nullptr;D3D12_RANGE range{0,16ull*iters};ck(rb->Map(0,&range,(void**)&t),"map");std::vector<double>gap,work,hand;
 for(unsigned i=iters/10;i<iters;i++){double g=double(t[2*i+1]-t[2*i])*1e3/freq;gap.push_back(g);if(mode){float ms=0;hip.Check(hip.hipEventElapsedTime(&ms,eb[i],ee[i]),"elapsed");work.push_back(ms);hand.push_back(g-ms);}}
 unsigned invalid=0;for(double ms:work)invalid+=!(ms>0)||!std::isfinite(ms);
 auto mean=[](const std::vector<double>&x){double s=0;for(double y:x)s+=y;return x.empty()?0:s/x.size();};
 printf("mode=%d mib=%zu iters=%u n=%zu gap_mean=%.4f gap_p50=%.4f gap_p99=%.4f",mode,mib,iters,gap.size(),mean(gap),pct(gap,.5),pct(gap,.99));
 printf(" invalid_hip_duration=%u query_end=%u",invalid,unsigned(getenv("STALL_QUERY_END")!=nullptr));
 printf(" pacing_ms=%u cpu_wall_per_frame_ms=%.4f",pacing_ms,std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-cpu_start).count()/iters);
 if(mode)printf(" hip_work_mean=%.4f handoff_mean=%.4f handoff_p50=%.4f handoff_p99=%.4f",mean(work),mean(hand),pct(hand,.5),pct(hand,.99));printf(" ms\n");
 return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 1;}}
