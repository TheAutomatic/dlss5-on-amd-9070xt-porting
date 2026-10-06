// Minimal native NVIDIA primitive readback. No game, NGX, model, or substitute network.
#include <windows.h>
#include <cuda.h>
#include <cstdio>
#include <fstream>
#include <vector>
#include <stdexcept>
template<class T>T load(HMODULE d,const char*n){auto p=GetProcAddress(d,n);if(!p)throw std::runtime_error(n);return reinterpret_cast<T>(p);}
static void ck(CUresult r,const char*n){if(r!=CUDA_SUCCESS){fprintf(stderr,"%s result=%d\n",n,int(r));throw std::runtime_error(n);}}
int main(int argc,char**argv){try{if(argc!=3&&argc!=5)throw std::runtime_error("nv_primitive_probe CUBIN OUTPUT [FEATURES_F16 WEIGHT32_F16]");auto dll=LoadLibraryA("nvcuda.dll");if(!dll)throw std::runtime_error("nvcuda.dll");
#define FN(f,name) auto f=load<decltype(&::f)>(dll,name)
 FN(cuInit,"cuInit");FN(cuDeviceGet,"cuDeviceGet");using CreateV2=CUresult(CUDAAPI*)(CUcontext*,unsigned,CUdevice);auto create_context=load<CreateV2>(dll,"cuCtxCreate_v2");FN(cuModuleLoad,"cuModuleLoad");FN(cuModuleGetFunction,"cuModuleGetFunction");FN(cuMemAlloc,"cuMemAlloc_v2");FN(cuLaunchKernel,"cuLaunchKernel");FN(cuCtxSynchronize,"cuCtxSynchronize");FN(cuMemcpyDtoH,"cuMemcpyDtoH_v2");FN(cuMemcpyHtoD,"cuMemcpyHtoD_v2");FN(cuMemFree,"cuMemFree_v2");FN(cuCtxDestroy,"cuCtxDestroy_v2");
 ck(cuInit(0),"init");CUdevice dev;ck(cuDeviceGet(&dev,0),"device");CUcontext ctx;ck(create_context(&ctx,0,dev),"context");CUmodule m;ck(cuModuleLoad(&m,argv[1]),"module");CUfunction f;const bool head=argc==5;ck(cuModuleGetFunction(&f,m,head?"original_gate_head_hw":"original_gate_sigmoid"),"function");CUdeviceptr out,features=0,weights=0;unsigned n=65536;size_t bytes=65536*4;
 if(head){auto read=[](const char*path){std::ifstream f(path,std::ios::binary|std::ios::ate);if(!f)throw std::runtime_error(path);auto sz=f.tellg();std::vector<unsigned char>v(size_t(sz),0);f.seekg(0);f.read((char*)v.data(),sz);if(!f)throw std::runtime_error(path);return v;};auto fv=read(argv[3]),wv=read(argv[4]);if(wv.size()!=64||fv.empty()||fv.size()%1024)throw std::runtime_error("head input shape");n=unsigned(fv.size()/64);bytes=size_t(n)*2;ck(cuMemAlloc(&features,fv.size()),"features alloc");ck(cuMemAlloc(&weights,wv.size()),"weights alloc");ck(cuMemcpyHtoD(features,fv.data(),fv.size()),"features copy");ck(cuMemcpyHtoD(weights,wv.data(),wv.size()),"weights copy");}
 ck(cuMemAlloc(&out,bytes),"alloc");void*sigargs[]={&out};void*headargs[]={&features,&weights,&out,&n};ck(cuLaunchKernel(f,head?n/16:256,1,1,head?32:256,1,1,0,nullptr,head?headargs:sigargs,nullptr),"launch");ck(cuCtxSynchronize(),"ready");std::vector<unsigned char>v(bytes);ck(cuMemcpyDtoH(v.data(),out,bytes),"read");std::ofstream s(argv[2],std::ios::binary);s.write((const char*)v.data(),bytes);if(!s)throw std::runtime_error("output");ck(cuMemFree(out),"free");if(head){ck(cuMemFree(features),"features free");ck(cuMemFree(weights),"weights free");}ck(cuCtxDestroy(ctx),"destroy");printf("NV_NATIVE_PRIMITIVE head=%d n=%u bytes=%zu; not whole-post oracle\n",int(head),n,bytes);return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 2;}}
