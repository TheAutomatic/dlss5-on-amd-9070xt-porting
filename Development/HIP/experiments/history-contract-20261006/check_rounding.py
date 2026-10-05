#!/usr/bin/env python3
"""Compare the same original post kernel's FLOAT4 and HALF4 outputs; CPU only."""
import argparse, json
from pathlib import Path
import numpy as np
ap=argparse.ArgumentParser();ap.add_argument('gold',type=Path);args=ap.parse_args()
result={}
for case in ('closed-history','zero-motion','one-pixel-motion','subpixel-diagonal'):
    original=np.fromfile(args.gold/f'{case}-float-output.f32',dtype='<f4')
    surface=np.fromfile(args.gold/f'{case}-half-output.f32',dtype='<f4')
    assert original.shape==surface.shape==(1024,)
    assert np.isfinite(original).all() and np.isfinite(surface).all()
    nearest=original.astype('<f2')
    toward=nearest.copy();overshoot=np.abs(nearest.astype('<f4'))>np.abs(original)
    toward.view('<u2')[overshoot]-=1
    result[case]={'count':int(original.size),'rne_diff':int(np.count_nonzero(surface!=nearest.astype('<f4'))),'rtz_diff':int(np.count_nonzero(surface!=toward.astype('<f4'))),'nonhalf_values':int(np.count_nonzero(original!=surface))}
    assert result[case]['rtz_diff']==0
print(json.dumps(result,indent=2))
