// Diagnostic temporal primitives. No network activation/precision changes.
typedef unsigned int uint;typedef unsigned long long u64;
#define KERNEL extern "C" __attribute__((global))
__attribute__((device)) __attribute__((always_inline)) uint fb(float x){return __builtin_bit_cast(uint,x);}
__attribute__((device)) __attribute__((always_inline)) float hf(unsigned short h){float v;asm("v_cvt_f32_f16 %0, %1":"=v"(v):"v"(uint(h)));return v;}
__attribute__((device)) __attribute__((always_inline)) int fe(float x){return int((fb(x)>>23)&255)-126;}
// Direct binary64 -> binary16 RNE, avoiding a binary32 intermediate/double rounding.
__attribute__((device)) __attribute__((always_inline)) unsigned short half_rne(double x){
 u64 b=__builtin_bit_cast(u64,x),a=b&0x7fffffffffffffffULL;uint sign=uint(b>>48)&0x8000u;
 if(!a)return static_cast<unsigned short>(sign);
 int exp=int(a>>52)-1023+15;u64 m=(a&0xfffffffffffffULL)|0x10000000000000ULL;
 if((a>>52)==2047)return static_cast<unsigned short>(sign|0x7c00u|(a&0xfffffffffffffULL?0x200u:0u));
 if(exp>=31)return static_cast<unsigned short>(sign|0x7c00u);
 int shift=42+(exp<1?1-exp:0);if(shift>63)return static_cast<unsigned short>(sign);
 u64 q=m>>shift,r=m&((1ULL<<shift)-1),mid=1ULL<<(shift-1);q+=r>mid||(r==mid&&(q&1));
 uint h=exp>0?uint((exp-1)*1024)+uint(q):uint(q);return static_cast<unsigned short>(sign|h);
}
KERNEL void hip_gate_sigmoid(float*out){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i>=65536)return;
 float x=hf(static_cast<unsigned short>(i)),t=x*(-1.4426950216293334961f);
 float e=__builtin_amdgcn_exp2f(t),d=e+1.f;out[i]=__builtin_amdgcn_rcpf(d);
}
// Native-post 27-bit product alignment, two K16 chunks, half accumulator between chunks.
KERNEL void hip_gate_head(const unsigned short*features,const unsigned short*weights,unsigned short*out,uint n){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i>=n)return;
 float acc=0.f;
 for(uint k=0;k<2;k++){
  int exp=-1000;float x[16],w[16];
  for(uint j=0;j<16;j++){x[j]=hf(features[i*32+k*16+j]);w[j]=hf(weights[k*16+j]);if(x[j]!=0.f&&w[j]!=0.f){int e=fe(x[j])+fe(w[j]);exp=e>exp?e:exp;}}
  if(acc!=0.f){int e=fe(acc)+1;exp=e>exp?e:exp;}if(exp==-1000)exp=0;
  double quantum=__builtin_bit_cast(double,u64(exp-27+1023)<<52),sum=0.;
  for(uint j=0;j<16;j++){double p=double(x[j])*double(w[j]);sum+=__builtin_trunc(p/quantum)*quantum;}
  acc=hf(half_rne(sum+double(acc)));
 }
 out[i]=half_rne(double(acc));
}
// raw_warp.xyz is the unnormalized five-tap RGB sum; .w is reciprocal(sum of tap weights).
// Given validated half logit and NVIDIA scalar table, preserve original gate coefficient/FMA ordering.
KERNEL void hip_gate_resolve(const float*rgb,const float*raw_warp,const unsigned short*logit,const float*sigmoid,float*out,uint n,float blend,uint enabled){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i>=n)return;
 if(!enabled){for(uint c=0;c<3;c++)out[i*3+c]=rgb[i*3+c];return;}
 float w=__builtin_fmaf(sigmoid[logit[i]],blend,0.f);w=__builtin_fminf(__builtin_fmaxf(w,0.f),1.f);
 for(uint c=0;c<3;c++){float delta=__builtin_fmaf(raw_warp[i*4+3],raw_warp[i*4+c],-rgb[i*3+c]);out[i*3+c]=__builtin_fmaf(w,delta,rgb[i*3+c]);}
}
