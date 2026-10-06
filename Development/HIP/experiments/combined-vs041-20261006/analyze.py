"""APP wall/raw only, original O2 NET0 runner; whole rounds, never pick good slots."""
from pathlib import Path
import argparse,csv,numpy as np,json,hashlib
p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('--discard',type=int,default=80);a=p.parse_args();slots=[];raw={};samples=[]
for i in range(4):
 d=a.root/f'slot-{i}';rows=list(csv.DictReader((d/'frame.csv').open()));x=np.array([float(r['wall_ms']) for r in rows[a.discard:]]);samples.append(x)
 slots.append({'slot':i,'side':'current' if i in [1,2] else '0.41','total_frames':len(rows),'steady_frames':len(x),'cold_frame0_ms':float(rows[0]['wall_ms']),'steady_mean_ms':float(x.mean()),'steady_p99_ms':float(np.percentile(x,99)),'steady_all_positive_finite':bool(np.isfinite(x).all() and (x>0).all())})
 for n in ['frame-first.f16','frame.f16']:
  f=d/n;v=np.fromfile(f,'<f2');raw[f'{i}/{n}']={'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'finite':bool(np.isfinite(v).all()),'bytes':f.stat().st_size}
base=np.r_[samples[0],samples[3]];h=np.r_[samples[1],samples[2]];delta=float(h.mean()-base.mean());p99=float(np.percentile(h,99)-np.percentile(base,99));j={'slots':slots,'discard':a.discard,'merged_avg_delta_ms':delta,'merged_p99_delta_ms':p99,'avg_and_p99_both_improve':delta<0 and p99<0,'raw':raw,'all_first_last_sha_equal':len(set(v['sha256'] for v in raw.values()))==1,'scope':'separate original0.41/current NativeGameFrame O2 NET_TIMING0 wall only, frozen realHDR restorer; includes codec/bridge/NN/decode/copy/consumerflush, excludes gamerender/FSR/Present; not continuousgame source'}
(a.root/'analysis.json').write_text(json.dumps(j,indent=2)+'\n');print(json.dumps(j,indent=2))
