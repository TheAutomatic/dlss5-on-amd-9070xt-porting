# analyze.py <dir with <case>-<run>.f16>  -- first-order extrapolation x + k*(y1-x) vs 2/3 passes (multi-pass-extrap-20261003)
# Frames: 1296x720 RGBA16F, linear final output. Main space = sRGB-encoded clamp[0,1] (the network's own working encoding is sRGB-like);
# "lin" = linear clamp[0,1]. PSNR peak 1.
import sys, numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter
D = sys.argv[1]; W, H = 1296, 720
CASES = ['900-static', '1080-static', '1080-motion', '1080-history']
def load(c, r):
    a = np.fromfile(f'{D}/{c}-{r}.f16', np.float16).astype(np.float64).reshape(H, W, 4)[..., :3]
    assert np.isfinite(a).all(); return a
def enc(l):
    l = np.clip(l, 0, 1); return np.where(l <= 0.0031308, l * 12.92, 1.055 * l ** (1 / 2.4) - 0.055)
def psnr(a, b, m=None):
    e = (a - b) ** 2
    e = e[m] if m is not None else e
    v = e.mean(); return 99.0 if v == 0 else 10 * np.log10(1 / v)
def kstar(base, d, y, m=None):
    t = y - base
    if m is not None: d, t = d[m], t[m]
    return float((d * t).sum() / (d * d).sum())
def low(a): return np.stack([gaussian_filter(a[..., i], 2.0) for i in range(3)], -1)
out = []; P = lambda s: (out.append(s), print(s))
for space in ['srgb', 'lin']:
    P(f'\n## space={space}')
    for c in CASES:
        R = {r: load(c, r) for r in ['x', 'p1', 'p2', 'p3', 's2', 's25', 's3']}
        print(c, 'raw max', {k: round(float(v.max()), 3) for k, v in R.items()})
        if space == 'srgb': R = {k: enc(v) for k, v in R.items()}
        else: R = {k: np.clip(v, 0, 1) for k, v in R.items()}
        x, y1, y2, y3 = R['x'], R['p1'], R['p2'], R['p3']; d = y1 - x
        P(f'### {c}  |d| rms={np.sqrt((d**2).mean()):.4f}  |y2-y1| rms={np.sqrt(((y2-y1)**2).mean()):.4f}  |y3-y2| rms={np.sqrt(((y3-y2)**2).mean()):.4f}')
        P(f'baseline: x-y1 {psnr(x,y1):.2f}  y1-y2 {psnr(y1,y2):.2f}  y1-y3 {psnr(y1,y3):.2f}  y2-y3 {psnr(y2,y3):.2f}')
        for tgt, y in (('y2', y2), ('y3', y3)):
            row = '  '.join(f'k={k}:{psnr(np.clip(x+k*d,0,1),y):.2f}' for k in (1.5, 2, 2.5, 3))
            ks = kstar(x, d, y); P(f'x+k*d vs {tgt}: {row}  | k*={ks:.3f} -> {psnr(np.clip(x+ks*d,0,1),y):.2f}')
        P(f'decoder STRENGTH k,k (1 pass) vs y2: s2 {psnr(R["s2"],y2):.2f} s2.5 {psnr(R["s25"],y2):.2f} s3 {psnr(R["s3"],y2):.2f} | vs y3: s2 {psnr(R["s2"],y3):.2f} s2.5 {psnr(R["s25"],y3):.2f} s3 {psnr(R["s3"],y3):.2f}')
        k2 = kstar(y2, y2 - y1, y3); P(f'2nd order y3 ~ y2+k(y2-y1): k*={k2:.3f} -> {psnr(np.clip(y2+k2*(y2-y1),0,1),y3):.2f} (k=1: {psnr(np.clip(2*y2-y1,0,1),y3):.2f});  step ratio |y2-y1|/|d|={np.sqrt(((y2-y1)**2).mean()/(d**2).mean()):.3f} |y3-y2|/|y2-y1|={np.sqrt(((y3-y2)**2).mean()/((y2-y1)**2).mean()):.3f}')
        ks3 = kstar(x, d, y3); e = np.clip(x + ks3 * d, 0, 1)
        Y = (x * [0.2126, 0.7152, 0.0722]).sum(-1); q = np.quantile(Y, [1/3, 2/3])
        bk = {'dark': Y < q[0], 'mid': (Y >= q[0]) & (Y < q[1]), 'bright': Y >= q[1]}
        P('luma terciles of x (vs y3): ' + '  '.join(f'{n}: k*={kstar(x,d,y3,m):.2f} ext {psnr(e,y3,m):.2f} / y1 {psnr(y1,y3,m):.2f}' for n, m in bk.items()))
        lx, ld, l3, le, l1 = low(x), low(d), low(y3), low(e), low(y1)
        hx, hd, h3, he, h1 = x - lx, d - ld, y3 - l3, e - le, y1 - l1
        P(f'bands (gauss s=2) vs y3: low k*={kstar(lx,ld,l3):.2f} ext {psnr(le,l3):.2f} / y1 {psnr(l1,l3):.2f}  | high k*={kstar(hx,hd,h3):.2f} ext {psnr(he,h3):.2f} / y1 {psnr(h1,h3):.2f}  | hi-energy rms x {np.sqrt((hx**2).mean()):.4f} y1 {np.sqrt((h1**2).mean()):.4f} y3 {np.sqrt((h3**2).mean()):.4f} ext {np.sqrt((he**2).mean()):.4f}')
        if space == 'srgb':
            diff = np.clip(np.abs(e - y3) * 8, 0, 1)
            tiles = [y1, e, y3, diff]
            img = np.concatenate([np.asarray(Image.fromarray((t * 255 + .5).astype(np.uint8)).resize((648, 360), Image.LANCZOS)) for t in tiles], 1)
            Image.fromarray(img).save(f'{sys.argv[2]}/{c}.png')
open(f'{sys.argv[2]}/../psnr.txt', 'w').write('\n'.join(out) + '\n')
