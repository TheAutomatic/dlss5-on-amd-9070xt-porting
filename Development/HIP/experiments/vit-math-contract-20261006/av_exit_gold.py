"""Small signed context source-semantic half-stage gold; no GPU/LLPC accuracy claim."""
import argparse,json,hashlib
from pathlib import Path
import numpy as np
ap=argparse.ArgumentParser();ap.add_argument('directory',type=Path);a=ap.parse_args();r=a.directory
den=np.fromfile(r/'denominator-8.f16',dtype='<f2');ctx=np.array([0.,-0.,2**-26,-2**-26,2**-24,-2**-24,.5,-.5,1.,-1.,1+2**-11,-(1+2**-11),448.,-448.,65504.,-65504.,65520.,-65520.,100000.,-100000.],dtype='<f4');pairs=np.array([(x,float(d)) for d in den for x in ctx],dtype='<f4')
with np.errstate(over='ignore'):
    ctxhalf=pairs[:,0].astype('<f2');inv=(np.float32(1)/np.maximum(pairs[:,1],np.float32(6.198883056640625e-5))).astype('<f2');product=(ctxhalf.astype('<f8')*inv.astype('<f8')).astype('<f2')
pairs.tofile(r/'av-exit-input-160x2.f32');np.stack([ctxhalf.view('<u2'),inv.view('<u2'),product.view('<u2')],axis=-1).astype('<u2').tofile(r/'av-exit-gold-160x3.u16')
report={'rows':len(pairs),'columns':['RNE_half(ctx_fp32)','RNE_half(fp32(1/max(den_half,6.198883056640625e-5)))','RNE_half(ctx_half*inv_half)'],'domain':'finite signed ctx, positive tree den; includes half overflow and signed zero/subnormal/boundaries','not_claimed':'LLPC divide accuracy, NaN input and final FP8 byte semantics require primitive confirmation','files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [r/'av-exit-input-160x2.f32',r/'av-exit-gold-160x3.u16']}};(r/'av-exit-gold.json').write_text(json.dumps(report,indent=2))
