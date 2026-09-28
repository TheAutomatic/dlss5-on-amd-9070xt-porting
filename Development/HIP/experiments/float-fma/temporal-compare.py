#!/usr/bin/env python3
"""Five-frame off/on/reset comparison against original CUBIN-derived oracles."""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('prefixes',nargs='+',type=Path);p.add_argument('--release',type=Path,required=True);a=p.parse_args()
expected=[a.release/'native-rgb-valid1080/post70/shift-full-oracle.f32',a.release/'native-temporal-valid1080/post70/shift-full-oracle.f32']
known=['82b01ef638b74e79adbacb0e8eceb5d8c94141cdff3e8900f32bb3dfad51abaf','5fbef833d68c14a75252ede43870ade986310264ed3fc1189c332d3a75719f96']
oracle=[]
for path,sha in zip(expected,known):
 b=path.read_bytes();assert len(b)==26542080 and hashlib.sha256(b).hexdigest()==sha
 oracle.append(np.frombuffer(b,np.float32).reshape(1152,1920,3))
reports=[]
for prefix in a.prefixes:
 rows=[];sse=count=0;visible_sse=visible_count=0;previous={}
 for i in range(5):
  path=Path(str(prefix)+f'-frame{i}.f32');b=path.read_bytes();assert len(b)==26542080
  v=np.frombuffer(b,np.float32).reshape(1152,1920,3);assert np.isfinite(v).all(),path
  d=v.astype(np.float64)-oracle[i%2];ss=float(np.sum(d*d));vs=float(np.sum(d[:1080]*d[:1080]));sse+=ss;count+=d.size;visible_sse+=vs;visible_count+=d[:1080].size
  if i%2 in previous: assert b==previous[i%2],'off/on replay output changed'
  previous[i%2]=b
  rows.append(dict(frame=i,history=i%2,rmse=(ss/d.size)**.5,visible_rmse=(vs/d[:1080].size)**.5,sha256=hashlib.sha256(b).hexdigest(),finite=True))
 reports.append(dict(prefix=str(prefix),frames=rows,aggregate_rmse=(sse/count)**.5,visible_aggregate_rmse=(visible_sse/visible_count)**.5))
print(json.dumps(dict(scope='71 blocks, fixed RGB/history, five-frame off/on/reset; not previous-output feedback or game acceptance',oracles=[str(x) for x in expected],reports=reports),indent=2))
