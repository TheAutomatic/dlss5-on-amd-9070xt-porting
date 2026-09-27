#include "hip_api.h"
#include <vector>
int main(int argc,char**argv){try{if(argc!=2)return 2;hip_probe::Api a;a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"dev");hip_probe::Handle m{},f{};a.Check(a.LoadModule(&m,argv[1]),"load");a.Check(a.hipModuleGetFunction(&f,m,"mode_probe"),"fn");
 void*d{};a.Check(a.hipMalloc(&d,8192*6*4),"malloc");void*args[]={&d};a.Check(a.hipModuleLaunchKernel(f,256,1,1,32,1,1,0,nullptr,args,nullptr),"launch");a.Check(a.hipDeviceSynchronize(),"sync");std::vector<unsigned> v(8192*6);a.Check(a.hipMemcpy(v.data(),d,v.size()*4,2),"copy");unsigned bad=0,nfdiff=0,modebad=0,guardbad=0;
 for(unsigned i=0;i<8192;i++){modebad+=v[i*6+4]!=0;guardbad+=v[i*6+5]!=0x7c00;for(unsigned e=0;e<8;e++){unsigned old=(v[i*6+e/4]>>(8*(e%4)))&255,now=(v[i*6+2+e/4]>>(8*(e%4)))&255;if(old!=now){if(((i*8+e)&0x7c00)==0x7c00)nfdiff++;else{if(bad<8)printf("FINITE_DIFF %04x %02x %02x\n",i*8+e,old,now);bad++;}}}}
 printf("HALF_CODES=65536 finite_bad=%u nonfinite_differences=%u mode_restore_bad=%u RNE_overflow_bad=%u\n",bad,nfdiff,modebad,guardbad);a.hipFree(d);a.hipModuleUnload(m);return bad||modebad||guardbad?1:0;
}catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 2;}}
