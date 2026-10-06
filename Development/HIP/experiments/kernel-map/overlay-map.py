#!/usr/bin/env python3
"""Apply accepted head/ViT microbenchmark refreshes to an audited baseline map.
This never claims a full-map or full-frame rerun. It requires explicit accepted=true.
"""
from pathlib import Path
import argparse,json,csv,hashlib,statistics,math
p=argparse.ArgumentParser();p.add_argument('--overlay',type=Path,required=True);p.add_argument('--baseline',type=Path,default=Path('/tmp/kernel-map/analysis-final'));p.add_argument('--out',type=Path,default=Path('/tmp/kernel-map/analysis-after'));a=p.parse_args()
c=json.loads(a.overlay.read_text());assert c.get('accepted') is True,'Overlay disabled until candidates are accepted.'
bs=json.loads((a.baseline/'summary.json').read_text());assert bs['final'] is True,'Baseline must be complete and repeat-resolved.'
old=json.loads((a.baseline/'measurement-provenance.json').read_text());rows=list(csv.DictReader((a.baseline/'position-timings.csv').open()));index={x['measurement_job_id']:x for x in old}
assert len(index)==323 and all(x['valid'] for x in old)
def resolve(s):
 q=Path(s);return q if q.is_absolute() else a.overlay.parent/q
meta_path=resolve(c['jobs_file']);metas=json.loads(meta_path.read_text());metas={x['id']:x for x in metas};logroot=resolve(c.get('logs_dir','logs-final-map'))
remove=set(c.get('remove_measurement_ids',[]));replace=c.get('replace_measurement_ids',{});adds=c.get('add_jobs',[])
head_old={x['measurement_job_id'] for x in old if x['backend']=='ours' and x['phase']=='head'}
vit_old={x['measurement_job_id'] for x in old if x['backend']=='ours' and x['phase']=='attention' and 31<=int(x['block'])<=38}
assert remove==head_old and len(remove)==2,'Expected exactly the old head pool+project pair.'
assert set(replace)==vit_old and len(replace)==8,'Expected all eight ViT attention sites.'
assert len(adds)==1 and adds[0]['group_id']=='b030.head_boundary','Expected one fused head job.'
new_ids=[v if isinstance(v,str) else v['measurement_job_id'] for v in replace.values()]+[adds[0]['measurement_job_id']]
assert len(set(new_ids))==9 and not set(new_ids)&(set(index)-remove-set(replace))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def measure_run(mid,folder):
 x=metas[mid];path=folder/(mid+'.log');b=path.read_bytes();s=b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig');tt={};checks=[];starts=[];results=[]
 for r in csv.reader(s.splitlines()):
  if not r or r[0] not in ['START','TIME','CHECK','RESULT']:continue
  assert r[1]==mid,(path,'foreign record')
  if r[0]=='START':starts.append(r[2])
  elif r[0]=='TIME':
   n=int(r[2]);assert n not in tt;tt[n]=float(r[3])
  elif r[0]=='CHECK':checks.append({k:int(v) for k,v in (z.split('=',1) for z in r[2:])})
  else:results.append(r)
 assert starts==[x['symbol']] and sorted(tt)==list(range(7)) and len(results)==1
 assert len(checks)>=2 and all(t.get('guards')==0 and t.get('invalid')==0 and t.get('nonzero',0)>0 for t in checks)
 assert all(math.isfinite(v) and v>0 for v in tt.values());med=statistics.median(tt.values());rr=results[0]
 assert int(rr[4])==7 and 64<=int(rr[3])<=200 and abs(float(rr[2])-med)<=1e-5
 return x,{'valid':True,'median_us':med,'round_us':[tt[k] for k in range(7)],'sample_count':7,'median_method':'7_round_median','log_path':str(path),'log_sha256':sha(path),'graph_repeats':int(rr[3]),'checks':checks,'errors':[],'metadata_path':str(meta_path),'metadata_sha256':sha(meta_path)}
repeat_ids=set(c.get('repeat_measurement_ids',[]))
assert repeat_ids<=set(new_ids), 'Repeat IDs must be among the nine refreshed jobs.'
repeat_dirs=[resolve(z) for z in c.get('repeat_logs_dirs',['logs-final-repeat1','logs-final-repeat2'])]
assert len(repeat_dirs)==2

def measure(mid):
 x,primary=measure_run(mid,logroot);runs=[dict(primary)]
 if mid in repeat_ids:
  for folder in repeat_dirs:
   _,extra=measure_run(mid,folder);runs.append(dict(extra))
 pooled=[v for run in runs for v in run['round_us']]
 assert len(pooled)==(21 if mid in repeat_ids else 7)
 combined=dict(primary);combined.update(median_us=statistics.median(pooled),round_us=pooled,sample_count=len(pooled),median_method='pooled_21_round_median' if mid in repeat_ids else '7_round_median',runs=runs,repeat_requested=mid in repeat_ids)
 return x,combined

def update(template,mid):
 x,m=measure(mid);r=dict(template);r.update(m);r.update(measurement_job_id=mid,kernel=x['symbol'],module=x['module'],grid_x=x['grid'][0],grid_y=x['grid'][1],grid_z=x['grid'][2],threads=x['block'][0],refresh_source='new_accepted_micro_log')
 r['original_measurement_job_id']=template.get('measurement_job_id','');return r
records=[]
for r in old:
 mid=r['measurement_job_id']
 if mid in remove:continue
 if mid in replace:
  v=replace[mid];records.append(update(r,v if isinstance(v,str) else v['measurement_job_id']))
 else:
  q=dict(r);q['refresh_source']='reused_baseline_measurement';records.append(q)
template=dict(index[sorted(remove)[0]]);template.update(dispatch_id='AHEAD001',job_id='ours.1080.b030.head_fused.0',group_id='b030.head_boundary',phase='head',block=30,host_count='')
newhead=update(template,adds[0]['measurement_job_id']);newhead['replaces_measurement_ids']=sorted(remove);records.append(newhead)
assert len(records)==322 and sum(x['backend']=='ours' for x in records)==168
bygroup={}
for x in records:bygroup.setdefault(x['group_id'],[]).append(x)
output=[]
for row in rows:
 r=dict(row);xs=bygroup[r['group_id']];oo=[x for x in xs if x['backend']=='ours'];dd=[x for x in xs if x['backend']=='daniel'];ratios=json.loads(r['area_ratio_by_block_json'])
 ou=sum(x['median_us'] for x in oo);du=sum(x['median_us'] for x in dd);de=sum(x['median_us']*float(ratios[str(x['block'])]) for x in dd)
 r.update(ours_us=ou,daniel_us=du,delta_us=ou-du,daniel_area_estimate_us=de,delta_area_estimate_us=ou-de,ours_dispatches=len(oo),daniel_dispatches=len(dd),ours_dispatch_ids=';'.join(x['dispatch_id'] for x in oo),ours_job_ids=';'.join(x['job_id'] for x in oo),ours_kernels=' + '.join(x['kernel'] for x in oo),ours_shapes_json=json.dumps([json.loads(x['shape_json']) for x in oo],sort_keys=True),status='valid',measurement_status='valid',refresh_scope='partially_refreshed_group' if any(x['refresh_source']=='new_accepted_micro_log' for x in xs) else 'baseline_group_reused')
 output.append(r)
a.out.mkdir(parents=True,exist_ok=True)
def save(name,data,fields=None):
 with (a.out/name).open('w',newline='') as f:
  w=csv.DictWriter(f,lineterminator="\n",fieldnames=fields or list(data[0]),extrasaction='ignore');w.writeheader();w.writerows(data)
save('position-timings.csv',output)
save('ranking-same-geometry.csv',sorted((r for r in output if r['eligible_exact_shape_rank']=='1'),key=lambda r:r['delta_us'],reverse=True),list(output[0]))
save('ranking-area-estimate.csv',sorted((r for r in output if r['comparison_policy'] not in ['skip_difference_exclude_implementation_rank','post_shift_mismatch_separate']),key=lambda r:r['delta_area_estimate_us'],reverse=True),list(output[0]))
fams=[]
for fam in sorted({r['family'] for r in output}):
 fs=[r for r in output if r['family']==fam];fams.append({'family':fam,'groups':len(fs),'ours_us':sum(r['ours_us'] for r in fs),'daniel_us':sum(r['daniel_us'] for r in fs),'delta_us':sum(r['delta_us'] for r in fs),'delta_area_estimate_us':sum(r['delta_area_estimate_us'] for r in fs)})
save('family-group-gaps.csv',fams)
summary={'final':True,'scope':'accepted-candidate partial microbenchmark refresh; NOT all-dispatch or end-to-end remeasurement','baseline_dir':str(a.baseline),'baseline_summary_sha256':sha(a.baseline/'summary.json'),'baseline_provenance_sha256':sha(a.baseline/'measurement-provenance.json'),'overlay_path':str(a.overlay),'overlay_sha256':sha(a.overlay),'new_measured_jobs':9,'refreshed_jobs_with_21_samples':sorted(repeat_ids),'refreshed_jobs_with_7_samples':sorted(set(new_ids)-repeat_ids),'new_measured_groups':sum(r['refresh_scope']=='partially_refreshed_group' for r in output),'ours_unchanged_measurements_reused':159,'daniel_unchanged_measurements_reused':154,'ours_dispatches_before':169,'ours_dispatches_after':168,'daniel_dispatches':154,'old_head_dispatches_removed':sorted(remove),'replaced_measurements':replace,'native_totals':{'ours_us':sum(r['ours_us'] for r in output),'daniel_us':sum(r['daniel_us'] for r in output),'gap_us':sum(r['delta_us'] for r in output)},'area_estimate_totals':{'daniel_us':sum(r['daniel_area_estimate_us'] for r in output),'gap_us':sum(r['delta_area_estimate_us'] for r in output)}}
assert summary['new_measured_groups']==9
(a.out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n');(a.out/'measurement-provenance.json').write_text(json.dumps(records,indent=2)+'\n');print(json.dumps(summary,indent=2))
