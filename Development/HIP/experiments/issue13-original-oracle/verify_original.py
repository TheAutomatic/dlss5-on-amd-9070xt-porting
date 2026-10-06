from pathlib import Path
import numpy as np,json,hashlib
root=Path(__file__).resolve().parent;m=json.loads((root/'manifest.json').read_text())
for name,info in m['files'].items():
 h=hashlib.sha256()
 with (root/name).open('rb') as f:
  while data:=f.read(4194304):h.update(data)
 assert h.hexdigest()==info['sha256'],name
print('all captured file hashes verified')
def linear(v):
 v=np.clip(v,0,1);return np.where(v<=.04045,v/12.92,((v+.055)/1.055)**2.4)
w=np.array([.212639,.715169,.072192],dtype='f4');xs=[];ys=[]
for f in ['8678','8680']:
 xs.append(linear(np.fromfile(root/(f+'.input-capture.rgba32'),'<f4').reshape(1080,1920,4)[:,:,:3]))
 ys.append(linear(np.fromfile(root/(f+'.original-post.rgb32'),'<f4').reshape(1080,1920,3))@w)
x,y=xs;u,v=ys;stable=np.max(abs(y-x)/(.003+.03*abs(x)),2)<1
blocks=lambda z:z[:1056].reshape(33,32,60,32).mean((1,3))
valid=(blocks(stable)>.90)&(blocks(x@w)>.02);delta=v-u-(y@w-x@w)
print(json.dumps(dict(stable_pixels=int(stable.sum()),stable_blocks=int(valid.sum()),p95_percent=float(np.percentile((abs(100*blocks(delta)/np.maximum(blocks(u),.02)))[valid],95)),stable_pixel_mae=float(abs(delta[stable]).mean())),indent=2))
