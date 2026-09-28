#!/usr/bin/env python3
"""Generate optional C256 two-wave-per-head body from the current exact body."""
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=None);p.add_argument('--output',type=Path,default=Path('/tmp/c512-fusion/code/c256_wave16.inc'));a=p.parse_args()
s=a.source.read_text() if a.source else subprocess.check_output(['git','show','8c9a61db:hip/wave_owned_mh.inc'],cwd=Path(__file__).resolve().parents[4],text=True);start=s.index('template<uint C,bool ByteIn,bool ByteOut>\nDEV void swin_wave2_body');end=s.index('#define W2_KERNEL',start)
s=s[start:end].replace('swin_wave2_body','swin_wave16_body')
old=' const uint win=__builtin_amdgcn_workgroup_id_x(),head=__builtin_amdgcn_workitem_id_x()/32;'
assert s.count(old)==1
s=s.replace(old,''' static_assert(C==256,"wave16 is C256 only");
 static_assert(W2_ROLL_QUERY && !W2_DEFER_Q,"wave16 requires rolled stored Q");
 static_assert(W2_FFN_QT_BATCH==2,"wave16 retains two-token-tile FFN batching");
 const uint win=__builtin_amdgcn_workgroup_id_x(),tid=__builtin_amdgcn_workitem_id_x(),head=tid/64;
 const uint qt0=((tid/32)&1u)*2u;''')
assert s.count('qt=0;qt<4;qt++')==7,s.count('qt=0;qt<4;qt++')
s=s.replace('qt=0;qt<4;qt++','qt=qt0;qt<qt0+2;qt++')
assert s.count('qb=0;qb<4;qb+=B')==1
s=s.replace('qb=0;qb<4;qb+=B','qb=qt0;qb<qt0+2;qb+=B')
s=s.replace('_Pragma("unroll 4") for(uint qt=qt0;', '_Pragma("unroll 2") for(uint qt=qt0;')
s=s.replace('w2_i16 query_words{};','w16_i8 query_words{};')
s=s.replace('query_words[qt*4+','query_words[(qt-qt0)*4+')
s=s.replace(' i2 qkv[3][4][2];',' i2 qkv[3][4][2];\n i2 own_v[2][2],saved_feature[2][2];')
old='''    qkv[part][qt][ci]=a;'''
assert s.count(old)==1
s=s.replace(old,'''    {if(part==1)w2_store<C>(plane1,qt,head*2+ci,a);else own_v[qt-qt0][ci]=a;}''')
anchor=' // One wave owns all keys and queries of a head. Existing WMMA half row-sum order is retained.'
assert s.count(anchor)==1
s=s.replace(anchor,''' // The FFN feature is needed only for this wave's final residual from here on.
 // Keep its two query tiles in registers, then let all heads retire feature reads.
 _Pragma("unroll 2") for(uint t=0;t<2;t++)for(uint ci=0;ci<2;ci++)saved_feature[t][ci]=w2_load<C>(plane0,qt0+t,head*2+ci);
 w2_sync();
 // Every wave reads all K tiles, while its own V fragments replace dead feature LDS.
 // The barrier also ensures no K reader remains before plane1 becomes AV output.
 _Pragma("unroll 4") for(uint kt=0;kt<4;kt++)for(uint ci=0;ci<2;ci++)qkv[1][kt][ci]=w2_load<C>(plane1,kt,head*2+ci);
 _Pragma("unroll 2") for(uint t=0;t<2;t++)for(uint ci=0;ci<2;ci++)w2_store<C>(plane0,qt0+t,head*2+ci,own_v[t][ci]);
 w2_sync();
 _Pragma("unroll 4") for(uint kt=0;kt<4;kt++)for(uint ci=0;ci<2;ci++)qkv[2][kt][ci]=w2_load<C>(plane0,kt,head*2+ci);
 // Each wave now has all keys/values and its own two query tiles. Original sums follow.''')
old='   a=w2_load<C>(plane0,qt,ct);';assert s.count(old)==2
s=s.replace(old,'   a=saved_feature[qt-qt0][ci];')
s=s.replace(" // All heads' AV ready; feature still lives in plane0. Preserve diagonal residual and K order."," // All heads' AV ready in plane1; residual uses saved_feature. Preserve K order.")
# Ordinary C256 export names and ABI remain untouched; host explicitly selects these exports.
header='''// Optional C256 window organization: 16 waves, two waves per head, two token tiles per wave.
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
'''
footer='''#define W16_KERNEL(NAME,BI,BO) KERNEL __attribute__((amdgpu_flat_work_group_size(512,512))) void NAME(const float*in,const float*fw,const float*aw,void*out,uint w,uint h,uint ww,uint hh,uint sx,uint sy,uint post){swin_wave16_body<256,BI,BO>(in,fw,aw,out,w,h,ww,hh,sx,sy,post);}
W16_KERNEL(c256_wave16,false,false)
W16_KERNEL(c256_wave16_bi,true,false)
W16_KERNEL(c256_wave16_bo,false,true)
W16_KERNEL(c256_wave16_bi_bo,true,true)
#undef W16_KERNEL
#endif
'''
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(header+s+footer);print(a.output)
