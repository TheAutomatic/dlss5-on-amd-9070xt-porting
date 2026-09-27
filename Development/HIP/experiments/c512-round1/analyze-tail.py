from pathlib import Path
import csv,collections,json,statistics,sys
root=Path(sys.argv[1]);result={}
for height in (900,1080):
 d=root/f'{height}-tail';b=(d/'run.log').read_bytes();log=b.decode('utf-16') if b[:2]==b'\xff\xfe' else b.decode();assert 'PASS c512 ledger checks=35' in log
 wanted=['mh_shift_pack','mh_pool_project_group_c256','mh_pool','mh_pool_project_production_h16w'];counts=collections.Counter();resources=collections.defaultdict(set)
 for l in log.splitlines():
  if not l.startswith('TOPO,'):continue
  _,stage,module,kernel,*values=l.split(',')
  if kernel not in wanted or (kernel=='mh_pool_project_production_h16w' and stage!='block30'):continue
  counts[kernel]+=1;resources[kernel].add(tuple(map(int,values)))
 times=collections.defaultdict(list)
 for r in csv.DictReader((d/'marginal.csv').open()):times[r['kernel'].rstrip('$')].append(float(r['ms']))
 result[str(height)]={}
 for k,x in times.items():
  assert len(x)==8
  ds=[(x[i+1]+x[i+2]-x[i]-x[i+3])/4 for i in (0,4)]
  result[str(height)][k]={'calls':counts[k],'resources':[dict(zip(['groups','threads','vgpr','lds','scratch','resident_groups_per_mp'],r)) for r in sorted(resources[k])],'marginal_round_ms':ds,'marginal_mean_ms':statistics.mean(ds)}
print(json.dumps(result,indent=2))
