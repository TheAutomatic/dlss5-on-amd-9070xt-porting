#!/usr/bin/env python3
from pathlib import Path
import csv,json,collections,sys
r=Path(sys.argv[1])
def rows(name):return list(csv.DictReader((r/name).open(encoding='utf-8-sig')))
groups=collections.defaultdict(dict)
for x in rows('timings.csv'):groups[x['batch'],int(x['slot'].split('-')[1]),int(x['frames'])][int(x['slot'].split('-')[-1])]=float(x['mean_ms'])
times=[];incomplete=[]
for (batch,h,n),v in sorted(groups.items()):
 if len(v)!=4:incomplete.append(dict(batch=batch,height=h,slots=v));continue
 a=(v[0]+v[3])/2;b=(v[1]+v[2])/2;times.append(dict(batch=batch,height=h,frames_per_slot=n,baseline_ms=a,candidate_ms=b,delta_ms=b-a,percent=100*(b/a-1),slots=v))
gold=list(csv.DictReader((r.parent/'float-fma-20260928/new-baseline-hashes.csv').open(encoding='utf-8-sig')));g={(x['mode'],x['case'],x['frame']):x['sha'].lower() for x in gold}
hashes=rows('frame-hashes.csv');base={(x['batch'],x['slot'][:-6],x['frame']):x['sha'].lower() for x in hashes if x['slot'].endswith('-False')};checked=[];gameflags=[]
for x in hashes:
 if not x['slot'].endswith('-True'):continue
 case=x['slot'][:-5];sha=x['sha'].lower();assert base[x['batch'],case,x['frame']]==sha,x
 if x['batch'].endswith('-gameflags'):gameflags.append(x);continue
 mode='AE' if x['batch'].endswith('-adaptive') else 'EXACT';assert g[mode,case,x['frame']]==sha,x;checked.append(x)
ae=rows('adaptive-decisions.csv');a={(x['set'],x['case'][:-6],x['frame']):x for x in ae if x['case'].endswith('-False')};b={(x['set'],x['case'][:-5],x['frame']):x for x in ae if x['case'].endswith('-True')};assert a.keys()==b.keys()
fields=['reuse','age','reason','relative','local','image'];different=sum(any(a[k][f]!=b[k][f] for f in fields) for k in a);assert not different
out=dict(timings=times,incomplete_timing_batches=incomplete,candidate_frames_matching_float_fma=len(checked),candidate_frames_by_batch=dict(collections.Counter(x['batch'] for x in checked)),game_flags_extra_matching_frames=len(gameflags),AE_pairs=len(a),AE_all_fields_different=different,AE_reuse_by_batch={s:dict(collections.Counter(x['reuse'] for x in b.values() if x['set']==s)) for s in sorted({x['set'] for x in b.values()})})
(r/'summary.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
