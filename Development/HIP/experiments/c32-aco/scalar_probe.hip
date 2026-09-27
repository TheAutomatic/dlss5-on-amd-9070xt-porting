#define DEV __attribute__((device)) __attribute__((always_inline))
typedef unsigned uint;
DEV uint q(float x){return uint(__builtin_amdgcn_cvt_pk_fp8_f32(__builtin_amdgcn_fmed3f(x,-448.f,448.f),0.f,0,false))&255u;}
DEV float oldF(float x){uint bits=__builtin_bit_cast(uint,x)&0x7fffffff;float r=__builtin_amdgcn_cvt_f32_fp8(int(q(x)),0);return bits==0?0.f:r;}
extern "C" __attribute__((global)) void probe(uint*out){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();
 if(i>=65536)return;
 float v=float(__builtin_bit_cast(_Float16,(unsigned short)i));
 out[i*3]=q(oldF(v));out[i*3+1]=q(v+0.f);
 uint bad=0;
 for(uint t=0;t<16;t++){
  uint bx=i*1664525u+t*1013904223u,by=~bx;float x=__builtin_bit_cast(float,bx),y=__builtin_bit_cast(float,by);uint a,b,c;
  asm("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(a):"v"(x));
  asm("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(b):"v"(y));
  asm("v_cvt_pkrtz_f16_f32 %0, %1, %2":"=v"(c):"v"(x),"v"(y));
  float fa,fb;
  asm("v_cvt_f32_f16 %0, %1":"=v"(fa):"v"(a));
  asm("v_cvt_f32_f16 %0, %1":"=v"(fb):"v"(b));
  uint olda=__builtin_bit_cast(unsigned short,(_Float16)fa),oldb=__builtin_bit_cast(unsigned short,(_Float16)fb);
  bad+=(olda!=(c&65535))||(oldb!=(c>>16));
 }
 out[i*3+2]=bad;
}
