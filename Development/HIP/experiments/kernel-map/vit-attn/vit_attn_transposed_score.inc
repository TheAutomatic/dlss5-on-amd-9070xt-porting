#ifndef HIP_VIT_ATTN_TRANSPOSED_SCORE
#define HIP_VIT_ATTN_TRANSPOSED_SCORE 0
#endif
#if HIP_VIT_ATTN_TRANSPOSED_SCORE
template<uint MAXT,bool ByteInput=false,bool ByteOut=false>
DEV void vit_attention_transposed_score_body(const float*in,float*out,uint tokens){
 uint head=bid()%32,first=bid()/32*16;if(first>=tokens)return;

 const unsigned char*in8=reinterpret_cast<const unsigned char*>(in);
 i2 q[2]{};for(uint k=0;k<32;k+=16){if constexpr(ByteInput)__builtin_memcpy(&q[k/16],in8+(first+rc())*1024+head*32+k+gr()*8,8);else for(uint e=0;e<8;e++){uint j=k+gr()*8+e;pack(q[k/16],e,in[(first+rc())*1024+head*32+j]);}}
 h8 ones{};for(uint e=0;e<8;e++)ones[e]=(_Float16)1.f;
 f8 sum{},acc[2]{};
 for(uint key=0,tile=0;key<tokens;key+=16,tile^=1u){f8 a{};
  for(uint k=0;k<32;k+=16){i2 y{};if constexpr(ByteInput)__builtin_memcpy(&y,in8+(tokens+key+rc())*1024+head*32+k+gr()*8,8);else for(uint e=0;e<8;e++){uint j=k+gr()*8+e;pack(y,e,in[(tokens+key+rc())*1024+head*32+j]);}a=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(y,q[k/16],a);}
  // Swapping Q/K operands transposes the score output, directly matching
  // the A-fragment consumed by denominator and PV. Same K0 then K16 order.
  h8 x{};i2 xb{};
  for(uint e=0;e<8;e++){
   float af=clampf(a[e]*from_half(0x2dbb)+1.708984375f,1.439453125f,1.9775390625f);
   uint hb=(bits(af)>>13)-0x1c000u;unsigned short u=(unsigned short)(((hb<<4)+0x4000u)&65535u);
   union{unsigned short u;_Float16 h;}cv;cv.u=u;x[e]=cv.h;pack(xb,e,from_half(u));
  }
  sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(x,ones,sum);
  for(uint c=0;c<2;c++){i2 y{};for(uint e=0;e<8;e++){uint vkey=key+gr()*8+e;if constexpr(ByteInput){uint b=in8[(2*tokens+vkey)*1024+head*32+c*16+rc()];y[e/4]=int(uint(y[e/4])|(b<<(8*(e%4))));}else pack(y,e,in[(2*tokens+vkey)*1024+head*32+c*16+rc()]);}acc[c]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(xb,y,acc[c]);}
 }
 float inv[8];for(uint e=0;e<8;e++)inv[e]=1.f/sum[e];

 for(uint c=0;c<2;c++)for(uint e=0;e<8;e++){if constexpr(ByteOut)reinterpret_cast<unsigned char*>(out)[(first+gr()*8+e)*1024+head*32+c*16+rc()]=byte_F(Hrtz(acc[c][e]*inv[e]));else out[(first+gr()*8+e)*1024+head*32+c*16+rc()]=F(Hrtz(acc[c][e]*inv[e]));}
}
#endif
