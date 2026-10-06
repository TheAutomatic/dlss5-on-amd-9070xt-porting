// C512 grouped FFN in one wave. Each wave owns 16 tokens x 64 output channels;
// hidden fragments feed contraction directly instead of crossing four waves in LDS.
#ifndef C512_REGISTER_FFN
#define C512_REGISTER_FFN 0
#endif
#if C512_REGISTER_FFN
template<bool FuseMix>
DEV void c512_register_ffn_body(const float*in,const float*w,float*out,unsigned char*out8,uint tokens){
 uint first=(bid()/8)*16,group=bid()%8;
 if(first>=tokens)return;
 h8 input[4];
 if constexpr(FuseMix){
  f8 mixed[4]{};const _Float16*w16=reinterpret_cast<const _Float16*>(w);
  // Same half inputs, K16 steps and RNE WMMA as the independent production mix.
  for(uint k=0;k<512;k+=16){
   h8 a{};for(uint e=0;e<8;e++)a[e]=(_Float16)in[(first+rc())*512+k+gr()*8+e];
   _Pragma("unroll 4") for(uint ci=0;ci<4;ci++){
    h8 b;__builtin_memcpy(&b,w16+(group*64+ci*16+rc())*512+k+gr()*8,16);
    mixed[ci]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(b,a,mixed[ci]);
   }
  }
  _Pragma("unroll 4") for(uint ci=0;ci<4;ci++)for(uint e=0;e<8;e++)input[ci][e]=(_Float16)F(Hrtz(mixed[ci][e]));
 }else{
  _Pragma("unroll 4") for(uint kt=0;kt<4;kt++)for(uint e=0;e<8;e++)input[kt][e]=(_Float16)in[(first+rc())*512+group*64+kt*16+gr()*8+e];
 }
 f8 result[4]{};
 const _Float16*expand=reinterpret_cast<const _Float16*>(w+262144)+group*16384;
 const unsigned char*contract=reinterpret_cast<const unsigned char*>(w)+4*393216+group*16384;
 // ht is the original contraction K16 order; each expansion has its original K64 order.
 _Pragma("clang loop unroll(disable)") for(uint ht=0;ht<16;ht++){
  f8 expanded{};
  _Pragma("unroll 4") for(uint kt=0;kt<4;kt++){
   h8 b;__builtin_memcpy(&b,expand+(ht*16+rc())*64+kt*16+gr()*8,16);
   expanded=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(b,input[kt],expanded);
  }
  i2 hidden{};
  _Pragma("unroll 8") for(uint e=0;e<8;e++){
   float v=Hrtz(expanded[e]),gate=clampf(v,-4.f,4.f),poly=__builtin_fmaf(gate,__builtin_fmaf(absf(gate),-.055908203125f,.447265625f),.89453125f);
   uint byte=byte_F(v*poly);hidden[e/4]=int(uint(hidden[e/4])|(byte<<(8*(e%4))));
  }
  _Pragma("unroll 4") for(uint ci=0;ci<4;ci++){
   i2 b;__builtin_memcpy(&b,contract+(ci*16+rc())*256+ht*16+gr()*8,8);
   result[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,hidden,result[ci]);
  }
 }
 _Pragma("unroll 4") for(uint ci=0;ci<4;ci++)for(uint e=0;e<8;e++){
  uint r=first+rc(),c=group*64+ci*16+gr()*8+e;float v=F(Hrtz(result[ci][e]));
  out[r*512+c]=v;
  out8[((r/16)*16+c/32)*512+(r%16)*32+c%32]=static_cast<unsigned char>(__builtin_amdgcn_cvt_pk_fp8_f32(v,0.f,0,false));
 }
}
WAVE void split_ffn_register_t8(const float*in,const float*w,float*out,unsigned char*out8,uint tokens){c512_register_ffn_body<false>(in,w,out,out8,tokens);}
WAVE void split_ffn_mix_register_t8(const float*in,const float*w,float*out,unsigned char*out8,uint tokens){c512_register_ffn_body<true>(in,w,out,out8,tokens);}
#endif
