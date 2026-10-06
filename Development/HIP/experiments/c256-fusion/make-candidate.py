#!/usr/bin/env python3
"""Create isolated wave_owned_mh.inc candidate; never edit input tree."""
import argparse,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=None);p.add_argument('--output',type=Path,default=Path('/tmp/c256-fusion/code/wave_owned_mh.inc'));args=p.parse_args()
s=args.source.read_text() if args.source else subprocess.check_output(['git','show','4f0a62f7:hip/wave_owned_mh.inc'],cwd=Path(__file__).resolve().parents[4],text=True)
anchor='struct w2_true{'
assert s.count(anchor)==1
s=s.replace(anchor,'''// C256-only scheduling experiments. Defaults preserve the existing source path.
#ifndef W2_FFN_QT_BATCH
#define W2_FFN_QT_BATCH 0
#endif
#ifndef W2_C256_HIDDEN_TILES
#define W2_C256_HIDDEN_TILES 0
#endif
#ifndef W2_C256_Q_LDS
#define W2_C256_Q_LDS 0
#endif
#if W2_FFN_QT_BATCH != 0 && W2_FFN_QT_BATCH != 2 && W2_FFN_QT_BATCH != 4
#error W2_FFN_QT_BATCH must be 0, 2 or 4
#endif
#if W2_C256_Q_LDS && (!W2_ROLL_QUERY || W2_DEFER_Q)
#error W2_C256_Q_LDS requires W2_ROLL_QUERY=1 and W2_DEFER_Q=0
#endif
'''+anchor)
start=s.index(' _Pragma("clang loop unroll(disable)") for(uint qt=0;qt<4;qt++){',s.index(' // Each head contracts'))
end=s.index('\n w2_sync();',start)
old=s[start:end]
new='''#if W2_FFN_QT_BATCH
 if constexpr(C==256){
 // Same WMMA chains, but one loaded weight fragment feeds B independent token tiles.
 // No reduction is reassociated: expanded keeps kt order; contract keeps ht/tile order.
 constexpr uint B=W2_FFN_QT_BATCH;
 constexpr uint T=W2_C256_HIDDEN_TILES?W2_C256_HIDDEN_TILES:W2_HIDDEN_TILES;
 static_assert(T==1||T==2||T==4||T==8,"C256 hidden tile batch must divide eight");
 _Pragma("clang loop unroll(disable)") for(uint qb=0;qb<4;qb+=B){
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
 {\n'''+old+'\n }'
s=s[:start]+new+s[end:]
old='''    if(part==0){query_words[qt*4+ci*2]=a[0];query_words[qt*4+ci*2+1]=a[1];}else'''
new='''    if(part==0){
#if W2_C256_Q_LDS
     if constexpr(C==256)w2_store<C>(plane1,qt,head*2+ci,a);else
#endif
     {query_words[qt*4+ci*2]=a[0];query_words[qt*4+ci*2+1]=a[1];}
    }else'''
assert s.count(old)==1;s=s.replace(old,new)
old='''  i2 query_frag[2];_Pragma("unroll 2") for(uint ci=0;ci<2;ci++)query_frag[ci]=i2{query_words[qt*4+ci*2],query_words[qt*4+ci*2+1]};'''
new='''  i2 query_frag[2];_Pragma("unroll 2") for(uint ci=0;ci<2;ci++){
#if W2_C256_Q_LDS && !defined(W2_ATTENTION_ONLY)
   // plane1 holds this wave's Q until this qt is consumed, then the same slots hold AV.
   // Every head owns disjoint ct slots; there are no cross-wave Q read/write hazards.
   if constexpr(C==256)query_frag[ci]=w2_load<C>(plane1,qt,head*2+ci);else
#endif
   query_frag[ci]=i2{query_words[qt*4+ci*2],query_words[qt*4+ci*2+1]};
  }'''
assert s.count(old)==1;s=s.replace(old,new)
args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(s)
print(args.output)
