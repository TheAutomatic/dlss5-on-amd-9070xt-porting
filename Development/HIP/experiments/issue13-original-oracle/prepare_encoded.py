#!/usr/bin/env python3
"""Validate issue13 inputs and prepare original-CUDA working surfaces; no GPU."""
import argparse,hashlib,json
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('--package',type=Path,default=Path('/tmp/issue13-yimo/unpacked'));p.add_argument('--output',type=Path,default=Path('/tmp/issue13-original-tools/encoded'));a=p.parse_args()
m=json.loads((a.package/'manifest.json').read_text());a.output.mkdir(parents=True,exist_ok=True)
reports=[]
for item in m['inputs']:
 source=a.package/'inputs'/item['file'];raw=source.read_bytes()
 assert len(raw)==item['bytes'] and hashlib.sha256(raw).hexdigest()==item['sha256']
 x=np.frombuffer(raw,dtype='<f2').reshape(1080,1920,4)
 assert np.isfinite(x).all()
 y=np.empty((1152,1920,4),dtype='<f2');y[:1080]=x;y[1080:]=x[2158-np.arange(1080,1152)]
 assert np.array_equal(y[1080],x[1078]) and np.array_equal(y[1151],x[1007])
 stem=str(item['frame']);f16=a.output/(stem+'.padded.rgba16f');f32=a.output/(stem+'.padded.rgba32f')
 y.tofile(f16);y.astype('<f4').tofile(f32)
 reports.append({'source':str(source),'source_sha256':item['sha256'],'padded_f16':str(f16),'padded_f16_sha256':hashlib.sha256(f16.read_bytes()).hexdigest(),'padded_f32':str(f32),'padded_f32_sha256':hashlib.sha256(f32.read_bytes()).hexdigest()})
(a.output/'provenance.json').write_text(json.dumps({'scope':'input preparation only, not GPU/oracle output','encoding':'unchanged encoded half, then exact half-to-float conversion','padding':'source_y=2158-y','seed':1,'style':1,'post_shift':3,'history':False,'frames':reports},indent=2)+'\n')
print(json.dumps(reports,indent=2))
