"""Two-K16 HMMA.F16 model from existing original-post aligned() evidence.
Its validity for the restored gate is checked against native primitive results,
not assumed from RGB or from same-source tap equality.
"""
from pathlib import Path
import argparse,sys,json
import numpy as np
r=Path(__file__).resolve().parents[4];sys.path.insert(0,str(r/'Development'))
from native_post70_reference import aligned
p=argparse.ArgumentParser();p.add_argument('--features',type=Path,required=True);p.add_argument('--weights',type=Path,required=True);p.add_argument('--native',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
f=np.fromfile(a.features,'<f2').astype(np.float32).reshape(-1,32);w=np.fromfile(a.weights,'<f2').astype(np.float32).reshape(1,32)
g=aligned(f[:,:16],w[:,:16],np.zeros((len(f),1),np.float32));g=aligned(f[:,16:],w[:,16:],g).astype('<f2').reshape(-1)
g.tofile(a.output);d={'scope':'two HMMA.F16 chunks model, pending native proof','tokens':len(f),'finite':bool(np.isfinite(g).all()),'logit_min':float(g.min()),'logit_max':float(g.max())}
if a.native:
 n=np.fromfile(a.native,'<f2');assert n.shape==g.shape;d.update(native_half_bitdiff=int(np.count_nonzero(n.view('<u2')!=g.view('<u2'))),max_abs=float(np.max(abs(n.astype(np.float32)-g.astype(np.float32)))))
print(json.dumps(d,indent=2))
