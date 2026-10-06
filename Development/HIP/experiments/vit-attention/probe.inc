// Experimental organization only: unchanged QK K16 order, exp map,
// denominator K16 order, AV K16 order, float reciprocal and RTZ epilogue.
template<unsigned G,unsigned U,bool HeadMajor,bool Native=false>
DEV void vit_probe_body(const float*in,float*out,uint tokens){
 uint qt=(tokens+15)/16,groups=(qt+G-1)/G,wave=__builtin_amdgcn_workitem_id_x()/32;
 uint head=HeadMajor?bid()/groups:bid()%32;
 uint first=(HeadMajor?(bid()%groups)*G+wave:(bid()/32)*G+wave)*16;
 if(first>=tokens)return;
 const unsigned char*in8=reinterpret_cast<const unsigned char*>(in);
 i2 q[2]{};
 for(uint k=0;k<32;k+=16)__builtin_memcpy(&q[k/16],in8+(first+rc())*1024+head*32+k+gr()*8,8);
 h8 ones{};for(uint e=0;e<8;e++)ones[e]=(_Float16)1.f;
 f8 sum{},acc[2]{};
 for(uint base=0;base<tokens;base+=16*U){
  i2 keys[U][2]{},values[U][2]{};f8 score[U]{};
  #pragma unroll
  for(uint t=0;t<U;t++)if(base+16*t<tokens){
   uint key=base+16*t;
   for(uint k=0;k<32;k+=16)__builtin_memcpy(&keys[t][k/16],in8+(tokens+key+rc())*1024+head*32+k+gr()*8,8);
   for(uint c=0;c<2;c++)for(uint e=0;e<8;e++){
    uint b=in8[(2*tokens+key+gr()*8+e)*1024+head*32+c*16+rc()];
    values[t][c][e/4]=int(uint(values[t][c][e/4])|(b<<(8*(e%4))));
   }
  }
  #pragma unroll
  for(uint t=0;t<U;t++)if(base+16*t<tokens){
   for(uint k=0;k<2;k++)score[t]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(keys[t][k],q[k],score[t]);
  }
  #pragma unroll
  for(uint t=0;t<U;t++)if(base+16*t<tokens){
   h8 x{};i2 xb{};
   for(uint e=0;e<8;e++){
    float af=clampf(score[t][e]*from_half(0x2dbb)+1.708984375f,1.439453125f,1.9775390625f);
    uint hb=(bits(af)>>13)-0x1c000u;unsigned short u=(unsigned short)(((hb<<4)+0x4000u)&65535u);
    union{unsigned short u;_Float16 h;}cv;cv.u=u;x[e]=cv.h;if constexpr(Native)pack(xb,e,float(cv.h));else pack(xb,e,from_half(u));
   }
   sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(x,ones,sum);
   for(uint c=0;c<2;c++)acc[c]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(xb,values[t][c],acc[c]);
  }
 }
 float inv[8];for(uint e=0;e<8;e++)inv[e]=1.f/sum[e];
 for(uint c=0;c<2;c++)for(uint e=0;e<8;e++)reinterpret_cast<unsigned char*>(out)[(first+gr()*8+e)*1024+head*32+c*16+rc()]=byte_F(Hrtz(acc[c][e]*inv[e]));
}
#define VP(NAME,G,U,H) KERNEL __attribute__((amdgpu_flat_work_group_size(32*G,32*G))) void NAME(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_probe_body<G,U,H>(in,out,tokens);}
VP(vit_probe_g1_u1_h0,1,1,false)
VP(vit_probe_g1_u1_h1,1,1,true)
VP(vit_probe_g4_u1_h1,4,1,true)
VP(vit_probe_g1_u4_h0,1,4,false)
VP(vit_probe_g4_u4_h1,4,4,true)

#define VPN(NAME,G,U,H) KERNEL __attribute__((amdgpu_flat_work_group_size(32*G,32*G))) void NAME(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_probe_body<G,U,H,true>(in,out,tokens);}
VPN(vit_probe_native_g1_u1_h0,1,1,false)
VPN(vit_probe_native_g1_u4_h0,1,4,false)
VPN(vit_probe_native_g4_u4_h1,4,4,true)
