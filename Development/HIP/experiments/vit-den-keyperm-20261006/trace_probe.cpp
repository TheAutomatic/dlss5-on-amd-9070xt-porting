#include "hip_api.h"
#include <fstream>
#include <cstdio>
#include <vector>
#include <cstring>
using namespace hip_probe;
int main(int argc,char**argv){try{
 if(argc!=4)throw std::runtime_error("trace_probe C_MODULE C2_MODULE OUT_DIR");Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle stream;a.Check(a.hipStreamCreate(&stream),"stream");
 for(int fixture=0;fixture<4;fixture++){
 std::vector<unsigned char>in(3*640*1024,0);for(size_t i=0;i<in.size();i++)if(fixture==1)in[i]=(i%7==0)?0:((i*13+i/1024)%2?32:160);else if(fixture==2&&i%37==0)in[i]=(i/37)%2?56:184;else if(fixture==3)in[i]=i%2?0x80:0x00;
 void*di,*out,*trace;a.Check(a.hipMalloc(&di,in.size()),"input");a.Check(a.hipMalloc(&out,640*1024),"output");a.Check(a.hipMalloc(&trace,(32*640+320+512)*4),"trace");a.Check(a.hipMemcpy(di,in.data(),in.size(),1),"upload");std::vector<unsigned char>refout;std::vector<unsigned>reftrace;
 for(int side=0;side<2;side++){std::vector<unsigned char>bytes(640*1024,0);std::vector<unsigned>words(32*640+320+512,0);a.Check(a.hipMemcpy(out,bytes.data(),bytes.size(),1),"clear out");a.Check(a.hipMemcpy(trace,words.data(),words.size()*4,1),"clear trace");Handle m,fn;a.Check(a.LoadModule(&m,argv[1+side]),"module");a.Check(a.hipModuleGetFunction(&fn,m,"keyperm_trace"),"fn");void*args[]={&di,&out,&trace};a.Check(a.hipModuleLaunchKernel(fn,1,1,1,32,1,1,0,stream,args,nullptr),"launch");a.Check(a.hipStreamSynchronize(stream),"sync");a.Check(a.hipMemcpy(bytes.data(),out,bytes.size(),2),"out");a.Check(a.hipMemcpy(words.data(),trace,words.size()*4,2),"trace");a.hipModuleUnload(m);
 std::string path=std::string(argv[3])+"/fixture"+std::to_string(fixture)+"-"+std::to_string(side);std::ofstream(path+".trace",std::ios::binary).write((char*)words.data(),words.size()*4);std::ofstream(path+".bytes",std::ios::binary).write((char*)bytes.data(),bytes.size());
 if(side==0){refout=bytes;reftrace=words;}else{size_t diffs[4]={};for(size_t i=0;i<words.size();i++)if(words[i]!=reftrace[i])diffs[i<16*640?0:i<32*640?1:i<32*640+320?2:3]++;size_t bd=0;for(size_t i=0;i<bytes.size();i++)bd+=bytes[i]!=refout[i];printf("KEYPERM_GOLD fixture=%d QK=%zu naturalP=%zu denprefix=%zu AV=%zu finalbyte=%zu\n",fixture,diffs[0],diffs[1],diffs[2],diffs[3],bd);if(diffs[0]||diffs[1]||diffs[2]||diffs[3]||bd)throw std::runtime_error("representation mismatch");}}
 a.hipFree(trace);a.hipFree(out);a.hipFree(di);
 }a.hipStreamDestroy(stream);return 0;
}catch(const std::exception&e){fprintf(stderr,"KEYPERM_FAIL %s\n",e.what());return 1;}}
