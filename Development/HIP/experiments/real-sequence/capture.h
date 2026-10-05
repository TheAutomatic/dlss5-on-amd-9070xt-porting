#pragma once
#include <vector>
#include <cstdio>
#include <stdexcept>
namespace NativeSequenceCapture {
struct Item {ID3D12Resource*source{},*readback{};D3D12_PLACED_SUBRESOURCE_FOOTPRINT fp{};UINT rows{};UINT64 row_bytes{},bytes{};D3D12_RESOURCE_STATES state{};unsigned role{};};
struct Frame {unsigned id{};ULONGLONG tick{};float jitter[2],scale[2],exposure;unsigned render[2],upscale[2],flags;bool reset;std::vector<Item>items;};
inline void Check(HRESULT h){if(FAILED(h))throw std::runtime_error("sequence capture HRESULT="+std::to_string(unsigned(h)));}
inline const wchar_t*Directory(){return _wgetenv(L"DLSS5_REAL_SEQUENCE_DIR");}
inline unsigned Limit(){const wchar_t*v=_wgetenv(L"DLSS5_REAL_SEQUENCE_FRAMES");unsigned n=v?wcstoul(v,nullptr,10):16;if(!n||n>48)throw std::runtime_error("real sequence burst must be 1..48 frames");return n;}
inline const char*Role(unsigned n){return n==0?"color":n==1?"depth":n==2?"motion":n==3?"exposure":n==4?"reactive":"transparency";}
// Called after the game's producer submission, before any neural/color mutation.
// A bounded burst uses one deferred copy list/frame; no per-frame Flush/readback.
// All borrowed source states are restored in the same list. Disk drain is once at burst end.
template<class Description>inline void Record(ID3D12CommandQueue*q,const Description&d,const D3D12_RESOURCE_STATES*states,unsigned frame,ID3D12Device*record_device){
 const wchar_t*dir=Directory();if(!dir||!*dir)return;
 static NativeGameSubmission*submit=nullptr;static std::vector<Frame>frames;static bool done=false,failed=false;
 if(done||failed)return;
 if(!submit&&GetFileAttributesW((std::wstring(dir)+L"\\ARM").c_str())==INVALID_FILE_ATTRIBUTES)return;
 try{
 if(!submit){if(GetFileAttributesW((std::wstring(dir)+L"\\manifest.jsonl").c_str())!=INVALID_FILE_ATTRIBUTES)throw std::runtime_error("capture destination already contains manifest");ULARGE_INTEGER free{};if(!GetDiskFreeSpaceExW(dir,&free,nullptr,nullptr)||free.QuadPart<100ull*1024*1024*1024)throw std::runtime_error("capture directory absent or free space below100GiB");submit=new NativeGameSubmission;submit->Create(q,true,record_device,true);}
 if(submit->Queue()!=q)throw std::runtime_error("capture queue changed");
 if(!frames.empty()&&frame!=frames.back().id+1)throw std::runtime_error("capture frame gap; discard partial burst");
 if(!std::isfinite(d.pre_exposure))throw std::runtime_error("nonfinite pre_exposure metadata");
 Frame f{};f.id=frame;f.tick=GetTickCount64();f.exposure=d.pre_exposure;f.reset=d.reset;f.flags=d.flags;
 for(unsigned i=0;i<2;i++){f.jitter[i]=d.jitter[i];f.scale[i]=d.motion_scale[i];f.render[i]=d.render[i];f.upscale[i]=d.upscale[i];}
 for(unsigned i=0;i<6;i++)if(d.resources[i].resource){Item a{};a.source=static_cast<ID3D12Resource*>(d.resources[i].resource);a.role=i;a.state=states[i];auto desc=a.source->GetDesc();
 if(desc.Dimension!=D3D12_RESOURCE_DIMENSION_TEXTURE2D||desc.SampleDesc.Count!=1||desc.MipLevels!=1||desc.DepthOrArraySize!=1)throw std::runtime_error("capture texture contract");
 submit->Device()->GetCopyableFootprints(&desc,0,1,0,&a.fp,&a.rows,&a.row_bytes,&a.bytes);
 if(!a.bytes||a.bytes>256ull*1024*1024)throw std::runtime_error("capture resource size");
 D3D12_HEAP_PROPERTIES hp{};hp.Type=D3D12_HEAP_TYPE_READBACK;D3D12_RESOURCE_DESC bd{};bd.Dimension=D3D12_RESOURCE_DIMENSION_BUFFER;bd.Width=a.bytes;bd.Height=1;bd.DepthOrArraySize=bd.MipLevels=1;bd.SampleDesc.Count=1;bd.Layout=D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
 Check(NativeCreateCommittedResource(submit->Device(),&hp,D3D12_HEAP_FLAG_NONE,&bd,D3D12_RESOURCE_STATE_COPY_DEST,nullptr,IID_PPV_ARGS(&a.readback)));a.source->AddRef();f.items.push_back(a);}
 frames.push_back(std::move(f));auto&pending=frames.back();
 submit->Submit([&](ID3D12GraphicsCommandList*c){for(auto&a:pending.items){D3D12_RESOURCE_BARRIER b{};b.Type=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;b.Transition={a.source,D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,a.state,D3D12_RESOURCE_STATE_COPY_SOURCE};if(a.state!=D3D12_RESOURCE_STATE_COPY_SOURCE)c->ResourceBarrier(1,&b);
 D3D12_TEXTURE_COPY_LOCATION src{},dst{};src.pResource=a.source;src.Type=D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;dst.pResource=a.readback;dst.Type=D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;dst.PlacedFootprint=a.fp;c->CopyTextureRegion(&dst,0,0,0,&src,nullptr);std::swap(b.Transition.StateBefore,b.Transition.StateAfter);if(a.state!=D3D12_RESOURCE_STATE_COPY_SOURCE)c->ResourceBarrier(1,&b);}});
 if(frames.size()!=Limit())return;
 submit->Flush();std::wstring base(dir);FILE*flags=_wfopen((base+L"\\config-lines.txt").c_str(),L"wb");if(!flags)throw std::runtime_error("capture config snapshot open");for(const auto&line:NativeConfigFileLines())fprintf(flags,"%s\n",line.c_str());fclose(flags);FILE*manifest=_wfopen((base+L"\\manifest.jsonl").c_str(),L"wb");if(!manifest)throw std::runtime_error("capture manifest open");
 for(auto&f:frames){fprintf(manifest,"{\"schema\":\"dlss5.real-sequence.v1\",\"frame_id\":%u,\"timestamp_ms\":%llu,\"seed\":null,\"reset\":%s,\"jitter\":[%.9g,%.9g],\"motion_scale\":[%.9g,%.9g],\"pre_exposure\":%.9g,\"render\":[%u,%u],\"upscale\":[%u,%u],\"ffx_flags\":%u,\"source_kind\":\"game_capture\",\"contract_verified\":false,\"motion_contract_verified\":false,\"timing_valid\":false,\"origin\":\"same-frame-ffx-pre-neural\",\"resources\":[",f.id,f.tick,f.reset?"true":"false",f.jitter[0],f.jitter[1],f.scale[0],f.scale[1],f.exposure,f.render[0],f.render[1],f.upscale[0],f.upscale[1],f.flags);
 bool comma=false;for(auto&a:f.items){std::string name=std::to_string(f.id)+"-"+Role(a.role)+".raw";std::wstring wn(name.begin(),name.end());FILE*out=_wfopen((base+L"\\"+wn).c_str(),L"wb");if(!out)throw std::runtime_error("capture raw open");void*p=nullptr;D3D12_RANGE r{0,SIZE_T(a.bytes)};Check(a.readback->Map(0,&r,&p));for(UINT y=0;y<a.rows;y++)if(fwrite(static_cast<char*>(p)+a.fp.Offset+size_t(y)*a.fp.Footprint.RowPitch,1,size_t(a.row_bytes),out)!=a.row_bytes)throw std::runtime_error("capture raw write");D3D12_RANGE no{};a.readback->Unmap(0,&no);fclose(out);
 fprintf(manifest,"%s{\"role\":\"%s\",\"path\":\"%s\",\"dxgi_format\":%u,\"width\":%u,\"height\":%u,\"rows\":%u,\"row_bytes\":%llu,\"bytes\":%llu,\"source_state\":%u}",comma?",":"",Role(a.role),name.c_str(),unsigned(a.fp.Footprint.Format),a.fp.Footprint.Width,a.fp.Footprint.Height,a.rows,a.row_bytes,a.row_bytes*a.rows,unsigned(a.state));comma=true;a.readback->Release();a.source->Release();}for(unsigned role=0;role<6;role++){bool found=false;for(auto&a:f.items)found|=a.role==role;if(!found){fprintf(manifest,"%s{\"role\":\"%s\",\"missing\":true}",comma?",":"",Role(role));comma=true;}}fprintf(manifest,"]}\n");}
 fclose(manifest);FILE*complete=_wfopen((base+L"\\COMPLETE").c_str(),L"wb");if(!complete)throw std::runtime_error("capture completion marker");fprintf(complete,"frames=%zu\n",frames.size());fclose(complete);done=true;frames.clear();delete submit;submit=nullptr;
 }catch(const std::exception&e){failed=true;fprintf(stderr,"REAL_SEQUENCE_CAPTURE stopped: %s\n",e.what()); /* retain pending GPU resources: timeout is not cancellation */}
}
}
