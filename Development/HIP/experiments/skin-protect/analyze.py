import numpy as np,json,hashlib
from pathlib import Path
from scipy.ndimage import uniform_filter
from PIL import Image
root=Path('/tmp/skin-actual/raw');dest=Path('/tmp/skin-analysis');dest.mkdir(exist_ok=True);stats=[]
def ease(lo,hi,v):t=np.clip((v-lo)/(hi-lo),0,1);return t*t*(3-2*t)
for case in ['900-static','1080-motion','1080-history']:
 h,w=(960,1600) if case.startswith('900') else (1152,1920)
 for mode in ['skin','predict-skin']:
  d=root/(case+'-'+mode)
  if not (d/'final.f32').exists():continue
  x=np.fromfile(d/'x.f32',np.float32).reshape(h,w,4)[:,:,:3];first=np.fromfile(d/'y1.f32',np.float32).reshape(h,w,3);out=np.fromfile(d/'final.f32',np.float32).reshape(h,w,3);mask=np.fromfile(d/'mask.f32',np.float32).reshape(h,w)
  y=.299*x[:,:,0]+.587*x[:,:,1]+.114*x[:,:,2];cb=.564*(x[:,:,2]-y)+.5;cr=.713*(x[:,:,0]-y)+.5;distance=np.sqrt(((cb-.405)/.09)**2+((cr-.6)/.11)**2);base=(1-ease(.95,1.45,distance))*ease(.02,.06,np.ptp(x,2));cpu=np.maximum(base,uniform_filter(base,3,mode='nearest'))
  core=mask>=1;zero=mask<=0;assert np.isfinite(out).all() and np.array_equal(out[core],first[core]);row=dict(case=case,mode=mode,core=int(core.sum()),zero=int(zero.sum()),cpu_gpu_mask_maxabs=float(np.max(np.abs(mask-cpu))),core_exact=True)
  if mode=='skin' and case!='1080-history':
   many=np.fromfile(root/(case+'-three')/'final.f32',np.float32).reshape(h,w,3);assert np.array_equal(out[zero],many[zero]);row['non_skin_exact']=True
  roi=(slice(int(h*.1),int(h*.3)),slice(int(w*.60),int(w*.72)))
  row['face_luma_one']=float(first[roi].mean());row['face_luma_protected']=float(out[roi].mean());stats.append(row);print(json.dumps(row))
  if mode=='skin':
   many=np.fromfile(root/(case+'-three')/'final.f32',np.float32).reshape(h,w,3);tiles=[first,many,out,np.repeat(mask[:,:,None],3,2)];cut=[Image.fromarray(np.uint8(np.clip(v[roi],0,1)*255)).resize((288,384)) for v in tiles];pic=Image.new('RGB',(1152,384));[pic.paste(v,(i*288,0)) for i,v in enumerate(cut)];pic.save(dest/(case+'-face.png'))
   # true decoded comparison: same 1296x720 surface, gamma preview only
   frames=[np.fromfile(root/(case+'-'+m)/'rgb-frame-11.f16',np.float16).reshape(720,1296,4)[:,:,:3].astype(np.float32) for m in ['one','three','skin']]
   roi2=(slice(72,216),slice(777,933));pic=Image.new('RGB',(864,384))
   for i,v in enumerate(frames):pic.paste(Image.fromarray(np.uint8(np.clip(v[roi2],0,1)**(1/2.2)*255)).resize((288,384)),(i*288,0))
   pic.save(dest/(case+'-decoded-face.png'))
  hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in d.glob('*.f32')};(dest/(case+'-'+mode+'-hashes.json')).write_text(json.dumps(hashes,indent=2))
(dest/'stats.json').write_text(json.dumps(stats,indent=2))
