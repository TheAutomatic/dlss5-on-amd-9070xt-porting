#include "hip_api.h"
#include <iostream>
int main(int argc,char**argv){try{
 if(argc!=2)return 2;hip_probe::Api api;api.Check(api.hipInit(0),"init");api.Check(api.hipSetDevice(0),"device");auto prop=api.Properties(0);
 int(*occupancy)(int*,void*,int,size_t)=nullptr;api.Load(occupancy,"hipModuleOccupancyMaxActiveBlocksPerMultiprocessor");
 std::cout<<"device="<<prop.name<<" multiprocessors="<<prop.multiProcessorCount<<" max_threads_per_mp="<<prop.maxThreadsPerMultiProcessor<<"\n";
 std::cout<<"module,kernel,block_threads,active_blocks_per_mp,active_threads_per_mp,theoretical_percent\n";
 for(auto module:{"c64-wave2.hsaco","swin-persistent.hsaco"}){
  void*m=nullptr;api.Check(api.LoadModule(&m,(std::string(argv[1])+"/"+module).c_str()),"module");
  for(unsigned c:{64,128,256}){
   std::vector<std::string>names=std::string(module)=="c64-wave2.hsaco"?std::vector<std::string>{"c"+std::to_string(c)+"_wave2_bi_bo"}:std::vector<std::string>{"sp_run"+std::to_string(c),"sp_recover"+std::to_string(c)};
   for(auto&name:names){void*f=nullptr;api.Check(api.hipModuleGetFunction(&f,m,name.c_str()),"function");int blocks=0;api.Check(occupancy(&blocks,f,c,0),"occupancy");std::cout<<module<<","<<name<<","<<c<<","<<blocks<<","<<blocks*c<<","<<100.*blocks*c/prop.maxThreadsPerMultiProcessor<<"\n";}
  }
  api.Check(api.hipModuleUnload(m),"unload");
 }
}catch(const std::exception&e){std::cerr<<e.what()<<"\n";return 1;}}
