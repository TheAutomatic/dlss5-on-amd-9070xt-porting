#include "hip_api.h"
#include <iostream>
int main(int argc,char**argv){try{
 if(argc!=2)return 2;hip_probe::Api api;api.Check(api.hipInit(0),"init");api.Check(api.hipSetDevice(0),"device");auto p=api.Properties(0);
 int(*occ)(int*,void*,int,size_t)=nullptr;api.Load(occ,"hipModuleOccupancyMaxActiveBlocksPerMultiprocessor");
 std::cout<<"device="<<p.name<<" mp="<<p.multiProcessorCount<<" max_threads="<<p.maxThreadsPerMultiProcessor<<"\nmodule,kernel,threads,blocks_per_mp,theoretical_percent\n";
 struct Job{const char*module;const char*name;unsigned threads;};
 Job jobs[]={{"flat-A/deep_fast-packed.hsaco","vit_attention_fused_640_bytein_bout",32},{"flat-P/deep_fast-packed.hsaco","vit_attention_fused_640_bytein_bout",32},{"probe/gfx1201/probe.hsaco","vit_probe_g4_u4_h1",128},{"probe/gfx1201/probe.hsaco","vit_probe_native_g4_u4_h1",128},{"probe/gfx1201/probe.hsaco","vit_probe_native_constv",32},{"daniel-050.hsaco","_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams",128},{"daniel-051.hsaco","_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams",128}};
 for(auto j:jobs){void*m=nullptr,*f=nullptr;api.Check(api.LoadModule(&m,(std::string(argv[1])+"/"+j.module).c_str()),"module");api.Check(api.hipModuleGetFunction(&f,m,j.name),"function");int n=0;api.Check(occ(&n,f,j.threads,0),"occupancy");std::cout<<j.module<<","<<j.name<<","<<j.threads<<","<<n<<","<<100.*n*j.threads/p.maxThreadsPerMultiProcessor<<"\n";api.Check(api.hipModuleUnload(m),"unload");}
}catch(const std::exception&e){std::cerr<<e.what()<<"\n";return 1;}}
