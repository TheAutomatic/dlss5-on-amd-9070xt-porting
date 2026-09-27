#include "hip_reference_network.h"
#include <fstream>
#include <string>
#include <vector>
#include <cmath>
#include <cstdio>
int main(int argc,char**argv){if(argc!=2)return 2;for(int b:{23,24,25,26,27,28,29,30,40,41,44,45,47}){auto v=hip_reference::ReadWeights(std::string(argv[1])+"/block"+std::to_string(b)+"-ffwd.f32");if(v.size()<262144)return 3;v.resize(262144);unsigned nf=0,ov=0;float mx=0;for(float x:v){nf+=!std::isfinite(x);ov+=std::fabs(x)>65504;mx=std::fmax(mx,std::fabs(x));}printf("block=%d mix_weights=%zu nonfinite=%u half_overflow=%u maxabs=%.9g\n",b,v.size(),nf,ov,mx);if(nf||ov)return 1;}return 0;}
