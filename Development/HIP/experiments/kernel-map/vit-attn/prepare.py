from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('source',help='pristine b99e9ef6 hip/deep_fast.hip');p.add_argument('--out',default='/tmp/kernel-map/vit-attn');a=p.parse_args();out=Path(a.out);out.mkdir(exist_ok=True)
s=Path(a.source).read_text();start=s.index('template<uint MAXT,bool ByteInput=false,bool ByteOut=false>');end=s.index('// Byte-stream twins:',start);body=s[start:end].replace('vit_attention_fused_body','vit_attention_transposed_score_body').replace(' __attribute__((shared)) unsigned short t16[2*16*24];','')
old='__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(q[k/16],y,a)';assert old in body;body=body.replace(old,'__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(y,q[k/16],a)')
begin=body.index('  unsigned short*t=t16+tile*16*24;');finish=body.index('  sum=__builtin_amdgcn_wmma',begin)
body=body[:begin]+'''  // Swapping Q/K operands transposes the score output, directly matching
  // the A-fragment consumed by denominator and PV. Same K0 then K16 order.
  h8 x{};i2 xb{};
  for(uint e=0;e<8;e++){
   float af=clampf(a[e]*from_half(0x2dbb)+1.708984375f,1.439453125f,1.9775390625f);
   uint hb=(bits(af)>>13)-0x1c000u;unsigned short u=(unsigned short)(((hb<<4)+0x4000u)&65535u);
   union{unsigned short u;_Float16 h;}cv;cv.u=u;x[e]=cv.h;pack(xb,e,from_half(u));
  }
''' +body[finish:]
body=body.replace(' WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);','')
inc='''#ifndef HIP_VIT_ATTN_TRANSPOSED_SCORE
#define HIP_VIT_ATTN_TRANSPOSED_SCORE 0
#endif
#if HIP_VIT_ATTN_TRANSPOSED_SCORE
'''+body+'#endif\n'
(out/'vit_attn_transposed_score.inc').write_text(inc)
patched=s[:start]+inc+s[start:]
for cap in [400,640]:
 old=f'vit_attention_fused_body<{cap},true,true>(in,out,tokens);'
 new=f'''\n#if HIP_VIT_ATTN_TRANSPOSED_SCORE
vit_attention_transposed_score_body<{cap},true,true>(in,out,tokens);
#else
{old}
#endif
'''
 assert patched.count(old)==1;patched=patched.replace(old,new)
(out/'deep_fast.hip').write_text(patched)
import difflib
(out/'kernel.patch').write_text(''.join(difflib.unified_diff(s.splitlines(True),patched.splitlines(True),fromfile='a/hip/deep_fast.hip',tofile='b/hip/deep_fast.hip')))
# Retire the incorrect draft, do not leave two candidates with ambiguous names.
bad=out/'vit_attn_wave_transpose.inc'
if bad.exists():bad.unlink()
print(out/'kernel.patch')
