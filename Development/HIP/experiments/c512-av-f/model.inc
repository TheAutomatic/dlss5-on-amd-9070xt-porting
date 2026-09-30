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
