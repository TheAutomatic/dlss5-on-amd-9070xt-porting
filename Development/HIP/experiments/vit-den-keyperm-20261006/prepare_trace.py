"""Isolated one-wave 16-query trace; never timing or production module."""
import argparse
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('out',type=Path);p.add_argument('--permuted',action='store_true');a=p.parse_args();s=a.source.read_text()
start=s.index('template<uint MAXT,bool ByteInput=false,bool ByteOut=false>\nDEV void vit_attention_transposed_score_body');end=s.index('\n#endif\n// FAST TIER',start);b=s[start:end]
b=b.replace('vit_attention_transposed_score_body','vit_keyperm_trace_body',1).replace('uint tokens){','uint tokens,float*trace){',1)
key='((gr()*8u+e)&3u)|(((gr()*8u+e)&4u)<<1u)|(((gr()*8u+e)&8u)>>1u)' if a.permuted else 'gr()*8u+e'
b=b.replace('unsigned short u=vit_trial_score_half(a[e]);',f'trace[rc()*tokens+key+({key})]=a[e];\n   unsigned short u=vit_trial_score_half(a[e]);',1)
pos=b.index('  for(uint c=0;c<2;c++){i2 y{};for(uint e=0;e<8;e++){uint vkey=')
b=b[:pos]+'''  for(uint e=0;e<8;e++)reinterpret_cast<uint*>(trace+16*tokens)[rc()*tokens+key+gr()*8u+e]=(uint(xb[e/4])>>(8*(e%4)))&255u;
  if((key+16)%64==0)trace[32*tokens+(__builtin_amdgcn_workitem_id_x()&31u)*10+key/64]=float(den_half);
'''+b[pos:]
b=b.replace('float inv=vit_inv(float(den_half));','for(uint c=0;c<2;c++)for(uint e=0;e<8;e++)trace[32*tokens+320+rc()*32+c*16+gr()*8+e]=acc[c][e];\n float inv=vit_inv(float(den_half));',1)
s=s[:end]+'\n'+b+'\nextern "C" __attribute__((global)) __attribute__((amdgpu_flat_work_group_size(32,32))) void keyperm_trace(const float*in,float*out,float*trace){vit_keyperm_trace_body<640,true,true>(in,out,640,trace);}\n'+s[end:]
a.out.write_text(s)
