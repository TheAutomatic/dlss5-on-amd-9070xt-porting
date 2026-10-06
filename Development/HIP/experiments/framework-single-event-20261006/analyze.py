"""Four-slot complete-framework screen; only current-tag samples enter NET stats."""
import argparse,csv,re,json,hashlib
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('directory',type=Path);p.add_argument('--discard',type=int,default=80);p.add_argument('--app-net0',action='store_true');a=p.parse_args()
r=[];walls=[[],[]];nets=[[],[]];hashes={}
for i in range(4):
 d=a.directory/f'slot-{i}';rows=list(csv.DictReader((d/'frame.csv').open()));wall=[float(v['wall_ms']) for v in rows if int(v['frame'])>=a.discard]
 records=[(int(x),float(y),int(z),int(q)) for x,y,z,q in re.findall(r'FRAME_NET_GPU frame=(\d+) gpu_ms=([^ ]+) tag=(\d+) ready=(\d+)',(d/'stdout.log').read_text())]
 ready=[y for x,y,z,q in records if x>=a.discard and q and z==x+1]
 hashes[str(i)]={n:{'sha256':hashlib.sha256((d/n).read_bytes()).hexdigest(),'finite':bool(np.isfinite(np.fromfile(d/n,dtype='<f2')).all())} for n in ['frame-first.f16','frame.f16']}
 r.append(dict(slot=i,wall_mean=float(np.mean(wall)),wall_p99=float(np.percentile(wall,99)),net_mean_ready=float(np.mean(ready)) if ready else None,net_p99_ready=float(np.percentile(ready,99)) if ready else None,samples=len(wall),records=len(records),ready_all=sum(q and z==x+1 for x,y,z,q in records),ready_steady=len(ready),invalid=sum(int(v['invalid']) for v in rows if v['invalid'])))
 k=int(i in [1,2]);walls[k]+=wall;nets[k]+=ready
raw_same=all(hashes[str(i)][n]['sha256']==hashes['0'][n]['sha256'] for i in range(4) for n in ['frame-first.f16','frame.f16'])
finite=all(q['finite'] for h in hashes.values() for q in h.values())
s=dict(slots=r,avg_delta=float(np.mean(walls[1])-np.mean(walls[0])),merged_p99_delta=float(np.percentile(walls[1],99)-np.percentile(walls[0],99)),net_avg_delta_ready=float(np.mean(nets[1])-np.mean(nets[0])) if all(nets) else None,net_p99_delta_ready=float(np.percentile(nets[1],99)-np.percentile(nets[0],99)) if all(nets) else None,allBfaster=max(r[i]['wall_mean'] for i in [1,2])<min(r[i]['wall_mean'] for i in [0,3]),raw_same=raw_same,finite=finite,all_current_ready=all(x['records']==x['ready_all'] and x['samples']==x['ready_steady'] for x in r))
if a.app_net0:
 receipts=[]
 for i in range(4):
  log=(a.directory/f'slot-{i}'/'stderr.log').read_text()
  diag=re.findall(r'APP_DIAGNOSTIC_RECEIPT timer_on=(\d+) timer_creates=(\d+) timer_records=(\d+) timer_queries=(\d+) span_probe=(\d+) poll_records=(\d+) post_signal_queries=(\d+)',log)
  pulse=re.findall(r'APP_PULSE_RECEIPT create=(\d+) create_ok=(\d+) record=(\d+) record_ok=(\d+) destroy=(\d+) destroy_ok=(\d+) drain=(\d+)',log)
  records_ok=False
  if len(diag)==1 and len(pulse)==1:
   x=list(map(int,diag[0]));y=list(map(int,pulse[0]));n=len(list(csv.DictReader((a.directory/f'slot-{i}'/'frame.csv').open())))
   records_ok=all(v==0 for v in x[:6]) and x[6]==n and (y==[1,1,n,n,1,1,1] if i in [1,2] else all(v==0 for v in y))
  receipts.append(dict(slot=i,diagnostic=diag,pulse=pulse,valid=records_ok))
 s['receipt']=receipts;s['all_diagnostics_off']=all(x['valid'] for x in receipts);s['all_current_ready']=False
 s['screen_pass']=s['avg_delta']<0 and s['merged_p99_delta']<0 and s['allBfaster'] and raw_same and finite and s['all_diagnostics_off']
else:
 s['screen_pass']=s['avg_delta']<0 and s['merged_p99_delta']<0 and s['allBfaster'] and raw_same and finite and s['all_current_ready']
(a.directory/'summary.json').write_text(json.dumps(s,indent=2)+'\n');(a.directory/'raw-hashes.json').write_text(json.dumps(hashes,indent=2)+'\n');print(json.dumps(s,indent=2))
