"""Independent dyadic half-FMA and ordered64-key tree references from locked shader formula."""
import argparse,json,hashlib
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
codes=np.arange(65536,dtype='<u2');scores=codes.view('<f2').astype('<f4');scores=scores[np.isfinite(scores)]
grid=np.linspace(-32,32,32769,dtype='<f4');scores=np.r_[scores,grid,np.nextafter(grid,np.float32(np.inf)),np.nextafter(grid,np.float32(-np.inf))].astype('<f4')
def probability(values):
    half_input=values.astype('<f2').astype(np.float64)
    # Exact fixed dyadic product/sum in binary64, then one half rounding; not f32 emulation.
    affine=(half_input*np.float64(.08953857421875)+np.float64(1.708984375)).astype('<f2')
    affine=np.clip(affine.astype(np.float32),np.float32(1.439453125),np.float32(1.9775390625)).astype('<f2')
    return ((affine.view('<u2')&1023)<<4).astype('<u2')
scores.tofile(a.output/'scores.f32');probability(scores).tofile(a.output/'score-gold.f16bits')
rng=np.random.default_rng(72606)
for tokens in (400,640):
    values=rng.uniform(-3,3,(64,tokens)).astype('<f4');prob=probability(values).view('<f2');den=np.zeros(64,dtype='<f2')
    for start in range(0,tokens,64):
        partial=np.zeros((64,8),dtype='<f2')
        for key in range(start,min(start+64,tokens),16):
            pair=(prob[:,key:key+8].astype(np.float32)+prob[:,key+8:key+16].astype(np.float32)).astype('<f2')
            partial=pair if key==start else (partial.astype(np.float32)+pair.astype(np.float32)).astype('<f2')
        even,odd=partial[:,0],partial[:,1]
        for j in (2,4,6):
            even=(even.astype(np.float32)+partial[:,j].astype(np.float32)).astype('<f2')
            odd=(odd.astype(np.float32)+partial[:,j+1].astype(np.float32)).astype('<f2')
        chunk=(even.astype(np.float32)+odd.astype(np.float32)).astype('<f2')
        den=(den.astype(np.float32)+chunk.astype(np.float32)).astype('<f2')
    prob.tofile(a.output/f'den-{tokens}.f16');den.tofile(a.output/f'den-{tokens}-gold.f16')
meta={'score_samples':len(scores),'score_scope':'63488 finitehalf inputs +98307 f32half boundary neighborhoods; NaN/Inf not claimed',
      'denominator_scope':'64queries×640 matches10fullchunks;400 uses explicit16keytail, not mochi448 geometry',
      'locked_source':'d1185d2 windows/shaders/rdna4/vit_attn.comp nr_vit_exp2;include/vit_attn_vt_chunk.glsl91-110',
      'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in a.output.iterdir() if p.is_file() and p.suffix in ('.f16','.f32','.f16bits')}}
(a.output/'scalar-gold.json').write_text(json.dumps(meta,indent=2)+'\n')
print('CPU_MATH_REFERENCE_READY scores='+str(len(scores))+' den=64x400/640; independent formula, no GPU parity claim')
