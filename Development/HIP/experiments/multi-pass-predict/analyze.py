import json,hashlib
from pathlib import Path
import numpy as np
from scipy.ndimage import uniform_filter,gaussian_filter
from PIL import Image
root=Path('/tmp/mp-predict-raw/raw');out=Path('/tmp/mp-predict-analysis');out.mkdir(exist_ok=True)
rows=[]
def psnr(a,b,mask=None):
 e=(a-b)**2
 if mask is not None:e=e[mask]
 return float(-10*np.log10(max(float(e.mean()),1e-30)))
for folder in sorted(root.iterdir()):
 if not folder.is_dir():continue
 h,w=(960,1600) if folder.name.startswith('900') else (1152,1920)
 x=np.fromfile(folder/'x.f32',np.float32).reshape(h,w,4)[:,:,:3];y1,y2,y3=[np.fromfile(folder/(n+'.f32'),np.float32).reshape(h,w,3) for n in ['y1','y2','y3']]
 assert all(np.isfinite(a).all() for a in [x,y1,y2,y3])
 d1=y1-x;d2=y2-y1;d3=y3-y2
 aa=np.sum(d1*d1,axis=2);bb=np.sum(d2*d2,axis=2);ab=np.sum(d1*d2,axis=2)
 lum=x.mean(2);dark=lum<np.quantile(lum,1/3);hf=lambda z:z-gaussian_filter(z,(2,2,0))
 globalr=float(ab.sum()/max(aa.sum(),1e-12));oracle=float(np.sum(d2*d3)/max(np.sum(d2*d2),1e-12))
 cands={'y2':y2,'global-secant':np.clip(y2+np.clip(globalr,0,1)*d2,0,1),'global-oracle-second':np.clip(y2+oracle*d2,0,1)}
 rs={}
 for patch in [8,16,32]:
  a=uniform_filter(aa,patch,mode='reflect');b=uniform_filter(bb,patch,mode='reflect');cross=uniform_filter(ab,patch,mode='reflect')
  cos=cross/np.sqrt(np.maximum(a*b,1e-20));r=np.clip(cross/(a+1e-7),0,1);r=np.where((cos>=.5)&(a>=1e-7),r,0)
  cands[f'local{patch}']=np.clip(y2+r[:,:,None]*d2,0,1);rs[patch]=r
 for name,pred in cands.items():
  row={'case':folder.name,'method':name,'psnr':psnr(pred,y3),'hf_psnr':psnr(hf(pred),hf(y3)),'dark_psnr':psnr(pred,y3,dark),'color_error':float(np.mean(np.abs((pred[:,:,0]-pred[:,:,1])-(y3[:,:,0]-y3[:,:,1])))),'finite':bool(np.isfinite(pred).all()),'global_r':globalr,'oracle_r':oracle}
  rows.append(row);print(json.dumps(row))
 # largest high-frequency true-third change crop, plus a dark crop
 energy=uniform_filter(np.sum(hf(d3)**2,2),128);iy,ix=np.unravel_index(np.argmax(energy),energy.shape);iy=int(np.clip(iy-128,0,h-256));ix=int(np.clip(ix-128,0,w-256))
 for tag,sy,sx in [('detail',iy,ix),('dark',max(0,h//2-128),max(0,w//2-128))]:
  tiles=[x,y2,cands['local16'],y3,np.clip(.5+(cands['local16']-y3)*8,0,1)]
  ims=[Image.fromarray(np.round(np.clip(a[sy:sy+256,sx:sx+256],0,1)*255).astype('uint8')) for a in tiles]
  canvas=Image.new('RGB',(1280,256));[canvas.paste(im,(i*256,0)) for i,im in enumerate(ims)];canvas.save(out/f'{folder.name}-{tag}.png')
 hashes={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in folder.glob('*.f32')};(out/f'{folder.name}-hashes.json').write_text(json.dumps(hashes,indent=2))
(out/'metrics.json').write_text(json.dumps(rows,indent=2))
