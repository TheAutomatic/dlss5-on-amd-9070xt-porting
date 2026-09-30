// composite-quant GPU probe: the production instruction sequence vs the candidate, one input per lane, all 2^32 patterns in chunks.
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;
KERNEL void probe(unsigned char*o,unsigned char*n,uint base){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();uint b=base+i;float x=__builtin_bit_cast(float,b);
 uint h,ro,rn;float f;
 asm volatile("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(h):"v"(x));   // production w2_rtz8 / Hrtz
 asm volatile("v_cvt_f32_f16 %0, %1":"=v"(f):"v"(h));
 float fo=f+0.f;                                                  // w2_z0 / cw_output_value
 float fn=__builtin_bit_cast(float,b&0xffffe000u)+0.f;            // candidate
 asm volatile("s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1\n\t"
              "v_cvt_pk_fp8_f32 %0, %2, 0\n\t"
              "v_cvt_pk_fp8_f32 %1, %3, 0\n\t"
              "s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0":"=&v"(ro),"=&v"(rn):"v"(fo),"v"(fn));
 o[i]=(unsigned char)ro;n[i]=(unsigned char)rn;}
