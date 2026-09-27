from pathlib import Path
import csv,json,sys,collections
p=Path(sys.argv[1]);rows=list(csv.DictReader((p/'measurements.csv').open(encoding='utf-8-sig')));hashes=list(csv.DictReader((p/'frame-hashes.csv').open(encoding='utf-8-sig')))
ans={};groups=collections.defaultdict(dict)
for r in rows:groups[r['set_batch']][r['tag']]=r
for group,d in groups.items():
 out={}
 for h in ('900','1080'):
  if 'time-'+h+'-0' not in d:continue
  slots=[d['time-'+h+'-'+str(i)] for i in range(4)];assert len({x['sha256'] for x in slots})==1
  a=sum(float(slots[i]['mean_ms']) for i in (0,3))/2;b=sum(float(slots[i]['mean_ms']) for i in (1,2))/2
  out[h]={'baseline_ms':a,'candidate_ms':b,'delta_ms':b-a,'percent':(b/a-1)*100}
 ans[group]=out
pairs=collections.defaultdict(dict)
for r in hashes:
 tag,side=r['tag'].rsplit('-',1);pairs[(r['set_batch'],tag,r['frame'])][side]=r['sha256']
for key,d in pairs.items():assert d.keys()=={'False','True'} and d['False']==d['True'],key
print(json.dumps({'timing':ans,'measurement_rows':len(rows),'frame_hashes':len(hashes),'matched_candidate_frames':len(pairs)},indent=2))
