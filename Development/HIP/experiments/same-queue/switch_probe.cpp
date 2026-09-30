// Context-switch cost probe (2026-10-01, same-queue).
// Question: how much of the D3D<->HIP handoff is "leaving the D3D queue" (any cross-queue fence) and how much is
// "leaving the D3D API/context" (HIP runs as a separate WDDM context)? Per frame, the game DIRECT queue writes a
// timestamp, then hands off K times to an executor that does W/K of a memory fill, each round being
// Signal(fence) -> executor Wait -> fill -> executor Signal -> DIRECT Wait; then the DIRECT queue writes a timestamp.
// gap = t_end - t_begin (one clock). Executors:
//   0  same DIRECT queue, no fence (the fill is just recorded inline)          -> "same queue" ideal
//   1  a second D3D12 COMPUTE queue in the same device                        -> cross-queue, same context
//   2  a second D3D12 DIRECT queue in the same device                         -> cross-queue, same context
//   3  HIP stream, external semaphore = shared D3D fence (current bridge)     -> cross-API context
//   4  HIP stream, D3D->HIP by WriteBufferImmediate + hipStreamWaitValue32, HIP->D3D by fence
// work time: D3D executors bracket each chunk with timestamps on their own queue; HIP with hipEvents.
// overhead = gap - sum(work chunks). Slope over K = cost per round trip.
// usage: switch_probe.exe <executor> <MiB> <K> <iterations>
#define WIN32_LEAN_AND_MEAN
#include "hip_api.h"
#include <d3d12.h>
#include <dxgi1_6.h>
#include <d3dcompiler.h>
#include <vector>
#include <algorithm>
#include <cstring>
#include <cstdio>
using namespace hip_probe;
static void ck(HRESULT h,const char*s){if(FAILED(h))throw std::runtime_error(std::string(s)+" hr="+std::to_string(unsigned(h)));}
static double pct(std::vector<double>v,double p){std::sort(v.begin(),v.end());return v[std::min(v.size()-1,size_t(p*(v.size()-1)+.5))];}
static double mean(const std::vector<double>&x){double s=0;for(double y:x)s+=y;return x.empty()?0:s/x.size();}
int main(int argc,char**argv){try{
 const int ex=argc>1?std::stoi(argv[1]):0;const size_t mib=argc>2?std::stoul(argv[2]):4096;const unsigned K=argc>3?unsigned(std::stoul(argv[3])):1;const unsigned iters=argc>4?unsigned(std::stoul(argv[4])):300;
 const bool hipEx=ex>=3;
 Api hip(7);hip.Check(hip.hipInit(0),"hipInit");int count=0;hip.Check(hip.hipGetDeviceCount(&count),"count");
 IDXGIFactory4*factory=nullptr;ck(CreateDXGIFactory1(IID_PPV_ARGS(&factory)),"factory");IDXGIAdapter1*adapter=nullptr;int ordinal=-1;
 for(unsigned i=0;!adapter;i++){IDXGIAdapter1*a=nullptr;if(factory->EnumAdapters1(i,&a)==DXGI_ERROR_NOT_FOUND)break;DXGI_ADAPTER_DESC1 desc{};a->GetDesc1(&desc);if(desc.VendorId==0x1002){char dn[256]{};WideCharToMultiByte(CP_UTF8,0,desc.Description,-1,dn,256,nullptr,nullptr);for(int n=0;n<count;n++){char hn[256]{};hip.Check(hip.hipDeviceGetName(hn,256,n),"name");if(!strcmp(dn,hn)){adapter=a;ordinal=n;break;}}}if(!adapter)a->Release();}
 if(!adapter)throw std::runtime_error("no AMD adapter");hip.Check(hip.hipSetDevice(ordinal),"set device");
 ID3D12Device*d=nullptr;ck(D3D12CreateDevice(adapter,D3D_FEATURE_LEVEL_12_0,IID_PPV_ARGS(&d)),"device");
 D3D12_COMMAND_QUEUE_DESC qd{};ID3D12CommandQueue*q=nullptr;ck(d->CreateCommandQueue(&qd,IID_PPV_ARGS(&q)),"queue");UINT64 freq=0;ck(q->GetTimestampFrequency(&freq),"freq");
 const D3D12_COMMAND_LIST_TYPE xt=ex==1?D3D12_COMMAND_LIST_TYPE_COMPUTE:D3D12_COMMAND_LIST_TYPE_DIRECT;
 ID3D12CommandQueue*xq=nullptr;if(ex==1||ex==2){D3D12_COMMAND_QUEUE_DESC x{};x.Type=xt;ck(d->CreateCommandQueue(&x,IID_PPV_ARGS(&xq)),"exec queue");UINT64 f2=0;ck(xq->GetTimestampFrequency(&f2),"freq2");if(f2!=freq)printf("warn: freq %llu vs %llu\n",f2,freq);}
 ID3D12Fence*fence=nullptr;ck(d->CreateFence(0,D3D12_FENCE_FLAG_SHARED,IID_PPV_ARGS(&fence)),"fence");ID3D12Fence*pace=nullptr;ck(d->CreateFence(0,D3D12_FENCE_FLAG_NONE,IID_PPV_ARGS(&pace)),"pace");
 Handle sem=nullptr,stream=nullptr;void*hbuf=nullptr;void*flag=nullptr;ID3D12Resource*flagbuf=nullptr;
 auto waitValue=(int(*)(Handle,void*,unsigned,unsigned,unsigned))nullptr;
 if(hipEx){HANDLE fh=nullptr;ck(d->CreateSharedHandle(fence,nullptr,GENERIC_ALL,nullptr,&fh),"fence handle");SemaphoreDesc sd{};sd.type=4;sd.handle.win32.handle=fh;hip.Check(hip.hipImportExternalSemaphore(&sem,&sd),"import fence");
  hip.Check(hip.hipStreamCreate(&stream),"stream");hip.Check(hip.hipMalloc(&hbuf,mib<<20),"hip buffer");
  D3D12_RESOURCE_DESC fd{};fd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;fd.Width=65536;fd.Height=1;fd.DepthOrArraySize=fd.MipLevels=1;fd.SampleDesc.Count=1;fd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;fd.Flags=D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
  D3D12_HEAP_PROPERTIES dp{};dp.Type=D3D12_HEAP_TYPE_DEFAULT;ck(d->CreateCommittedResource(&dp,D3D12_HEAP_FLAG_SHARED,&fd,D3D12_RESOURCE_STATE_COMMON,nullptr,IID_PPV_ARGS(&flagbuf)),"flag buffer");HANDLE flh=nullptr;ck(d->CreateSharedHandle(flagbuf,nullptr,GENERIC_ALL,nullptr,&flh),"flag handle");
  auto finfo=d->GetResourceAllocationInfo(0,1,&fd);MemoryDesc md{};md.type=5;md.handle.win32.handle=flh;md.size=finfo.SizeInBytes;md.flags=1;Handle fext=nullptr;hip.Check(hip.hipImportExternalMemory(&fext,&md),"import flag");BufferDesc bd{};bd.size=65536;hip.Check(hip.hipExternalMemoryGetMappedBuffer(&flag,fext,&bd),"map flag");hip.Check(hip.hipMemsetAsync(flag,0,65536,stream),"zero");hip.Check(hip.hipStreamSynchronize(stream),"zs");
  HMODULE hm=GetModuleHandleA("amdhip64_7.dll");if(!hm)hm=GetModuleHandleA("amdhip64_6.dll");waitValue=reinterpret_cast<decltype(waitValue)>(GetProcAddress(hm,"hipStreamWaitValue32"));if(!waitValue)throw std::runtime_error("no waitValue");}
 // D3D fill kernel (grid-stride uint4 stores), used by executors 0-2.
 ID3D12Resource*dbuf=nullptr;ID3D12RootSignature*rs=nullptr;ID3D12PipelineState*pso=nullptr;
 if(!hipEx){D3D12_RESOURCE_DESC bd{};bd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;bd.Width=mib<<20;bd.Height=1;bd.DepthOrArraySize=bd.MipLevels=1;bd.SampleDesc.Count=1;bd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;bd.Flags=D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;D3D12_HEAP_PROPERTIES dp{};dp.Type=D3D12_HEAP_TYPE_DEFAULT;ck(d->CreateCommittedResource(&dp,D3D12_HEAP_FLAG_NONE,&bd,D3D12_RESOURCE_STATE_COMMON,nullptr,IID_PPV_ARGS(&dbuf)),"d3d buffer");
  const char*hlsl="RWByteAddressBuffer B:register(u0);cbuffer C:register(b0){uint base;uint n;uint v;};[numthreads(256,1,1)]void main(uint3 id:SV_DispatchThreadID){for(uint i=id.x;i<n;i+=65535u*256u)B.Store4((base+i)*16u,uint4(v,v,v,v));}";
  ID3DBlob*cs=nullptr,*er=nullptr;ck(D3DCompile(hlsl,strlen(hlsl),"fill",nullptr,nullptr,"main","cs_5_0",D3DCOMPILE_OPTIMIZATION_LEVEL3,0,&cs,&er),"compile fill");
  D3D12_ROOT_PARAMETER rp[2]{};rp[0].ParameterType=D3D12_ROOT_PARAMETER_TYPE_UAV;rp[1].ParameterType=D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;rp[1].Constants.Num32BitValues=3;D3D12_ROOT_SIGNATURE_DESC rsd{};rsd.NumParameters=2;rsd.pParameters=rp;ID3DBlob*rsb=nullptr;ck(D3D12SerializeRootSignature(&rsd,D3D_ROOT_SIGNATURE_VERSION_1,&rsb,&er),"rs ser");ck(d->CreateRootSignature(0,rsb->GetBufferPointer(),rsb->GetBufferSize(),IID_PPV_ARGS(&rs)),"rs");
  D3D12_COMPUTE_PIPELINE_STATE_DESC pd{};pd.pRootSignature=rs;pd.CS={cs->GetBufferPointer(),cs->GetBufferSize()};ck(d->CreateComputePipelineState(&pd,IID_PPV_ARGS(&pso)),"pso");}
 const unsigned perF=2+2*K;D3D12_QUERY_HEAP_DESC hd{};hd.Type=D3D12_QUERY_HEAP_TYPE_TIMESTAMP;hd.Count=perF*iters;ID3D12QueryHeap*heap=nullptr;ck(d->CreateQueryHeap(&hd,IID_PPV_ARGS(&heap)),"qheap");
 D3D12_RESOURCE_DESC rd{};rd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;rd.Width=8ull*perF*iters;rd.Height=1;rd.DepthOrArraySize=rd.MipLevels=1;rd.SampleDesc.Count=1;rd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;D3D12_HEAP_PROPERTIES hp{};hp.Type=D3D12_HEAP_TYPE_READBACK;ID3D12Resource*rb=nullptr;ck(d->CreateCommittedResource(&hp,D3D12_HEAP_FLAG_NONE,&rd,D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&rb)),"readback");
 const unsigned total=unsigned((mib<<20)/16),chunk=total/K;
 auto mk=[&](D3D12_COMMAND_LIST_TYPE t){ID3D12CommandAllocator*a=nullptr;ID3D12GraphicsCommandList*l=nullptr;ck(d->CreateCommandAllocator(t,IID_PPV_ARGS(&a)),"alloc");ck(d->CreateCommandList(0,t,a,nullptr,IID_PPV_ARGS(&l)),"list");return l;};
 auto fill=[&](ID3D12GraphicsCommandList*l,unsigned k,unsigned it){l->SetComputeRootSignature(rs);l->SetPipelineState(pso);l->SetComputeRootUnorderedAccessView(0,dbuf->GetGPUVirtualAddress());l->SetComputeRoot32BitConstant(1,k*chunk,0);l->SetComputeRoot32BitConstant(1,chunk,1);l->SetComputeRoot32BitConstant(1,it,2);unsigned g=std::min(65535u,(chunk+255)/256);l->Dispatch(g,1,1);D3D12_RESOURCE_BARRIER ub{};ub.Type=D3D12_RESOURCE_BARRIER_TYPE_UAV;ub.UAV.pResource=dbuf;l->ResourceBarrier(1,&ub);};
 // per frame lists: begin (DIRECT), K executor lists, end (DIRECT). Executor 0: everything in begin list.
 std::vector<ID3D12GraphicsCommandList*>lb(iters),le(iters),lx(size_t(iters)*K,nullptr);
 for(unsigned i=0;i<iters;i++){unsigned qb=perF*i;lb[i]=mk(D3D12_COMMAND_LIST_TYPE_DIRECT);lb[i]->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,qb);
  if(ex==0)for(unsigned k=0;k<K;k++){lb[i]->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,qb+2+2*k);fill(lb[i],k,i);lb[i]->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,qb+3+2*k);}
  if(ex==4){ID3D12GraphicsCommandList2*c2=nullptr;ck(lb[i]->QueryInterface(IID_PPV_ARGS(&c2)),"l2");D3D12_WRITEBUFFERIMMEDIATE_PARAMETER wp{flagbuf->GetGPUVirtualAddress(),i+1};D3D12_WRITEBUFFERIMMEDIATE_MODE wm=D3D12_WRITEBUFFERIMMEDIATE_MODE_MARKER_OUT;c2->WriteBufferImmediate(1,&wp,&wm);c2->Release();}
  ck(lb[i]->Close(),"close b");
  if(ex==1||ex==2)for(unsigned k=0;k<K;k++){auto l=mk(xt);l->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,qb+2+2*k);fill(l,k,i);l->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,qb+3+2*k);ck(l->Close(),"close x");lx[size_t(i)*K+k]=l;}
  le[i]=mk(D3D12_COMMAND_LIST_TYPE_DIRECT);le[i]->EndQuery(heap,D3D12_QUERY_TYPE_TIMESTAMP,qb+1);if(i+1==iters)le[i]->ResolveQueryData(heap,D3D12_QUERY_TYPE_TIMESTAMP,0,perF*iters,rb,0);ck(le[i]->Close(),"close e");}
 std::vector<Handle>eb(size_t(iters)*K),ee(size_t(iters)*K);if(hipEx)for(size_t i=0;i<eb.size();i++){hip.Check(hip.hipEventCreate(&eb[i]),"ev");hip.Check(hip.hipEventCreate(&ee[i]),"ev");}
 UINT64 v=0,pv=0;HANDLE done=CreateEventW(nullptr,FALSE,FALSE,nullptr);std::vector<UINT64>endv(iters);
 for(unsigned i=0;i<iters;i++){
  if(i>=2&&pace->GetCompletedValue()<endv[i-2]){ck(pace->SetEventOnCompletion(endv[i-2],done),"ev");if(WaitForSingleObject(done,10000)!=WAIT_OBJECT_0)throw std::runtime_error("timeout");}
  ID3D12CommandList*a[]={lb[i]};q->ExecuteCommandLists(1,a);
  for(unsigned k=0;k<K&&ex!=0;k++){size_t j=size_t(i)*K+k;
   if(ex==4&&k==0)hip.Check(waitValue(stream,flag,i+1,0,0xffffffffu),"wait value");
   else{ck(q->Signal(fence,++v),"sig in");if(hipEx){WaitParams w{};w.params.fence.value=v;hip.Check(hip.hipWaitExternalSemaphoresAsync(&sem,&w,1,stream),"hwait");}else ck(xq->Wait(fence,v),"xwait");}
   if(hipEx){hip.Check(hip.hipEventRecord(eb[j],stream),"eb");hip.Check(hip.hipMemsetAsync(static_cast<char*>(hbuf)+size_t(k)*chunk*16,int(i&255),size_t(chunk)*16,stream),"memset");hip.Check(hip.hipEventRecord(ee[j],stream),"ee");SignalParams s{};s.params.fence.value=++v;hip.Check(hip.hipSignalExternalSemaphoresAsync(&sem,&s,1,stream),"hsig");}
   else{ID3D12CommandList*x[]={lx[j]};xq->ExecuteCommandLists(1,x);ck(xq->Signal(fence,++v),"xsig");}
   ck(q->Wait(fence,v),"qwait");}
  ID3D12CommandList*b[]={le[i]};q->ExecuteCommandLists(1,b);ck(q->Signal(pace,++pv),"pace");endv[i]=pv;}
 ck(pace->SetEventOnCompletion(pv,done),"fin");if(WaitForSingleObject(done,60000)!=WAIT_OBJECT_0)throw std::runtime_error("final timeout");if(hipEx)hip.Check(hip.hipStreamSynchronize(stream),"hs");
 UINT64*t=nullptr;D3D12_RANGE range{0,size_t(8ull*perF*iters)};ck(rb->Map(0,&range,(void**)&t),"map");std::vector<double>gap,work,over;
 for(unsigned i=iters/10;i<iters;i++){size_t qb=size_t(perF)*i;double g=double(t[qb+1]-t[qb])*1e3/freq,w=0;
  for(unsigned k=0;k<K;k++){if(hipEx){float ms=0;hip.Check(hip.hipEventElapsedTime(&ms,eb[size_t(i)*K+k],ee[size_t(i)*K+k]),"el");w+=ms;}else w+=double(t[qb+3+2*k]-t[qb+2+2*k])*1e3/freq;}
  gap.push_back(g);work.push_back(w);over.push_back(g-w);}
 printf("ex=%d mib=%zu K=%u n=%zu gap_mean=%.4f gap_p50=%.4f gap_p99=%.4f work_mean=%.4f over_mean=%.4f over_p50=%.4f over_p99=%.4f per_roundtrip=%.4f ms\n",ex,mib,K,gap.size(),mean(gap),pct(gap,.5),pct(gap,.99),mean(work),mean(over),pct(over,.5),pct(over,.99),ex?mean(over)/K:0.0);
 return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 1;}}
