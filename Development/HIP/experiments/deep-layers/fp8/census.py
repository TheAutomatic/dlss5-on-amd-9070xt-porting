#!/usr/bin/env python3
import numpy as np,json,hashlib,argparse
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,default=Path('release/native-rgb-valid1080/amd-full'));args=parser.parse_args();root=args.root
lut=[]
for b in range(256):
 e=(b>>3)&15;m=b&7
 if e==15 and m==7:continue
 x=m/512 if e==0 else (1+m/8)*2.**(e-7)
 lut.append(np.float32(-x if b&128 else x))
fp8bits=np.array(lut,dtype=np.float32).view(np.uint32)
report={'sources':[],'weight_elements':0,'bad_after_half':0,'scope':'finite E4M3 representability only; does not prove FP16/FP8 WMMA equivalence','old_arithmetic_counterexample':'Development/history/DevHistory-full-20260923.md:1738-1750; block46 pattern2; only FP8 expansion reproduces 10 float-bit differences'}
for block in list(range(23,31))+list(range(40,48)):
 p=root/f'block{block}-ffwd.f32';raw=np.fromfile(p,dtype='<f4');assert len(raw)==524288,(p,len(raw))
 row={'block':block,'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'parts':{}}
 for name,a,b in [('mix',0,262144),('expand',262144,393216),('contract',393216,524288)]:
  src=raw[a:b];h=src.astype(np.float16).astype(np.float32)
  bad=~np.isin(h.view(np.uint32),fp8bits);badraw=~np.isin(src.view(np.uint32),fp8bits)
  part={'count':len(src),'finite':bool(np.isfinite(src).all()),'fp8_exact_raw':int((~badraw).sum()),'fp8_exact_after_half':int((~bad).sum()),'half_changed_bits':int((src.view(np.uint32)!=h.view(np.uint32)).sum()),'min':float(src.min()),'max':float(src.max()),'bad_examples':[{'index':int(i+a),'float':float(src[i]),'half':float(h[i])} for i in np.flatnonzero(bad)[:8]]}
  row['parts'][name]=part;report['weight_elements']+=len(src);report['bad_after_half']+=int(bad.sum())
 report['sources'].append(row)
p=Path(__file__).resolve().parent/'weight-census-all16.json';p.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'blocks':len(report['sources']),'elements':report['weight_elements'],'bad_after_half':report['bad_after_half'],'half_changed':sum(y['half_changed_bits'] for x in report['sources'] for y in x['parts'].values())}))
