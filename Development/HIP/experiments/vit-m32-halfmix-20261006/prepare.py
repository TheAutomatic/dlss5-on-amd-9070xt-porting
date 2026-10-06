"""Unique QB32 K/V-sharing x locked halfscore/64-key halfden combination."""
from pathlib import Path
import argparse,importlib.util,subprocess,json,hashlib
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);row=next(x for x in m.recipe(r/'hip')if x[0]=='deep_fast-packed-fast');stock=row[2]
historical=subprocess.check_output(['git','show','vit-1080-gap:hip/deep_fast.hip'],cwd=r,text=True);start=historical.index('DEV void vit_attn_m32_prob');end=historical.index('\n#endif',start);body=historical[start:end]
old='''float af=clampf(a[e]*from_half(0x2dbb)+1.708984375f,1.439453125f,1.9775390625f);
  uint hb=(bits(af)>>13)-0x1c000u;unsigned short u=(unsigned short)(((hb<<4)+0x4000u)&65535u);'''
assert body.count(old)==1;body=body.replace(old,'unsigned short u=vit_trial_score_half(a[e]);')
body=body.replace('vit_attn_m32_prob','vit_m32_halfmix_prob').replace('vit_attention_m32_body','vit_attention_m32_halfmix_body')
body=body.replace(' h8 ones{};for(uint e=0;e<8;e++)ones[e]=(_Float16)1.f;\n f8 sum0{},sum1{},acc0[2]{},acc1[2]{};',' trial_h2 partial0[4]{},partial1[4]{};_Float16 den0=0,den1=0;\n f8 acc0[2]{},acc1[2]{};')
old='  sum0=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,x0,sum0);sum1=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,x1,sum1);';assert body.count(old)==1;body=body.replace(old,'  trial_den_step(x0,partial0,den0,key,tokens);trial_den_step(x1,partial1,den1,key,tokens);')
body=body.replace('vit_inv(sum0[0])','vit_inv(float(den0))').replace('vit_inv(sum1[0])','vit_inv(float(den1))')
# Preserve CURRENT FAST1 exit math; historical Hrtz predates the current twin.
body=body.replace('byte_F(Hrtz(','byte_F(vit_attn_hrtz(')
helpers=(r/'Development/HIP/experiments/vit-score-halfclamp-20261006/score_half.inc').read_text()+'\n'+(r/'Development/HIP/experiments/vit-math-stair-20261006/den_half.inc').read_text()
anchor='WAVE void vit_attention_fused_640_bytein_bout(';pos=stock.index(anchor);new=stock[:pos]+helpers+'\n'+body+'\n'+stock[pos:];a0=new.index(anchor);b0=new.index('\n}',a0);wrapper=new[a0:b0];old='vit_attention_transposed_score_body<640,true,true>(in,out,tokens);';assert wrapper.count(old)==1;new=new[:a0]+wrapper.replace(old,'vit_attention_m32_halfmix_body<640>(in,out,tokens);')+new[b0:]
(a.output/'old.hip').write_text(stock);(a.output/'new.hip').write_text(new)
(a.output/'source.json').write_text(json.dumps({'scope':'only640wrapper QB32shareKV plusB2scorehalfFMA/lockedC64keyhalfden; QK/AVf32,currentFAST1exit unchanged, originalKV AoS scalarloads/gridkeep; noTR/producer/exit-half extra','compiler':row[1]or'COMGR','opts':row[-1],'historical_source_commit':subprocess.check_output(['git','rev-parse','vit-1080-gap'],cwd=r,text=True).strip(),'historical_M32_moduleSHA':'f3e32bed16091d66f84db7ef29165173205a61f6efe73708bf231d8c7698a2c2','old_sourceSHA':hashlib.sha256(stock.encode()).hexdigest(),'new_sourceSHA':hashlib.sha256(new.encode()).hexdigest(),'numeric_loss_experiment_NOT_production':True},indent=2)+'\n')
