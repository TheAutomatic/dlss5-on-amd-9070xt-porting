// composite-quant CPU proof: for every 32-bit pattern x, compare
//   O(x) = fp8sat( float(half_rtz(x)) + 0 )          (production: v_cvt_pkrtz_f16_f32, v_cvt_f32_f16, +0, MODE.FP16_OVFL v_cvt_pk_fp8_f32)
//   N(x) = fp8sat( bits(x) & 0xffffe000 + 0 )        (candidate: one v_and_b32)
// E4M3 fn: RNE, finite |v| >= 448 saturates to 0x7e/0xfe (MODE.FP16_OVFL). Non-finite inputs are reported, not modelled
// (the GPU run with the real instructions covers them). Mismatches are classified and printed.
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
static float fb(uint32_t u){float f;memcpy(&f,&u,4);return f;}
static uint32_t bf(float f){uint32_t u;memcpy(&u,&f,4);return u;}
static float half_rtz(float x){ // finite x only
  uint32_t b=bf(x),s=b&0x80000000u,a=b&0x7fffffffu;float m=fb(a);
  if(m>65504.f)return fb(s|bf(65504.f));
  if(m>=0x1p-14f)return fb(s|(a&0xffffe000u));
  double q=floor((double)m*0x1p24)*0x1p-24; return fb(s|bf((float)q));}
static uint32_t fp8(float v){ // finite v
  uint32_t s=(bf(v)>>24)&0x80u;double a=fabs((double)v);
  if(a>=448.0)return s|0x7eu;
  int e;frexp(a,&e); /* a=m*2^e, m in [.5,1) -> exponent e-1 */
  int ex=e-1; if(a==0)return s;
  double step= ex< -6 ? 0x1p-9 : ldexp(1.0,ex-3);
  double r=nearbyint(a/step); double q=r*step; // RNE (default rounding mode)
  if(q>=448.0)return s|0x7eu; // 448 itself is representable; >448 cannot occur below 448 input except 480 -> sat
  if(q==0)return s;
  int qe;frexp(q,&qe);qe-=1;
  if(qe< -6){return s|(uint32_t)(q/0x1p-9);} // subnormal: mantissa k, exponent field 0
  uint32_t mant=(uint32_t)(q/ldexp(1.0,qe)*8.0)-8u; return s|((uint32_t)(qe+7)<<3)|mant;}
int main(void){
  uint64_t n=0,mis=0,nonfinite=0,mis_negtiny=0,mis_other=0,dif_single=0;
  for(uint64_t i=0;i<=0xffffffffull;i++){uint32_t b=(uint32_t)i;float x=fb(b);
    if(!isfinite(x)){nonfinite++;continue;}
    n++;
    float o=half_rtz(x)+0.f, c=fb(b&0xffffe000u)+0.f;
    uint32_t O=fp8(o),N=fp8(c);
    if(fp8(x+0.f)!=O)dif_single++;
    if(O!=N){mis++; if((b&0x80000000u)&&fabsf(x)<0x1p-24f)mis_negtiny++; else {mis_other++; if(mis_other<10)printf("OTHER %08x O=%02x N=%02x\n",b,O,N);}}
  }
  printf("finite=%llu nonfinite(skipped)=%llu mismatches=%llu (neg |x|<2^-24: %llu, other: %llu)\n",(unsigned long long)n,(unsigned long long)nonfinite,(unsigned long long)mis,(unsigned long long)mis_negtiny,(unsigned long long)mis_other);
  printf("reference: fp8(x+0) single rounding differs from O on %llu finite inputs (half rounding is load-bearing)\n",(unsigned long long)dif_single);
  return mis_other?1:0;}
