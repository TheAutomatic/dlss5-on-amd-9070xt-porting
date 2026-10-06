#!/usr/bin/env python3
import csv,json,sys
from pathlib import Path
r=Path(sys.argv[1]);rows=list(csv.DictReader((r/'timings.csv').open(encoding='utf-8-sig')));times=[]
for batch in ('r1','r2'):
 for h in (900,1080):
  x={int(v['slot'].split('-')[-1]):float(v['mean_ms']) for v in rows if v['batch']==f'runtime-regression-P-{batch}' and v['slot'].startswith(f'time-{h}-')}
  if len(x)!=4:continue
  a=(x[0]+x[3])/2;b=(x[1]+x[2])/2;times.append(dict(batch=batch,height=h,baseline_ms=a,production_ms=b,delta_ms=b-a,percent=100*(b/a-1),slots=x))
hashes=list(csv.DictReader((r/'frame-hashes.csv').open(encoding='utf-8-sig')));golden=[];changes=[]
for mode,batch in [('EXACT','correct'),('AE','adaptive')]:
 for case in ('900-static','900-motion','1080-static','1080-motion','720-motion','900-history','1080-history'):
  sets=[{x['frame']:x['sha'] for x in hashes if x['batch']==f'runtime-regression-P-{batch}' and x['slot']==case+'-'+side} for side in ('False','True')]
  a,b=sets;assert len(a)==len(b)==12,(mode,case)
  changes.append(dict(mode=mode,case=case,frames=12,changed=sum(a[k]!=b[k] for k in a)))
  for frame,sha in sorted(b.items()):golden.append(dict(mode=mode,case=case,frame=frame,sha=sha))
with (r/'new-baseline-hashes.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=['mode','case','frame','sha']);w.writeheader();w.writerows(golden)
ae=list(csv.DictReader((r/'adaptive-decisions.csv').open(encoding='utf-8-sig')));pairs=[]
for case in ('900-static','900-motion','1080-static','1080-motion','720-motion','900-history','1080-history'):
 a={x['frame']:x for x in ae if x['case']==case+'-False'};b={x['frame']:x for x in ae if x['case']==case+'-True'};assert len(a)==len(b)==12,(case,len(a),len(b))
 pairs.append(dict(case=case,frames=12,reuse_changed=sum(a[k]['reuse']!=b[k]['reuse'] for k in a),control_changed=sum(any(a[k][c]!=b[k][c] for c in ['reuse','age','reason']) for k in a),any_field_changed=sum(any(a[k][c]!=b[k][c] for c in ['reuse','age','reason','relative','local','image']) for k in a),baseline_reuse=sum(x['reuse']=='1' for x in a.values()),production_reuse=sum(x['reuse']=='1' for x in b.values())))
(r/'summary.json').write_text(json.dumps(dict(timings=times,frame_changes=changes,adaptive=pairs),indent=2)+'\n');print(json.dumps(times,indent=2));print(json.dumps(pairs,indent=2))
