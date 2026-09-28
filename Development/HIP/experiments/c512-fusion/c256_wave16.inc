// Optional C256 window organization: 16 waves, two waves per head, two token tiles per wave.
// Uses the same two 16KiB planes; K and V exchange adds two group barriers.
#ifndef W2_C256_WAVE16
#define W2_C256_WAVE16 0
#endif
#if W2_C256_WAVE16
// Permit appending after the generated attention-only body as well.
#ifdef W2_ATTENTION_ONLY
#undef W2_ATTENTION_ONLY
#endif
using w16_i8=int __attribute__((ext_vector_type(8)));
template<uint C,bool ByteIn,bool ByteOut>
DEV void swin_wave16_body(const float*in,const float*fw,const float*aw,void*out_any,
 uint width,uint height,uint workw,uint workh,uint sx,uint sy,uint post){
 static_assert(C==256,"wave16 is C256 only");
 static_assert(W2_ROLL_QUERY && !W2_DEFER_Q,"wave16 requires rolled stored Q");
 static_assert(W2_FFN_QT_BATCH==2,"wave16 retains two-token-tile FFN batching");
 const uint win=__builtin_amdgcn_workgroup_id_x(),tid=__builtin_amdgcn_workitem_id_x(),head=tid/64;
 const uint qt0=((tid/32)&1u)*2u;
 const uint rc=w2_rc(),gr=w2_gr();
 if(win>=(workw/8)*(workh/8))return;
 __attribute__((shared)) unsigned char plane0[64*C],plane1[64*C];
 auto input=[&](uint tok,uint col)->float{
#if W2_DIRECT_COORDS
  int x=int((win%(workw/8))*8+tok%8)-int(sx),y=int((win/(workw/8))*8+tok/8)-int(sy);
#else
  uint p=w2_pixel(win,tok,workw);int x=int(p%workw)-int(sx),y=int(p/workw)-int(sy);
#endif
  bool valid=x>=0&&y>=0&&x<int(width)&&y<int(height);uint idx=valid?(uint(y)*width+uint(x))*C+col:col;
  float v;if constexpr(ByteIn)v=__builtin_amdgcn_cvt_f32_fp8(int(reinterpret_cast<const unsigned char*>(in)[idx]),0);else v=in[idx];
  return valid?v:0.f;
 };
 // Stage original input in A fragments. Preserve the byte cast used by pack4.
 for(uint qt=qt0;qt<qt0+2;qt++)for(uint ci=0;ci<2;ci++){
  i2 a{};
#if W2_BYTE_INPUT_LOADS
  if constexpr(ByteIn){a=w2_input_bytes<C>(in,win,qt*16+rc,head*32+ci*16+gr*8,workw,width,height,sx,sy);a[0]=int(w2_canonical_byte_word(uint(a[0])));a[1]=int(w2_canonical_byte_word(uint(a[1])));}
  else
#endif
  for(uint e=0;e<8;e++)w2_bits(a,e,q8(input(qt*16+rc,head*32+ci*16+gr*8+e)));
  w2_store<C>(plane0,qt,head*2+ci,a);
 }
 w2_sync();
 // Each head contracts only its own 128 hidden channels. Expanded fragments never enter LDS.
#if W2_FFN_QT_BATCH
 if constexpr(C==256){
 // Reuse each weight fragment across independent token tiles. Each accumulator keeps
 // the original kt or ht/tile order, including activation, FP8 and RTZ boundaries.
 constexpr uint B=W2_FFN_QT_BATCH;
 constexpr uint T=W2_HIDDEN_TILES;
 _Pragma("clang loop unroll(disable)") for(uint qb=qt0;qb<qt0+2;qb+=B){
  f8 contract[B][2]{};
  _Pragma("clang loop unroll(disable)") for(uint ht=0;ht<8;ht+=T){
   f8 expanded[B][T]{};
   for(uint kt=0;kt<C/16;kt++){
    i2 inputs[B];
    _Pragma("unroll") for(uint qi=0;qi<B;qi++)inputs[qi]=w2_load<C>(plane0,qb+qi,kt);
    _Pragma("unroll") for(uint tile=0;tile<T;tile++){
     i2 b=w2_weight(fw,head*128+(ht+tile)*16+rc,C,kt*16);
     _Pragma("unroll") for(uint qi=0;qi<B;qi++)expanded[qi][tile]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,inputs[qi],expanded[qi][tile]);
    }
   }
   _Pragma("unroll") for(uint tile=0;tile<T;tile++){
    i2 hidden[B];
    _Pragma("unroll") for(uint qi=0;qi<B;qi++){
     W2_Q8_DECL(packed);
     for(uint e=0;e<8;e++){float a=expanded[qi][tile][e],g=clampf(a,-4.f,4.f),q=__builtin_fmaf(absf(g),-.055908203125f,.447265625f),poly=__builtin_fmaf(g,q,.89453125f);W2_Q8_SETF(packed,e,a,poly);}W2_Q8_END(packed);hidden[qi]=packed;
    }
    for(uint ci=0;ci<2;ci++){
     i2 b=w2_weight(fw+4*C*C,head*32+ci*16+rc,4*C,head*128+(ht+tile)*16);
     _Pragma("unroll") for(uint qi=0;qi<B;qi++)contract[qi][ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,hidden[qi],contract[qi][ci]);
    }
   }
  }
  _Pragma("unroll") for(uint qi=0;qi<B;qi++)for(uint ci=0;ci<2;ci++){
#if W2_RTZ_PAIR
   f8 rounded=w2_rtz8(contract[qi][ci]);W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SET(a,e,rounded[e]);W2_Q8_END(a);
#else
   W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SET(a,e,Hrtz(contract[qi][ci][e]));W2_Q8_END(a);
#endif
   w2_store<C>(plane1,qb+qi,head*2+ci,a);
  }
 }
 }else
#endif
 {
 _Pragma("clang loop unroll(disable)") for(uint qt=qt0;qt<qt0+2;qt++){
  f8 contract[2]{};
  _Pragma("clang loop unroll(disable)") for(uint ht=0;ht<8;ht+=W2_HIDDEN_TILES){
   f8 expanded[W2_HIDDEN_TILES]{};
   for(uint kt=0;kt<C/16;kt++){
    i2 a=w2_load<C>(plane0,qt,kt);
    _Pragma("unroll") for(uint tile=0;tile<W2_HIDDEN_TILES;tile++){
     i2 b=w2_weight(fw,head*128+(ht+tile)*16+rc,C,kt*16);
     expanded[tile]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,expanded[tile]);
    }
   }
   _Pragma("unroll") for(uint tile=0;tile<W2_HIDDEN_TILES;tile++){
    W2_Q8_DECL(hidden);
    for(uint e=0;e<8;e++){float a=expanded[tile][e],g=clampf(a,-4.f,4.f),q=__builtin_fmaf(absf(g),-.055908203125f,.447265625f),poly=__builtin_fmaf(g,q,.89453125f);W2_Q8_SETF(hidden,e,a,poly);}W2_Q8_END(hidden);
    for(uint ci=0;ci<2;ci++){
     i2 b=w2_weight(fw+4*C*C,head*32+ci*16+rc,4*C,head*128+(ht+tile)*16);
     contract[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,hidden,contract[ci]);
    }
   }
  }
#if W2_RTZ_PAIR
  for(uint ci=0;ci<2;ci++){f8 rounded=w2_rtz8(contract[ci]);W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SET(a,e,rounded[e]);W2_Q8_END(a);w2_store<C>(plane1,qt,head*2+ci,a);}
#else
  for(uint ci=0;ci<2;ci++){W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SET(a,e,Hrtz(contract[ci][e]));W2_Q8_END(a);w2_store<C>(plane1,qt,head*2+ci,a);}
#endif
 }
 }
 w2_sync();
 // Cross-head FFN mixing plus the original residual. plane0 is now free for feature bytes.
 _Pragma("clang loop unroll(disable)") for(uint qt=qt0;qt<qt0+2;qt++){
  f8 result[2]{};
#if W2_RTZ_PAIR || W2_BYTE_INPUT_LOADS
  for(uint ci=0;ci<2;ci++){f8 products;i2 ib{};
   if constexpr(ByteIn&&W2_BYTE_INPUT_LOADS)ib=w2_input_bytes<C>(in,win,qt*16+rc,head*32+ci*16+gr*8,workw,width,height,sx,sy);
   for(uint e=0;e<8;e++){uint c=head*32+ci*16+gr*8+e;float v;if constexpr(ByteIn&&W2_BYTE_INPUT_LOADS)v=__builtin_amdgcn_cvt_f32_fp8(int((uint(ib[e/4])>>(8*(e%4)))&255u),0);else v=input(qt*16+rc,c);products[e]=v*fw[9*C*C+c];}
#if W2_RTZ_PAIR
   result[ci]=w2_rtz8(products);
#else
   for(uint e=0;e<8;e++)result[ci][e]=Hrtz(products[e]);
#endif
  }
#else
  for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){uint c=head*32+ci*16+gr*8+e;result[ci][e]=Hrtz(input(qt*16+rc,c)*fw[9*C*C+c]);}
#endif
  for(uint kt=0;kt<C/16;kt++)for(uint ci=0;ci<2;ci++){
   i2 a=w2_load<C>(plane1,qt,kt),b=w2_weight(fw+8*C*C,head*32+ci*16+rc,C,kt*16);
   result[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,result[ci]);
  }
  for(uint ci=0;ci<2;ci++){W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SET(a,e,result[ci][e]);W2_Q8_END(a);w2_store<C>(plane0,qt,head*2+ci,a);}
 }
 w2_sync();
 // Q/K use A-fragment orientation. V is computed in the opposite orientation,
 // directly becoming the B fragments consumed by P*V; no V transpose/staging needed.
 i2 qkv[3][4][2];
 i2 own_v[2][2],saved_feature[2][2];
#if W2_ROLL_QUERY && !W2_DEFER_Q
 w16_i8 query_words{};
#endif
 _Pragma("unroll") for(uint part=W2_DEFER_Q?1:0;part<3;part++){
  _Pragma("unroll 2") for(uint qt=qt0;qt<qt0+2;qt++){
   uint qlane=w2_lane();
#if W2_LAUNDER_QKV
   // Make each tile's coordinates a fresh compiler value, preventing whole-window
   // A/B fragments from being hoisted and kept live across all unrolled tiles.
   __asm__ volatile("" : "+v"(qlane));qlane&=31u;
#endif
   uint qrc=qlane&15u,qgr=qlane>>4;
   f8 q[2]{};
   for(uint kt=0;kt<C/16;kt++)for(uint ci=0;ci<2;ci++){
    i2 a=w2_load<C>(plane0,qt,kt,qlane),b=w2_weight(aw,part*C+head*32+ci*16+qrc,C,kt*16,qgr);
    if(part<2)q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,q[ci]);
    else q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(a,b,q[ci]);
   }
   float inv=1.f;
   if(part<2){float ss=w2_serial_norm(q[0],q[1]);inv=__builtin_amdgcn_rsqf(maxf(ss,6.198883056640625e-5f))*(part==0?aw[4*C*C+(C/32)*4096+head]:1.f);}
   for(uint ci=0;ci<2;ci++){W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SETF(a,e,q[ci][e],inv);W2_Q8_END(a);
#if W2_ROLL_QUERY && !W2_DEFER_Q
    if(part==0){query_words[(qt-qt0)*4+ci*2]=a[0];query_words[(qt-qt0)*4+ci*2+1]=a[1];}else
#endif
    {if(part==1)w2_store<C>(plane1,qt,head*2+ci,a);else own_v[qt-qt0][ci]=a;}
   }
   w2_schedule();
  }
 }
 // The FFN feature is needed only for this wave's final residual from here on.
 // Keep its two query tiles in registers, then let all heads retire feature reads.
 _Pragma("unroll 2") for(uint t=0;t<2;t++)for(uint ci=0;ci<2;ci++)saved_feature[t][ci]=w2_load<C>(plane0,qt0+t,head*2+ci);
 w2_sync();
 // Every wave reads all K tiles, while its own V fragments replace dead feature LDS.
 // The barrier also ensures no K reader remains before plane1 becomes AV output.
 _Pragma("unroll 4") for(uint kt=0;kt<4;kt++)for(uint ci=0;ci<2;ci++)qkv[1][kt][ci]=w2_load<C>(plane1,kt,head*2+ci);
 _Pragma("unroll 2") for(uint t=0;t<2;t++)for(uint ci=0;ci<2;ci++)w2_store<C>(plane0,qt0+t,head*2+ci,own_v[t][ci]);
 w2_sync();
 _Pragma("unroll 4") for(uint kt=0;kt<4;kt++)for(uint ci=0;ci<2;ci++)qkv[2][kt][ci]=w2_load<C>(plane0,kt,head*2+ci);
 // Each wave now has all keys/values and its own two query tiles. Original sums follow.
#if W2_ROLL_QUERY
 _Pragma("clang loop unroll(disable)")
#else
 _Pragma("unroll 4")
#endif
 for(uint qt=qt0;qt<qt0+2;qt++){
#if W2_ROLL_QUERY && !W2_DEFER_Q
  i2 query_frag[2];_Pragma("unroll 2") for(uint ci=0;ci<2;ci++)query_frag[ci]=i2{query_words[(qt-qt0)*4+ci*2],query_words[(qt-qt0)*4+ci*2+1]};
#endif
#if W2_DEFER_Q
  uint qlane=w2_lane();
#if W2_LAUNDER_QKV
  __asm__ volatile("" : "+v"(qlane));qlane&=31u;
#endif
  uint qrc=qlane&15u,qgr=qlane>>4;
  f8 query[2]{};
  for(uint kt=0;kt<C/16;kt++)for(uint ci=0;ci<2;ci++){
   i2 a=w2_load<C>(plane0,qt,kt,qlane),b=w2_weight(aw,head*32+ci*16+qrc,C,kt*16,qgr);
   query[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,query[ci]);
  }
  float qs=w2_serial_norm(query[0],query[1]);
  float qinv=__builtin_amdgcn_rsqf(maxf(qs,6.198883056640625e-5f))*aw[4*C*C+(C/32)*4096+head];
  i2 query_frag[2];for(uint ci=0;ci<2;ci++){W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SETF(a,e,query[ci][e],qinv);W2_Q8_END(a);query_frag[ci]=a;}
#endif
  h8 exponent[4];
  _Pragma("unroll 4") for(uint key=0;key<4;key++){
   f8 scores{};
   _Pragma("unroll 2") for(uint ci=0;ci<2;ci++)scores=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(qkv[1][key][ci],
#if W2_DEFER_Q || W2_ROLL_QUERY
    query_frag[ci],
#else
    qkv[0][qt][ci],
#endif
    scores);
   h8 ex{};
   for(uint e=0;e<8;e++){
    uint row=qt*16+rc,k=key*16+gr*8+e;
    float score=scores[e]+aw[4*C*C+head*4096+row*64+k],affine=clampf(score*.044921875f+1.30078125f,1.03125f,1.5693359375f);
    uint ah=(bits(affine)>>13)-0x1c000u;unsigned short hb=static_cast<unsigned short>(((ah<<5)+0x8000u)&65535u);ex[e]=__builtin_bit_cast(_Float16,hb);
   }
   exponent[key]=ex;
  }
  h8 ones{};for(uint e=0;e<8;e++)ones[e]=(_Float16)1.f;
  f8 sums[2]{};
  _Pragma("unroll 2") for(uint side=0;side<2;side++){
   _Pragma("unroll 2") for(uint half=0;half<2;half++)sums[side]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,exponent[side+2*half],sums[side]);
  }
  i2 prob[4];
  _Pragma("unroll 4") for(uint key=0;key<4;key++){W2_Q8_DECL(a);for(uint e=0;e<8;e++){float inv=w2_inverse(sums[0][e]+sums[1][e]);W2_Q8_SETF(a,e,float(exponent[key][e]),inv);}W2_Q8_END(a);prob[key]=a;}
  for(uint ci=0;ci<2;ci++){
   f8 av{};
   _Pragma("unroll 4") for(uint key=0;key<4;key++)av=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(qkv[2][key][ci],prob[key],av);
   W2_Q8_DECL(a);for(uint e=0;e<8;e++)W2_Q8_SET(a,e,av[e]);W2_Q8_END(a);w2_store<C>(plane1,qt,head*2+ci,a);
  }
  w2_schedule();
 }
 w2_sync();
 // All heads' AV ready in plane1; residual uses saved_feature. Preserve K order.
 const unsigned char*diag=reinterpret_cast<const unsigned char*>(aw)+4*(4*C*C+(C/32)*4096+C/32+C);
#if W2_FULL_WINDOW
 auto finish=[&](auto full){
 _Pragma("clang loop unroll(disable)") for(uint qt=qt0;qt<qt0+2;qt++){
  f8 result[2]{};
  for(uint ci=0;ci<2;ci++){
   uint ct=head*2+ci;i2 a;
#if defined(W2_ATTENTION_ONLY) && W2_DIRECT_FEATURE
   __builtin_memcpy(&a,feature+w2_pixel(win,qt*16+rc,workw)*C+ct*16+gr*8,8);
#else
   a=saved_feature[qt-qt0][ci];
#endif
   for(uint part=0;part<3;part++){i2 b;__builtin_memcpy(&b,diag+(part*(C/16)+ct)*512+(gr*16+rc)*8,8);result[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,result[ci]);}
  }
  for(uint kt=0;kt<C/16;kt++)for(uint ci=0;ci<2;ci++){
   i2 a=w2_load<C>(plane1,qt,kt),b=w2_weight(aw+3*C*C,head*32+ci*16+rc,C,kt*16);
   result[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,result[ci]);
  }
#if W2_DIRECT_COORDS
  uint x=(win%(workw/8))*8+(qt*16+rc)%8,y=(win/(workw/8))*8+(qt*16+rc)/8;
#else
  uint p=w2_pixel(win,qt*16+rc,workw),x=p%workw,y=p/workw;
#endif
  if(full||(x>=sx&&y>=sy&&x<sx+width&&y<sy+height)){
   uint dest=((y-sy)*width+x-sx)*C+head*32+gr*8;
   for(uint ci=0;ci<2;ci++){
    if constexpr(ByteOut){W2_Q8_DECL(a);for(uint e=0;e<8;e++){float v=result[ci][e];W2_Q8_SET(a,e,post==0?Hrtz(v):v);}W2_Q8_END(a);__builtin_memcpy(reinterpret_cast<unsigned char*>(out_any)+dest+ci*16,&a,8);}
    else for(uint e=0;e<8;e++){float v=result[ci][e];static_cast<float*>(out_any)[dest+ci*16+e]=post==3?Hrtz(v):post==0?F(Hrtz(v)):F(v);}
   }
  }
 }
 };
 uint tx=(win%(workw/8))*8,ty=(win/(workw/8))*8;
 if(tx>=sx&&ty>=sy&&tx+8<=sx+width&&ty+8<=sy+height)finish(w2_true{});else finish(w2_false{});
#else
 _Pragma("clang loop unroll(disable)") for(uint qt=qt0;qt<qt0+2;qt++){
  f8 result[2]{};
  for(uint ci=0;ci<2;ci++){
   uint ct=head*2+ci;i2 a;
#if defined(W2_ATTENTION_ONLY) && W2_DIRECT_FEATURE
   __builtin_memcpy(&a,feature+w2_pixel(win,qt*16+rc,workw)*C+ct*16+gr*8,8);
#else
   a=saved_feature[qt-qt0][ci];
#endif
   for(uint part=0;part<3;part++){i2 b;__builtin_memcpy(&b,diag+(part*(C/16)+ct)*512+(gr*16+rc)*8,8);result[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,result[ci]);}
  }
  for(uint kt=0;kt<C/16;kt++)for(uint ci=0;ci<2;ci++){
   i2 a=w2_load<C>(plane1,qt,kt),b=w2_weight(aw+3*C*C,head*32+ci*16+rc,C,kt*16);
   result[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,a,result[ci]);
  }
#if W2_DIRECT_COORDS
  uint x=(win%(workw/8))*8+(qt*16+rc)%8,y=(win/(workw/8))*8+(qt*16+rc)/8;
#else
  uint p=w2_pixel(win,qt*16+rc,workw),x=p%workw,y=p/workw;
#endif
  if(x>=sx&&y>=sy&&x<sx+width&&y<sy+height){
   uint dest=((y-sy)*width+x-sx)*C+head*32+gr*8;
   for(uint ci=0;ci<2;ci++){
    if constexpr(ByteOut){W2_Q8_DECL(a);for(uint e=0;e<8;e++){float v=result[ci][e];W2_Q8_SET(a,e,post==0?Hrtz(v):v);}W2_Q8_END(a);__builtin_memcpy(reinterpret_cast<unsigned char*>(out_any)+dest+ci*16,&a,8);}
    else for(uint e=0;e<8;e++){float v=result[ci][e];static_cast<float*>(out_any)[dest+ci*16+e]=post==3?Hrtz(v):post==0?F(Hrtz(v)):F(v);}
   }
  }
 }
#endif
}
#define W16_KERNEL(NAME,BI,BO) KERNEL __attribute__((amdgpu_flat_work_group_size(512,512))) void NAME(const float*in,const float*fw,const float*aw,void*out,uint w,uint h,uint ww,uint hh,uint sx,uint sy,uint post){swin_wave16_body<256,BI,BO>(in,fw,aw,out,w,h,ww,hh,sx,sy,post);}
W16_KERNEL(c256_wave16,false,false)
W16_KERNEL(c256_wave16_bi,true,false)
W16_KERNEL(c256_wave16_bo,false,true)
W16_KERNEL(c256_wave16_bi_bo,true,true)
#undef W16_KERNEL
#endif
