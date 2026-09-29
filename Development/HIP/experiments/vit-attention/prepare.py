#!/usr/bin/env python3
import argparse,importlib.util,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];h=Path(__file__).resolve().parent
sp=importlib.util.spec_from_file_location('recipes',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
recipe=list(next(x for x in m.recipe(r/'hip') if x[0]=='deep_fast-packed'));recipe[2]=[x for x in recipe[2] if not x.startswith(('HIP_VIT_ATTN_NATIVE_HALF','HIP_VIT_ATTN_PROB_PAIR','HIP_VIT_ATTN_TRANSPOSED_AV'))]
print(recipe[0],recipe[2])
s='\n'.join('#define '+x for x in recipe[2])+'\n'+subprocess.check_output(['git','show','629b0555:hip/deep_fast.hip'],cwd=r,text=True)+'\n'+(h/'probe.inc').read_text()
(a.out/'probe.hip').write_text(s)

core=subprocess.check_output(['git','show','629b0555:hip/deep_fast.hip'],cwd=r,text=True)
start=core.index('template<uint MAXT,bool ByteInput=false,bool ByteOut=false>\nDEV void vit_attention_transposed_score_body')
end=core.index('\n#endif',start)
body=core[start:end].replace('vit_attention_transposed_score_body','vit_attention_native_body').replace('pack(xb,e,from_half(u));','pack(xb,e,float(cv.h));')
s+='\n'+body+'\nWAVE void vit_probe_native(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_attention_native_body<640,true,true>(in,out,tokens); }\n'
(a.out/'probe.hip').write_text(s)
# Diagnostic only: requires the fixture's V plane to consist of FP8 +1 bytes.
# Same arithmetic for that restricted input; never a production candidate.
vbody=body.replace('vit_attention_native_body','vit_attention_constv_body')
old='uint b=in8[(2*tokens+vkey)*1024+head*32+c*16+rc()];'
assert vbody.count(old)==1
vbody=vbody.replace(old,'uint b=0x38u;')
s+='\n'+vbody+'\nWAVE void vit_probe_native_constv(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_attention_constv_body<640,true,true>(in,out,tokens);}\n'
(a.out/'probe.hip').write_text(s)
# Probability values are positive normals below 2, so pack()'s +/-448 clamp
# and zero/NaN cases are irrelevant; encode two lanes per FP8 instruction.
pbody=body.replace('vit_attention_native_body','vit_attention_pair_body')
pbody=pbody.replace('h8 x{};i2 xb{};','h8 x{};i2 xb{};f8 prob{};').replace('pack(xb,e,float(cv.h));','prob[e]=float(cv.h);')
pbody=pbody.replace('  sum=__builtin_amdgcn_wmma', '''  xb[0]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[0],prob[1],0,false);
  xb[0]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[2],prob[3],xb[0],true);
  xb[1]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[4],prob[5],0,false);
  xb[1]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[6],prob[7],xb[1],true);
  sum=__builtin_amdgcn_wmma''')
s+='\n'+pbody+'\nWAVE void vit_probe_pair(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_attention_pair_body<640,true,true>(in,out,tokens);}\n'
(a.out/'probe.hip').write_text(s)
tbody=body.replace('vit_attention_native_body','vit_attention_transposed_av_body')
old='sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(x,ones,sum);'
assert tbody.count(old)==1;tbody=tbody.replace(old,old.replace('(x,ones,sum)','(ones,x,sum)'))
old='acc[c]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(xb,y,acc[c]);'
assert tbody.count(old)==1;tbody=tbody.replace(old,old.replace('(xb,y,acc[c])','(y,xb,acc[c])'))
old='float inv[8];for(uint e=0;e<8;e++)inv[e]=1.f/sum[e];'
assert tbody.count(old)==1;tbody=tbody.replace(old,'float inv=1.f/sum[0];')
tbody=tbody.replace('(first+gr()*8+e)*1024+head*32+c*16+rc()','(first+rc())*1024+head*32+c*16+gr()*8+e').replace('acc[c][e]*inv[e]','acc[c][e]*inv')
s+='\n'+tbody+'\nWAVE void vit_probe_transpose(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_attention_transposed_av_body<640,true,true>(in,out,tokens);}\n'
(a.out/'probe.hip').write_text(s)
tpbody=tbody.replace('vit_attention_transposed_av_body','vit_attention_pair_transposed_av_body')
tpbody=tpbody.replace('h8 x{};i2 xb{};','h8 x{};i2 xb{};f8 prob{};').replace('pack(xb,e,float(cv.h));','prob[e]=float(cv.h);')
tpbody=tpbody.replace('  sum=__builtin_amdgcn_wmma', '''  xb[0]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[0],prob[1],0,false);
  xb[0]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[2],prob[3],xb[0],true);
  xb[1]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[4],prob[5],0,false);
  xb[1]=__builtin_amdgcn_cvt_pk_fp8_f32(prob[6],prob[7],xb[1],true);
  sum=__builtin_amdgcn_wmma''')
s+='\n'+tpbody+'\nWAVE void vit_probe_pair_transpose(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_attention_pair_transposed_av_body<640,true,true>(in,out,tokens);}\n'
(a.out/'probe.hip').write_text(s)
