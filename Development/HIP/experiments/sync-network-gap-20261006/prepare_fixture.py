"""Half-exact encoded-domain gradient, shared valid pixels and original bottom mirror."""
import argparse,json,hashlib
from pathlib import Path
import numpy as np
ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);a=ap.parse_args();a.output.mkdir(parents=True,exist_ok=True)
w,vh,ph=1600,900,960
y,x=np.indices((vh,w),dtype=np.float32)
v=np.stack((x/w,y/vh,np.full_like(x,.5),np.ones_like(x)),axis=-1).astype('<f2').astype('<f4')
rows=np.arange(ph);rows=np.where(rows<vh,rows,2*vh-rows-2);p=v[rows].copy()
for name,array in [('valid.rgba32f',v),('processing.rgba32f',p)]:array.tofile(a.output/name)
meta={'domain':'already encoded internal RGB input; synthetic gradient, not a real scene/HDR capture','width':w,'valid_height':vh,'processing_height':ph,'half_exact':True,'bottom_mirror':'y<900?y:1798-y','padding_rows':rows[vh:].tolist(),'seed':0,'style':1,'files':{name:{'sha256':hashlib.sha256((a.output/name).read_bytes()).hexdigest(),'bytes':(a.output/name).stat().st_size} for name in ['valid.rgba32f','processing.rgba32f']}}
(a.output/'input.json').write_text(json.dumps(meta,indent=2))
