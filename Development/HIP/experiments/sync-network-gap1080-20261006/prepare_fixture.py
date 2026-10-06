import argparse,json,hashlib
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
w,vh=1920,1080;y,x=np.indices((vh,w),dtype=np.float32);v=np.stack((x/w,y/vh,np.full_like(x,.5),np.ones_like(x)),axis=-1).astype('<f2').astype('<f4');v.tofile(a.output/'valid.rgba32f');rows={}
for ph in [1152,1088]:
 yy=np.arange(ph);yy=np.where(yy<vh,yy,2*vh-yy-2);v[yy].copy().tofile(a.output/f'processing{ph}.rgba32f');rows[ph]=yy[vh:].tolist()
files={f.name:{'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in a.output.glob('*.rgba32f')};(a.output/'input.json').write_text(json.dumps({'domain':'common already encoded half-exact synthetic gradient','width':w,'valid_height':vh,'processing_heights':[1152,1088],'mirror':'y<1080?y:2158-y','padding_rows':rows,'files':files,'style':1,'seed':0},indent=2))
