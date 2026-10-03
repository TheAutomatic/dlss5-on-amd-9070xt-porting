#pragma once
#include <windows.h>
#include <d3d12.h>
#include <cstdint>
#include <initializer_list>
// Microsoft-x64 ABI of driver NGX parameters, independently of MinGW C++ vtables.
namespace ngx_direct {
using Result=std::uint32_t;
struct Handle { unsigned Id; };
using InitExt=Result(__cdecl*)(unsigned long long,const wchar_t*,ID3D12Device*,unsigned int,void*);
using GetCaps=Result(__cdecl*)(void**);
using Create=Result(__cdecl*)(ID3D12GraphicsCommandList*,unsigned int,void*,Handle**);
using Eval=Result(__cdecl*)(ID3D12GraphicsCommandList*,const Handle*,const void*,void*);
using Release=Result(__cdecl*)(Handle*);
inline void** table(void* p){return *reinterpret_cast<void***>(p);}
inline void SetULL(void* p,const char* k,unsigned long long v){using F=void(__cdecl*)(void*,const char*,unsigned long long);reinterpret_cast<F>(table(p)[7])(p,k,v);}
inline void SetUInt(void* p,const char* k,unsigned v){using F=void(__cdecl*)(void*,const char*,unsigned);reinterpret_cast<F>(table(p)[4])(p,k,v);}
inline void SetFloat(void* p,const char* k,float v){using F=void(__cdecl*)(void*,const char*,float);reinterpret_cast<F>(table(p)[6])(p,k,v);}
inline void SetResource(void* p,const char* k,ID3D12Resource* v){using F=void(__cdecl*)(void*,const char*,ID3D12Resource*);reinterpret_cast<F>(table(p)[1])(p,k,v);}
inline Result GetUInt(void* p,const char* k,unsigned* v){using F=Result(__cdecl*)(void*,const char*,unsigned*);return reinterpret_cast<F>(table(p)[12])(p,k,v);}
inline Result GetFloat(void* p,const char* k,float* v){using F=Result(__cdecl*)(void*,const char*,float*);return reinterpret_cast<F>(table(p)[14])(p,k,v);}
inline Result GetULL(void* p,const char* k,unsigned long long* v){using F=Result(__cdecl*)(void*,const char*,unsigned long long*);return reinterpret_cast<F>(table(p)[15])(p,k,v);}
inline void Creation(void*p,unsigned w,unsigned h){
 SetUInt(p,"DLSSNR.Enabled",1);SetUInt(p,"DLSSNR.Width",w);SetUInt(p,"DLSSNR.Height",h);
 SetUInt(p,"CreationNodeMask",1);SetUInt(p,"VisibilityNodeMask",1);
 SetUInt(p,"DLSSNR.Hint.Render.Preset",0);SetUInt(p,"DLSSNR.Style",1);
 SetFloat(p,"DLSSNR.Intensity",1);SetFloat(p,"DLSSNR.LocalStructureStrength",1);
 SetFloat(p,"DLSSNR.LocalToneStrength",1);SetFloat(p,"DLSSNR.SkinStructureStrength",-1);
 SetUInt(p,"DLSSNR.UseAutoMask",1);SetUInt(p,"DLSSNR.UICorrection",1);
}
inline void Evaluation(void*p,ID3D12Resource*color,ID3D12Resource*output,ID3D12Resource*depth,ID3D12Resource*motion,unsigned w,unsigned h){
 Creation(p,w,h);SetResource(p,"DLSSNR.Color",color);SetResource(p,"DLSSNR.Output",output);
 SetResource(p,"DLSSNR.Depth",depth);SetResource(p,"DLSSNR.MVec",motion);
 SetUInt(p,"DLSSNR.Reset",1);SetUInt(p,"DLSSNR.DepthInverted",0);
 for(const char* k:{"DLSSNR.ColorSubrectBaseX","DLSSNR.ColorSubrectBaseY","DLSSNR.OutputSubrectBaseX","DLSSNR.OutputSubrectBaseY","DLSSNR.DepthSubrectBaseX","DLSSNR.DepthSubrectBaseY","DLSSNR.MVecSubrectBaseX","DLSSNR.MVecSubrectBaseY"})SetUInt(p,k,0);
 for(const char* k:{"DLSSNR.ColorSubrectWidth","DLSSNR.OutputSubrectWidth","DLSSNR.DepthSubrectWidth","DLSSNR.MVecSubrectWidth"})SetUInt(p,k,w);
 for(const char* k:{"DLSSNR.ColorSubrectHeight","DLSSNR.OutputSubrectHeight","DLSSNR.DepthSubrectHeight","DLSSNR.MVecSubrectHeight"})SetUInt(p,k,h);
 SetFloat(p,"DLSSNR.MVecScaleX",1);SetFloat(p,"DLSSNR.MVecScaleY",1);
}
}
