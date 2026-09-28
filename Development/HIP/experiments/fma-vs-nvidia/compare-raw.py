#!/usr/bin/env python3
from pathlib import Path
import sys,json,hashlib
import numpy as np
root=Path(__file__).resolve().parents[4];raw=Path(sys.argv[1]);dest=Path(sys.argv[2])
oracle_path=root/'release/native-rgb-valid1080/amd-full/oracle-final.f32'
y=np.fromfile(oracle_path,np.float32).reshape(1152,1920,3)
xs={s:np.fromfile(raw/f'raw-{s}.f32',np.float32).reshape(y.shape) for s in ('A','F','H')}
def metric(x,y):
 assert np.isfinite(x).all() and np.isfinite(y).all()
 d=x.astype(np.float64)-y.astype(np.float64);rmse=float(np.sqrt(np.mean(d*d)))
 return dict(values=x.size,bit_different=int(np.count_nonzero(x.view(np.uint32)!=y.view(np.uint32))),mae=float(np.mean(np.abs(d))),rmse=rmse,max_abs=float(np.max(np.abs(d))),psnr_peak1_db=float(-20*np.log10(rmse)) if rmse else None)
out={'scope':'One preserved original-CUBIN random RGB fixture, seed0, reset, all71 blocks, raw network RGB (no codec), same 1920x1152 reflected input. Visible metrics crop first1080 rows. Not a game-image quality judgement.',
'oracle_sha256':hashlib.sha256(oracle_path.read_bytes()).hexdigest(),'outputs_sha256':{s:hashlib.sha256((raw/f'raw-{s}.f32').read_bytes()).hexdigest() for s in xs},
'vs_nvidia':{s:{'visible1080':metric(x[:1080],y[:1080]),'processing1152':metric(x,y)} for s,x in xs.items()},
'vs_current':{s:metric(x[:1080],xs['A'][:1080]) for s,x in xs.items() if s!='A'}}
dest.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
