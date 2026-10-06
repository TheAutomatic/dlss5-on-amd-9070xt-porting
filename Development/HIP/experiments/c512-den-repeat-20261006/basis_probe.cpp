#include "hip_api.h"
#include <cmath>
using namespace hip_probe;
int main(int argc,char**argv){try{
 if(argc!=3)throw std::runtime_error("basis_probe MODULE OUTPUT_U32");Api a(7);a.Check(a.hipInit(0),"init");a.Check(a.hipSetDevice(0),"device");Handle m{},q{},f{};void*d{};
 a.Check(a.LoadModule(&m,argv[1]),"module");a.Check(a.hipStreamCreate(&q),"stream");a.Check(a.hipModuleGetFunction(&f,m,"c512_den_typed_basis"),"function");a.Check(a.hipMalloc(&d,256*4),"output");void*args[]={&d};a.Check(a.hipModuleLaunchKernel(f,1,1,1,32,1,1,0,q,args,nullptr),"launch");a.Check(a.hipStreamSynchronize(q),"completion");std::vector<unsigned>out(256);a.Check(a.hipMemcpy(out.data(),d,1024,2),"readback");std::ofstream(argv[2],std::ios::binary).write((char*)out.data(),1024);
 size_t expected_diff=0,e_diff=0;for(unsigned lane=0;lane<32;lane++){float expected=28.375f+.5f*(lane%16);unsigned bits;memcpy(&bits,&expected,4);for(unsigned e=0;e<8;e++){expected_diff+=out[lane*8+e]!=bits;e_diff+=out[lane*8+e]!=out[lane*8];}}
 printf("BASIS expected_diff=%zu within_lane_e_diff=%zu asymmetric_columns=16\n",expected_diff,e_diff);a.hipFree(d);a.hipStreamDestroy(q);a.hipModuleUnload(m);if(expected_diff||e_diff)throw std::runtime_error("typed denominator mapping falsified");return 0;
 }catch(const std::exception&e){fprintf(stderr,"BASIS_FAIL %s\n",e.what());return 1;}}
