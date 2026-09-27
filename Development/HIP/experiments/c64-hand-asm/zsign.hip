// Can an fp8 WMMA with C = +0 produce -0? Cases per lane block of 8 outputs (lane 0 values reported, all lanes checked).
#define KERNEL extern "C" __attribute__((global))
typedef unsigned int uint;typedef int i2 __attribute__((ext_vector_type(2)));typedef float f8 __attribute__((ext_vector_type(8)));
static __attribute__((device)) i2 rep(uint b){uint w=b|(b<<8)|(b<<16)|(b<<24);return i2{int(w),int(w)};}
KERNEL void probe(uint*out){
 uint l=__builtin_amdgcn_workitem_id_x();f8 z={0,0,0,0,0,0,0,0};
 f8 nz;for(int i=0;i<8;i++)nz[i]=-0.0f;
 // 0: A=-0, B=+1, C=+0   1: A=-0,B=+1,C=-0   2: A=+1/-1 alternating bytes (exact cancel), B=+1, C=+0
 // 3: chained: C = result of case 0, A=-0,B=+1   4: A=-1,B=+tiny so products round? (exact in f32) with C=+0 then add +1-1 pattern
 f8 r0=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(rep(0x80),rep(0x38),z);
 f8 r1=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(rep(0x80),rep(0x38),nz);
 uint alt=0x38|(0xb8<<8)|(0x38<<16)|(0xb8<<24);i2 A2={int(alt),int(alt)};
 f8 r2=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(A2,rep(0x38),z);
 f8 r3=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(rep(0x80),rep(0x38),r0);
 f8 r4=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(A2,rep(0x38),nz);
 uint neg[5]={0,0,0,0,0};
 for(int i=0;i<8;i++){neg[0]|=__builtin_bit_cast(uint,r0[i]);neg[1]|=__builtin_bit_cast(uint,r1[i]);neg[2]|=__builtin_bit_cast(uint,r2[i]);neg[3]|=__builtin_bit_cast(uint,r3[i]);neg[4]|=__builtin_bit_cast(uint,r4[i]);}
 for(int k=0;k<5;k++)out[l*5+k]=neg[k];}
