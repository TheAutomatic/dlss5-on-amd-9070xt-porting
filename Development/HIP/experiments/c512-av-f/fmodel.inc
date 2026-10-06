// F() of deep_fast.hip (HIP_NATIVE_FP8_F + HIP_BRANCHLESS_F): a==0 ? +0 : decode(fp8_rne(clamp(x,-448,448))). Finite x only.
static float fp8_decode(uint32_t q){float s=(q&0x80u)?-1.f:1.f;uint32_t e=(q>>3)&15u,m=q&7u;float v=e?ldexpf(1.f+m/8.f,(int)e-7):ldexpf((float)m,-9);return s*v;}
static float Fm(float x){if((bf(x)&0x7fffffffu)==0)return 0.f;float c=fminf(fmaxf(x,-448.f),448.f);return fp8_decode(fp8(c));}
