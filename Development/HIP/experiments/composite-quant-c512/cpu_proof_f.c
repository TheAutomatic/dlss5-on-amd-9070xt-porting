// composite-quant-c512 CPU proof: for every finite 32-bit x compare the C512 f32 epilogue
//   O(x) = F(Hrtz(x))                 (production: v_cvt_pkrtz_f16_f32 + v_cvt_f32_f16, then F)
//   N(x) = F(bits(x) & 0xffffe000)    (candidate: one v_and_b32, then F)
// as 32-bit patterns (the output is a float, so +0 and -0 are different results). Non-finite x: GPU run only.
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
static float fb(uint32_t u){float f;memcpy(&f,&u,4);return f;}
static uint32_t bf(float f){uint32_t u;memcpy(&u,&f,4);return u;}
#include "model.inc"
#include "fmodel.inc"
int main(void){
  uint64_t n=0,nf=0,mis=0,mis_negtiny=0,mis_other=0,dom_mis=0,dif_single=0,dif_single_dom=0;
  for(uint64_t i=0;i<=0xffffffffull;i++){uint32_t b=(uint32_t)i;float x=fb(b);
    if(!isfinite(x)){nf++;continue;}
    n++;
    uint32_t O=bf(Fm(half_rtz(x))),N=bf(Fm(fb(b&0xffffe000u)));
    int dom=(x==0.f)||fabsf(x)>=0x1p-18f; /* WMMA FP8-grid sums: +0 or a nonzero multiple of 2^-18 */
    if(bf(Fm(x))!=O){dif_single++;if(dom)dif_single_dom++;}
    if(O!=N){mis++;if(dom)dom_mis++;if((b&0x80000000u)&&fabsf(x)<0x1p-24f)mis_negtiny++;else{mis_other++;if(mis_other<10)printf("OTHER %08x O=%08x N=%08x\n",b,O,N);}}
  }
  printf("finite=%llu nonfinite(skipped)=%llu O!=N=%llu (neg 0<|x|<2^-24: %llu, other: %llu, in WMMA domain: %llu)\n",(unsigned long long)n,(unsigned long long)nf,(unsigned long long)mis,(unsigned long long)mis_negtiny,(unsigned long long)mis_other,(unsigned long long)dom_mis);
  printf("reference: F(x) without the half rounding differs from O on %llu finite inputs, %llu of them in the WMMA domain\n",(unsigned long long)dif_single,(unsigned long long)dif_single_dom);
  return (mis_other||dom_mis)?1:0;}
