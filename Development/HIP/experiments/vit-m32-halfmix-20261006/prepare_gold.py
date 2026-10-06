from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args();old=(a.root/'old.hip').read_text();new=(a.root/'new.hip').read_text();start=old.index('template<uint MAXT,bool ByteInput=false,bool ByteOut=false>\nDEV void vit_attention_transposed_score_body');end=old.index('\n#endif\n// FAST TIER',start);ref=old[start:end].replace('vit_attention_transposed_score_body','vit_halfmix_ref16_body')
needle='''float af=clampf(a[e]*from_half(0x2dbb)+1.708984375f,1.439453125f,1.9775390625f);
   uint hb=(bits(af)>>13)-0x1c000u;unsigned short u=(unsigned short)(((hb<<4)+0x4000u)&65535u);''';assert ref.count(needle)==1;ref=ref.replace(needle,'unsigned short u=vit_trial_score_half(a[e]);')
ref=ref.replace('f8 sum{},acc[2]{};','trial_h2 dp[4]{};_Float16 den=0;f8 acc[2]{};');needle='''#if HIP_VIT_ATTN_TRANSPOSED_AV
  sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,x,sum);
#else
  sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(x,ones,sum);
#endif''';assert ref.count(needle)==1;ref=ref.replace(needle,'trial_den_step(x,dp,den,key,tokens);');ref=ref.replace('vit_inv(sum[0])','vit_inv(float(den))').replace('vit_inv(sum[e])','vit_inv(float(den))')
s=new+'\n'+ref+'\nWAVE void vit_halfmix_reference_640(const float*in,float*out,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;vit_halfmix_ref16_body<640,true,true>(in,out,tokens);}\n';(a.root/'gold.hip').write_text(s)
