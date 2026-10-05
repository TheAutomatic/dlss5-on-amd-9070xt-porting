// Minimal native NVIDIA primitive readback. No game, NGX, model, or substitute network.
#include <windows.h>
#include <cuda.h>
#include <cstdio>
#include <fstream>
#include <vector>
#include <stdexcept>
template<class T>T load(HMODULE d,const char*n){auto p=GetProcAddress(d,n);if(!p)throw std::runtime_error(n);return reinterpret_cast<T>(p);}
static void ck(CUresult r,const char*n){if(r!=CUDA_SUCCESS){fprintf(stderr,"%s result=%d\n",n,int(r));throw std::runtime_error(n);}}
int main(int argc,char**argv){try{if(argc!=3)throw std::runtime_error("nv_primitive_probe CUBIN OUTPUT_F32");auto dll=LoadLibraryA("nvcuda.dll");if(!dll)throw std::runtime_error("nvcuda.dll");
#define FN(f,name) auto f=load<decltype(&::f)>(dll,name)
 FN(cuInit,"cuInit");FN(cuDeviceGet,"cuDeviceGet");using CreateV2=CUresult(CUDAAPI*)(CUcontext*,unsigned,CUdevice);auto create_context=load<CreateV2>(dll,"cuCtxCreate_v2");FN(cuModuleLoad,"cuModuleLoad");FN(cuModuleGetFunction,"cuModuleGetFunction");FN(cuMemAlloc,"cuMemAlloc_v2");FN(cuLaunchKernel,"cuLaunchKernel");FN(cuCtxSynchronize,"cuCtxSynchronize");FN(cuMemcpyDtoH,"cuMemcpyDtoH_v2");FN(cuMemFree,"cuMemFree_v2");FN(cuCtxDestroy,"cuCtxDestroy_v2");
 ck(cuInit(0),"init");CUdevice dev;ck(cuDeviceGet(&dev,0),"device");CUcontext ctx;ck(create_context(&ctx,0,dev),"context");CUmodule m;ck(cuModuleLoad(&m,argv[1]),"module");CUfunction f;ck(cuModuleGetFunction(&f,m,"original_gate_sigmoid"),"function");CUdeviceptr out;ck(cuMemAlloc(&out,65536*4),"alloc");void*args[]={&out};ck(cuLaunchKernel(f,256,1,1,256,1,1,0,nullptr,args,nullptr),"launch");ck(cuCtxSynchronize(),"ready");std::vector<float>v(65536);ck(cuMemcpyDtoH(v.data(),out,v.size()*4),"read");std::ofstream s(argv[2],std::ios::binary);s.write(reinterpret_cast<const char*>(v.data()),v.size()*4);if(!s)throw std::runtime_error("output");ck(cuMemFree(out),"free");ck(cuCtxDestroy(ctx),"destroy");printf("NV_NATIVE_SIGMOID_HALF_DOMAIN 65536 codes, bytes262144; scalar primitive only\n");return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 2;}}
