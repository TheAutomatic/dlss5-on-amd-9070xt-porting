#!/usr/bin/env python3
from pathlib import Path
import csv,json,collections,sys
r=Path(sys.argv[1]);groups=collections.defaultdict(dict)
for x in csv.DictReader((r/'timings.csv').open(encoding='utf-8-sig')):groups[x['batch'],int(x['slot'].split('-')[1]),int(x['frames'])][int(x['slot'].split('-')[-1])]=float(x['mean_ms'])
rows=[]
for (batch,h,n),v in sorted(groups.items()):
 assert len(v)==4,(batch,h,len(v));a=(v[0]+v[3])/2;b=(v[1]+v[2])/2;rows.append(dict(batch=batch,height=h,frames_per_slot=n,baseline_ms=a,candidate_ms=b,delta_ms=b-a,percent=100*(b/a-1),slots=v))
hashes=list(csv.DictReader((r/'frame-hashes.csv').open(encoding='utf-8-sig')));gold=list(csv.DictReader((r.parent/'float-fma-20260928/new-baseline-hashes.csv').open(encoding='utf-8-sig')));g={(x['mode'],x['case'],x['frame']):x['sha'] for x in gold};checks=[]
for x in hashes:
 if not x['slot'].endswith('-True'):continue
 mode='AE' if x['batch'].endswith('-adaptive') else 'EXACT';case=x['slot'][:-5];key=(mode,case,x['frame']);assert key in g;assert x['sha']==g[key],x;checks.append(x)
ae=list(csv.DictReader((r/'adaptive-decisions.csv').open(encoding='utf-8-sig')));a={(x['case'][:-6],x['frame']):x for x in ae if x['case'].endswith('-False')};b={(x['case'][:-5],x['frame']):x for x in ae if x['case'].endswith('-True')};assert len(a)==len(b)==84
fields=['reuse','age','reason','relative','local','image'];different=sum(any(a[k][f]!=b[k][f] for f in fields) for k in a);assert not different
out=dict(timings=rows,candidate_frames_matching_float_fma=len(checks),candidate_frames_by_batch=dict(collections.Counter(x['batch'] for x in checks)),AE_pairs=84,AE_all_fields_different=different)
(r/'summary.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
