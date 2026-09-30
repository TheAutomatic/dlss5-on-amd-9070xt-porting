# Same metric as mochizuki ngx-verification: 8-bit RGB, MSE over all pixels and channels, peak 255; SSIM = mean over R,G,B, 11x11 Gaussian sigma 1.5.
# usage: psnr.py NGX_DIR RES OURS.f16 [OURS2.f16 ...]   (ours: tightly packed RGBA binary16, sRGB-encoded, quantized here as round(clamp*255))
import sys,numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter
def load(p):return np.asarray(Image.open(p).convert('RGB')).astype(np.float64)
def psnr(a,b):return 10*np.log10(255**2/((a-b)**2).mean())
def ssim(a,b):
    C1,C2=(0.01*255)**2,(0.03*255)**2;s=[]
    for c in range(3):
        x,y=a[...,c],b[...,c];f=lambda z:gaussian_filter(z,1.5,truncate=5/1.5)
        mx,my=f(x),f(y);sx=f(x*x)-mx*mx;sy=f(y*y)-my*my;sxy=f(x*y)-mx*my
        s.append((((2*mx*my+C1)*(2*sxy+C2))/((mx*mx+my*my+C1)*(sx+sy+C2))).mean())
    return float(np.mean(s))
d,res=sys.argv[1],sys.argv[2];w,h=map(int,res.split('x'))
nv=load(f'{d}/single-frame-outputs/{res}_nvidia.png');mo=load(f'{d}/single-frame-outputs/{res}_dlssnr-amd.png');inp=load(f'{d}/single-frame-inputs/{res}.png')
print(f'{res} mochizuki psnr={psnr(mo,nv):.2f} ssim={ssim(mo,nv):.5f} | input psnr={psnr(inp,nv):.2f}')
for p in sys.argv[3:]:
    o=np.fromfile(p,np.float16).astype(np.float64).reshape(h,w,4)[...,:3]
    o=np.round(np.clip(o,0,1)*255)
    md=(o-nv).mean(axis=(0,1));within=(np.abs(o-nv).max(axis=2)<=1).mean()*100
    print(f'{res} {p} psnr={psnr(o,nv):.2f} ssim={ssim(o,nv):.5f} mean_diff={md.round(3)} within1={within:.1f}% vs_mochizuki={psnr(o,mo):.2f}')
