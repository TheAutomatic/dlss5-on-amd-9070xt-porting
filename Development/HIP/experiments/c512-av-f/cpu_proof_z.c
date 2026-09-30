// c512-av-f CPU proof over all finite 32-bit x (fp8 = E4M3 RNE saturating model, F = deep_fast/multihead F):
//   AV : fp8(clamp(F(x))) vs fp8(clamp(x))   -> expected: differ only at x = -0
//   QKV: fp8(F(x)) vs fp8(clamp(x + 0))      -> expected: never differ
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
static float fb(uint32_t u){float f;memcpy(&f,&u,4);return f;}
static uint32_t bf(float f){uint32_t u;memcpy(&u,&f,4);return u;}
#include "model.inc"
#include "fmodel.inc"
static float cl(float x){return fminf(fmaxf(x,-448.f),448.f);}
int main(void){uint64_t n=0,d1=0,d1z=0,d2=0;
 for(uint64_t i=0;i<=0xffffffffull;i++){uint32_t b=(uint32_t)i;float x=fb(b);if(!isfinite(x))continue;n++;
  volatile float z=0.f;float xz=x+z;
  uint32_t o=fp8(cl(Fm(x))),n1=fp8(cl(x)),n2=fp8(cl(xz));
  if(o!=n1){d1++;if(b==0x80000000u)d1z++;else if(d1-d1z<10)printf("AV %08x %02x %02x\n",b,o,n1);}
  if(o!=n2){d2++;if(d2<10)printf("QKV %08x %02x %02x\n",b,o,n2);}}
 printf("finite=%llu AV diff=%llu (x=-0: %llu) QKV(x+0) diff=%llu\n",(unsigned long long)n,(unsigned long long)d1,(unsigned long long)d1z,(unsigned long long)d2);
 return (d1!=d1z||d2)?1:0;}
