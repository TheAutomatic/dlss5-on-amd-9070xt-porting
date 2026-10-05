"""Recover omitted post projection row from the original 310.8 asset; no fitting."""
from pathlib import Path
import argparse,hashlib,json,sys
import numpy as np
r=Path(__file__).resolve().parents[4];sys.path.insert(0,str(r/'Development'))
from native_split_reference import bits
p=argparse.ArgumentParser();p.add_argument('--weights',type=Path,required=True);p.add_argument('--blend',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
raw=a.weights.read_bytes();assert len(raw)==21808
head=np.empty((16,32),np.float32);head[bits(512,[2,5,6,7]),bits(512,[0,1,3,4,8])]=np.frombuffer(raw[0x5130:],'<f2')
assert all(np.count_nonzero(head[i])==32 for i in [0,2,4,6]);assert not np.count_nonzero(head[[1,3,5,7,8,9,10,11,12,13,14,15]])
head[6].astype('<f4').tofile(a.output/'post70-history-head.f32');head[6].astype('<f2').tofile(a.output/'post70-history-head.f16')
b=a.blend.read_bytes();assert len(b)==2 and int.from_bytes(b,'little')==0x39eb;(a.output/'post70-blend.f16').write_bytes(b)
meta={'source_sha256':hashlib.sha256(raw).hexdigest(),'source_bytes':len(raw),'source_head_offset':0x5130,'head_shape':[16,32],'RGB_rows_preserved':[0,2,4],'history_row':6,'gate_features':'row-major [processing_y][processing_x][32], IEEE f16, little endian','blend_f16_bits':'0x39eb','blend_float':float(np.frombuffer(b,'<f2')[0]),'assets':{q.name:{'bytes':q.stat().st_size,'sha256':hashlib.sha256(q.read_bytes()).hexdigest()}for q in a.output.glob('*')if q.is_file()}}
(a.output/'gate-assets.json').write_text(json.dumps(meta,indent=2)+'\n');print(json.dumps(meta,indent=2))
