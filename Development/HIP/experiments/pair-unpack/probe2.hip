// pair-unpack probe 2: raw v_cvt_pk_f32_fp8 results for a known word, stored lane by lane.
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;
typedef float f2 __attribute__((ext_vector_type(2)));
KERNEL void probe(uint*out){
 if(__builtin_amdgcn_workitem_id_x())return;
 uint w=0xc4054038u; // bytes 0x38(1.0) 0x40(2.0) 0x05 0xc4(-3.0)
 f2 a;asm volatile("v_cvt_pk_f32_fp8 %0, %1" : "=v"(a) : "v"(w));
 f2 b;asm volatile("v_cvt_pk_f32_fp8 %0, %1 op_sel:[1,0]" : "=v"(b) : "v"(w));
 f2 c=__builtin_amdgcn_cvt_pk_f32_fp8(int(w),false);
 out[0]=__builtin_bit_cast(uint,a.x);out[1]=__builtin_bit_cast(uint,a.y);out[2]=__builtin_bit_cast(uint,b.x);out[3]=__builtin_bit_cast(uint,b.y);
 out[4]=__builtin_bit_cast(uint,c.x);out[5]=__builtin_bit_cast(uint,c.y);
 out[6]=__builtin_bit_cast(uint,__builtin_amdgcn_cvt_f32_fp8(int(w),0));out[7]=__builtin_bit_cast(uint,__builtin_amdgcn_cvt_f32_fp8(int(w),1));out[8]=__builtin_bit_cast(uint,__builtin_amdgcn_cvt_f32_fp8(int(w),2));out[9]=__builtin_bit_cast(uint,__builtin_amdgcn_cvt_f32_fp8(int(w),3));}
