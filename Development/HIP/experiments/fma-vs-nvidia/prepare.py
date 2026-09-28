#!/usr/bin/env python3
"""Isolated activation candidates; never edit the production recipe/source."""
from pathlib import Path
import shutil,sys,hashlib,json
repo=Path(__file__).resolve().parents[4]
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
manifest={}
for mode in ('Z','F','H'):
 dst=out/('hip-'+mode);shutil.copytree(repo/'hip',dst,dirs_exist_ok=True)
 helper='''
DEV float audit_h(float x){unsigned v;asm("v_cvt_f16_f32 %0, %1" : "=v"(v):"v"(x));return float(__builtin_bit_cast(_Float16,(unsigned short)v));}
DEV float audit_hfma(float a,float b,float c){unsigned v;asm("v_fma_mixlo_f16 %0, %1, %2, %3 op_sel_hi:[0,0,0]" : "=v"(v):"v"(a),"v"(b),"v"(c));return float(__builtin_bit_cast(_Float16,(unsigned short)v));}
DEV float audit_act(float x){float a=audit_h(x),g=clampf(a,-4.f,4.f);float q=audit_hfma(absf(g),-.055908203125f,.447265625f),p=audit_hfma(g,q,.89453125f);return audit_h(a*p);}
'''
 for name,var in [('wave_owned_c32.inc','v'),('wave_owned_mh.inc','a')]:
  p=dst/name;s=p.read_text()
  old='q=absf(g)*(-.055908203125f)+.447265625f,'+('p' if var=='v' else 'poly')+'=g*q+.89453125f'
  assert s.count(old)==1
  if mode=='F':s=s.replace(old,'q=__builtin_fmaf(absf(g),-.055908203125f,.447265625f),'+('p' if var=='v' else 'poly')+'=__builtin_fmaf(g,q,.89453125f)')
  if mode=='H':
   s=helper+s
   if var=='v':s=s.replace('CW_Q8_SET(a,e,v*p)','CW_Q8_SET(a,e,audit_act(v))')
   else:s=s.replace('W2_Q8_SETF(hidden,e,a,poly)','W2_Q8_SET(hidden,e,audit_act(a)+0.f)')
  p.write_text(s)
  manifest[f'{mode}/{name}']=hashlib.sha256(s.encode()).hexdigest()
(out/'source-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
