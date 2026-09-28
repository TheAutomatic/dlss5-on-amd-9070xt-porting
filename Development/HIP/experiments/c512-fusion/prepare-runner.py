#!/usr/bin/env python3
"""Snapshot 8c9a61db and add default-off C512 fused QKV/attention host route."""
from pathlib import Path
import argparse,subprocess,difflib,json
ap=argparse.ArgumentParser();ap.add_argument('out',type=Path);ap.add_argument('--repo',type=Path,default=Path(__file__).resolve().parents[4]);a=ap.parse_args()
root=a.repo.resolve();out=a.out.resolve();revision='8c9a61db'
def git(*args):return subprocess.check_output(['git',*args],cwd=root)
names=git('ls-tree','-r','--name-only',revision,'src','Development/HIP').decode().splitlines()
for name in names:
 if not(name.startswith('src/') or (name.startswith('Development/HIP/') and name.count('/')==2 and (name.endswith('.h') or name.endswith('/benchmark_vit_reuse.cpp')))):continue
 p=out/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(git('show',revision+':'+name))
p=out/'Development/HIP/hip_reference_network.h';original=p.read_text();s=original
def replace(old,new):
 global s
 assert s.count(old)==1,(old[:100],s.count(old));s=s.replace(old,new)
s='''#ifndef C512_QKV_ATTN_EXPERIMENT
#define C512_QKV_ATTN_EXPERIMENT 0
#endif
#ifndef C512_FUSED_WAVES
#define C512_FUSED_WAVES 2
#endif
'''+s
replace('  if(module=="c512_m32_mh"||module=="c512_m32_deep"){groups=count/1024;threads=32;}', '''  if(module=="c512_m32_mh"||module=="c512_m32_deep"){groups=count/1024;threads=32;}
#if C512_QKV_ATTN_EXPERIMENT
  if(module=="c512_m32_mh"&&kernel=="c512_qkv_attention_fused"){groups=count;threads=32*C512_FUSED_WAVES;}
#endif''')
replace('Tensor ready_norm={},bool feature_byte=false,bool out_byte=false){','''Tensor ready_norm={},bool feature_byte=false,bool out_byte=false
#if C512_QKV_ATTN_EXPERIMENT
 ,Tensor ready_av={}
#endif
 ){
#if C512_QKV_ATTN_EXPERIMENT
  if(ready_av){
   const U n=w*h;
   if(c!=512||!opt.fp8_av||!opt.packed_weights||ready_av->bytes<size_t(n)*512||feature_byte||out_byte)
    throw std::runtime_error("C512 fused AV contract");
   auto out=New((cropw?size_t(cropw)*croph:size_t(n))*512);
   if(cropw){
    if(opt.c512_proj_frag)Run("mh_fast","mh_attention_project_frag_c512",size_t(n)*512,P(ready_av),P(input),PackedMhWeightQkvFrag(aw,512),P(out),n,U(raw?3:0),cropw,croph,w,sx,sy);
    else Run("mh_fast","mh_attention_crop",size_t(n)*512,P(ready_av),P(input),PackedMhWeight(aw,512,true),P(out),n,U(raw?3:0),cropw,croph,w,sx,sy,U(512));
   }else Run("mh_fast","mh_attention_project_fast_scalar_fp8",size_t(n)*512,P(ready_av),P(input),PackedMhWeight(aw,512,true),P(out),n,U(512),U(raw?3:0));
   return out;
  }
#endif''')
replace(' if(c==512){auto mixed=', '''
#if C512_QKV_ATTN_EXPERIMENT
 Tensor fused_c512_av;
#endif
 if(c==512){auto mixed=''')
old='producer_norm=New(size_t(n)*384);if(c512_m32_active)Run("c512_m32_mh","mh_qkv_normalize_frag_c512_m32",size_t((n+31)/32*32)*768,P(ffn8),PackedMhWeightQkvFrag(Block(block,"attention"),512),P(producer_norm),n);else Run("mh_fast","mh_qkv_normalize_frag_c512",size_t(n)*1536,P(ffn8),PackedMhWeightQkvFrag(Block(block,"attention"),512),P(producer_norm),n);'
replace(old,'''\n#if C512_QKV_ATTN_EXPERIMENT
 if(!c512_m32_active||!opt.fp8_av||!opt.fused_mh||!opt.fp8_normalized||ww%8||hh%8)
  throw std::runtime_error("C512 fused experiment requires production M32/FP8/window geometry");
 fused_c512_av=New(size_t(n)*128);
 Run("c512_m32_mh","c512_qkv_attention_fused",size_t(n/64)*16,P(ffn8),PackedMhWeightQkvFrag(Block(block,"attention"),512),P(fused_c512_av),ww,hh);
#else
 '''+old+'''\n#endif
''')
replace('auto attended=(crop||producer_norm)?AttentionFast', '''auto attended=(crop||producer_norm
#if C512_QKV_ATTN_EXPERIMENT
 ||fused_c512_av
#endif
 )?AttentionFast''')
replace('sx,sy,producer_norm,byte_feature,byte_out):Attention(ffn', '''sx,sy,producer_norm,byte_feature,byte_out
#if C512_QKV_ATTN_EXPERIMENT
 ,fused_c512_av
#endif
 ):Attention(ffn''')
# No runtime flags, resident-buffer changes or C256-route edits.
p.write_text(s)
patch=''.join(difflib.unified_diff(original.splitlines(True),s.splitlines(True),fromfile='a/Development/HIP/hip_reference_network.h',tofile='b/Development/HIP/hip_reference_network.h'))
(out/'header.patch').write_text(patch)
(out/'snapshot.json').write_text(json.dumps({'revision':revision,'host_macro':'C512_QKV_ATTN_EXPERIMENT=1','kernel_macro':'C512_FUSED_QKV_ATTN=1','threads_macro':'C512_FUSED_WAVES=2 (must match kernel)','module':'c512-m32-mh.hsaco','export':'c512_qkv_attention_fused','geometry':'grid=(workw/8)*(workh/8)*16, threads=64','unchanged':'C2561080 route; MAKE_RESIDENT_EVERY; runtime flags'},indent=2))
print(out)
