exec(open('Development/HIP/experiments/multi-pass-predict/analyze.py').read().split('for folder in sorted(root.iterdir()):')[0])
rows=[]
for folder in sorted(root.iterdir()):
 if not folder.is_dir():continue
 h,w=(960,1600) if folder.name.startswith('900') else (1152,1920)
 x=np.fromfile(folder/'x.f32',np.float32).reshape(h,w,4)[:,:,:3];y1,y2,y3=[np.fromfile(folder/(n+'.f32'),np.float32).reshape(h,w,3) for n in ['y1','y2','y3']];pred=np.fromfile('/tmp/mp-predict-actual/'+folder.name+'.f32',np.float32).reshape(h,w,3)
 hf=lambda z:z-gaussian_filter(z,(2,2,0));dark=x.mean(2)<np.quantile(x.mean(2),1/3)
 for name,a in [('real2',y2),('gpu-predict',pred)]:
  row=dict(case=folder.name,method=name,psnr=psnr(a,y3),hf_psnr=psnr(hf(a),hf(y3)),dark_psnr=psnr(a,y3,dark),color_error=float(np.mean(np.abs((a[:,:,0]-a[:,:,1])-(y3[:,:,0]-y3[:,:,1])))),finite=bool(np.isfinite(a).all()),min=float(a.min()),max=float(a.max()));rows.append(row);print(json.dumps(row))
 energy=uniform_filter(np.sum(hf(y3-y2)**2,2),128);iy,ix=np.unravel_index(np.argmax(energy),energy.shape);iy=int(np.clip(iy-128,0,h-256));ix=int(np.clip(ix-128,0,w-256))
 tiles=[x,y2,pred,y3,np.clip(.5+(pred-y3)*8,0,1)];canvas=Image.new('RGB',(1280,256))
 for i,a in enumerate(tiles):canvas.paste(Image.fromarray(np.round(np.clip(a[iy:iy+256,ix:ix+256],0,1)*255).astype('uint8')),(i*256,0))
 canvas.save(out/f'{folder.name}-gpu-detail.png')
(out/'actual-metrics.json').write_text(json.dumps(rows,indent=2))
