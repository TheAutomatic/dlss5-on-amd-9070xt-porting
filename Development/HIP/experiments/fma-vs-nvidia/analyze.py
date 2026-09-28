#!/usr/bin/env python3
import csv,json,sys
from pathlib import Path
r=Path(sys.argv[1]);rows=list(csv.DictReader((r/'timings.csv').open(encoding='utf-8-sig')))
summary=[]
for set_ in ('F','H'):
 for batch in ('r1','r2'):
  for height in (900,1080):
   slots={int(x['slot'].split('-')[-1]):float(x['mean_ms']) for x in rows if x['batch']==f'runtime-regression-{set_}-{batch}' and x['slot'].startswith(f'time-{height}-')}
   if len(slots)!=4:continue
   a=(slots[0]+slots[3])/2;b=(slots[1]+slots[2])/2
   summary.append(dict(candidate=set_,batch=batch,height=height,baseline_ms=a,candidate_ms=b,delta_ms=b-a,percent=(b/a-1)*100,slots=slots))
hashes=list(csv.DictReader((r/'frame-hashes.csv').open(encoding='utf-8-sig')))
checks=[]
for set_ in ('F','H'):
 for case in ('900-static','900-motion','1080-static','1080-motion','720-motion','900-history','1080-history'):
  a={x['frame']:x['sha'] for x in hashes if x['batch']==f'runtime-regression-{set_}-correct' and x['slot']==case+'-False'}
  b={x['frame']:x['sha'] for x in hashes if x['batch']==f'runtime-regression-{set_}-correct' and x['slot']==case+'-True'}
  assert len(a)==len(b)==12 and a.keys()==b.keys(),(set_,case,len(a),len(b))
  checks.append(dict(candidate=set_,case=case,frames=12,changed=sum(a[k]!=b[k] for k in a)))
(r/'summary.json').write_text(json.dumps({'timings':summary,'frame_checks':checks},indent=2)+'\n');print(json.dumps(summary,indent=2))
