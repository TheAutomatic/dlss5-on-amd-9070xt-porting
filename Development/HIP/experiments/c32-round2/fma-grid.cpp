// Hidden WMMA operands are E4M3 multiples of 2^-9. A finite dot from zero stays on the 2^-18 grid.
// Exhaustively compare packed FP8 over the unclamped activation interval; outside it g is +/-4.
// CPU screening only; GPU confirmation is required before adopting any zero-difference variant.
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
static unsigned q8(float x){unsigned b;std::memcpy(&b,&x,4);unsigned a=b&0x7fffffff,s=(b>>24)&128;
 if(a>=0x43e00000u)return s|126;
 if(a<0x3c800000u)return s|unsigned(std::nearbyint(std::fabs(x)*512.f));
 unsigned r=(a+0x7ffffu+((a>>20)&1u))>>20;return s|((r-960)>126?126:r-960);
}
int main(){unsigned bad[3]={};
 for(int n=-(4<<18);n<=(4<<18);n++){
  float v=std::ldexp(float(n),-18),g=v,q=std::fabs(g)*(-.055908203125f)+.447265625f,p=g*q+.89453125f;
  float fq=std::fma(std::fabs(g),-.055908203125f,.447265625f);
  float y[3]={v*(g*fq+.89453125f),v*std::fma(g,q,.89453125f),v*std::fma(g,fq,.89453125f)};
  for(int j=0;j<3;j++)if(q8(v*p)!=q8(y[j])){if(bad[j]<3)printf("mismatch variant=%d n=%d x=%.9g old=%02x new=%02x\n",j,n,v,q8(v*p),q8(y[j]));bad[j]++;}
 }
 printf("GRID=2097153 q_fma_bad=%u p_fma_bad=%u both_fma_bad=%u\n",bad[0],bad[1],bad[2]);
}
