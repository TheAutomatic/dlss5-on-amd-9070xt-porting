// pair-unpack probe: for every E4M3 byte b, (1) q8(cvt_f32_fp8(b)) == b? (2) cvt_pk_f32_fp8 (two at once) == two cvt_f32_fp8?
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;
typedef float f2 __attribute__((ext_vector_type(2)));
KERNEL void probe(uint*out){
 uint b=__builtin_amdgcn_workitem_id_x()+__builtin_amdgcn_workgroup_id_x()*256;if(b>=256)return;
 uint b2=(b*37u+11u)&255u,w=b|(b2<<8)|(b<<16)|(b2<<24);
 float s0=__builtin_amdgcn_cvt_f32_fp8(int(w),0),s1=__builtin_amdgcn_cvt_f32_fp8(int(w),1);
 f2 lo=__builtin_amdgcn_cvt_pk_f32_fp8(int(w),false),hi=__builtin_amdgcn_cvt_pk_f32_fp8(int(w),true);
 uint rt=uint(__builtin_amdgcn_cvt_pk_fp8_f32(s0,s0,0,false))&255u;
 out[b*4+0]=rt;
 out[b*4+1]=__builtin_bit_cast(uint,lo.x)==__builtin_bit_cast(uint,s0)&&__builtin_bit_cast(uint,lo.y)==__builtin_bit_cast(uint,s1)?1u:0u;
 out[b*4+2]=__builtin_bit_cast(uint,hi.x)==__builtin_bit_cast(uint,__builtin_amdgcn_cvt_f32_fp8(int(w),2))&&__builtin_bit_cast(uint,hi.y)==__builtin_bit_cast(uint,__builtin_amdgcn_cvt_f32_fp8(int(w),3))?1u:0u;
 out[b*4+3]=__builtin_bit_cast(uint,s0);
 if(b==5){out[1024]=__builtin_bit_cast(uint,s0);out[1025]=__builtin_bit_cast(uint,s1);out[1026]=__builtin_bit_cast(uint,lo.x);out[1027]=__builtin_bit_cast(uint,lo.y);out[1028]=__builtin_bit_cast(uint,hi.x);out[1029]=__builtin_bit_cast(uint,hi.y);out[1030]=w;}}
