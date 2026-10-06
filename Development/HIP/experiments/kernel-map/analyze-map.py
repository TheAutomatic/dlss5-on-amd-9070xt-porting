#!/usr/bin/env python3
"""Strict measurement join. Old zero-output batch is never a final source."""
from pathlib import Path
import argparse,csv,json,re,statistics,hashlib,math
from collections import defaultdict
p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path('/tmp/kernel-map'));p.add_argument('--allow-old-preview',action='store_true');a=p.parse_args();root=a.root
J=lambda f:json.loads((root/f).read_text());jobs=list(csv.DictReader((root/'dispatch-jobs.csv').open()));positions=list(csv.DictReader((root/'position-map.csv').open()))
ours={x['id']:x for x in J('ours-jobs.json')};deep=J('deep1080.json');shallow=[x for x in J('daniel-shallow.json') if x['geometry']['resolution']=='1080-daniel-default']
def block(x):return int(re.search(r'\d+',str(x['position']))[0])
def phase(x):
 b=block(x);f=x['family']
 if f=='C512':return ['ffwd','ffn_projection','qkv_attention','attention_projection'][int(re.search(r'(?:stage)?(\d+)$',x['id'])[1])]
 if f=='ViT':return ['expand','contract','qkv','attention','projection'][int(re.search(r'(?:stage)?(\d+)$',x['id'])[1])]
 return {'ViT-repack':'entry_gather' if b==30 else 'exit_gather','head':'head','decoder':'up'}.get(f,'core')
dindex=defaultdict(list)
for x in deep+shallow:dindex[(block(x),phase(x),x['symbol'],tuple(x['grid']),int(x['block'][0]))].append(x)
assert len(jobs)==323 and len(ours)==169 and len(deep)==108 and len(shallow)==46
preview=a.allow_old_preview;oursdir='logs-ours' if preview else 'logs-ours-valid'
repeat_plan=root/'repeat-list.txt'
requested_repeats=set(repeat_plan.read_text().splitlines()) if repeat_plan.exists() and not preview else set()
requested_repeats.discard('')
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def text(path):
 b=path.read_bytes();return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
def readlog(path,x):
 errors=[];times={};checks=[];result=[];start=[]
 if not path.exists():return {'valid':False,'errors':['missing_log'],'log_path':str(path)}
 try:
  for r in csv.reader(text(path).splitlines()):
   if not r or r[0] not in ['START','TIME','CHECK','RESULT']:continue
   if len(r)<2 or r[1]!=x['id']:errors.append('foreign_job_record');continue
   if r[0]=='START':start.append(r[2])
   elif r[0]=='TIME':
    n=int(r[2]);v=float(r[3])
    if n in times:errors.append('duplicate_TIME_round')
    times[n]=v
   elif r[0]=='CHECK':checks.append({k:int(v) for k,v in (z.split('=',1) for z in r[2:])})
   elif r[0]=='RESULT':result.append(r)
  if start!=[x['symbol']]:errors.append('START_symbol_or_count')
  if sorted(times)!=list(range(7)):errors.append('TIME_not_exactly_7_unique_rounds')
  if any(not math.isfinite(v) or v<=0 for v in times.values()):errors.append('TIME_nonpositive_nonfinite')
  if len(checks)<2:errors.append('missing_pre_or_post_CHECK')
  if any(c.get('guards')!=0 or c.get('invalid')!=0 or c.get('nonzero',0)<=0 for c in checks):errors.append('CHECK_guard_invalid_or_zero_output')
  med=statistics.median(times.values()) if len(times)==7 else None
  if len(result)!=1:errors.append('RESULT_count')
  elif int(result[0][4])!=7 or med is None or abs(float(result[0][2])-med)>0.00001:errors.append('RESULT_median_round_mismatch')
  reps=int(result[0][3]) if len(result)==1 else None
  if reps is not None and not 64<=reps<=200:errors.append('unexpected_graph_repeat_count')
 except (ValueError,IndexError,KeyError) as e:errors.append('parse_error:'+str(e));med=None;reps=None
 return {'valid':not errors,'errors':errors,'log_path':str(path),'log_sha256':digest(path),'median_us':med,'round_us':[times[k] for k in sorted(times)],'graph_repeats':reps,'checks':checks}
def signature(x):
 # Actual pointers are normalized by their argument role; scalar args/alias relationships are retained.
 ptrs={};args=[];buf={b['id']:b for b in x['buffers']}
 for arg in x['args']:
  q=dict(arg)
  if q['type']=='ptr' and 'buffer' in q:
   name=q['buffer'];ptrs.setdefault(name,len(ptrs));q['buffer']=ptrs[name]
   b=buf[name];q['buffer_layout']={k:b.get(k) for k in ['bytes','init','value','check','check_bytes']}
  args.append(q)
 return hashlib.sha256(json.dumps({'symbol':x['symbol'],'grid':x['grid'],'block':x['block'],'args':args},sort_keys=True).encode()).hexdigest()[:16]
records=[];used=set();fixture_sources={}
for j in jobs:
 if j['backend']=='ours':
  mid='ours-%03d'%(int(j['dispatch_id'][1:])-1);x=ours[mid];folder=oursdir;meta='ours-jobs.json'
 else:
  key=(int(j['block']),j['phase'],j['kernel'],tuple(int(j[k]) for k in ['grid_x','grid_y','grid_z']),int(j['threads']))
  found=dindex[key];assert len(found)==1,(j['dispatch_id'],key,[x['id'] for x in found]);x=found[0];mid=x['id'];folder='logs-shallow' if x in shallow else 'logs-deep';meta='daniel-shallow.json' if x in shallow else 'deep1080.json'
 assert x['symbol']==j['kernel'] and x['grid']==[int(j[k]) for k in ['grid_x','grid_y','grid_z']] and x['block']==[int(j['threads']),1,1],j['dispatch_id']
 assert mid not in used,mid;used.add(mid)
 rec={**j,'measurement_job_id':mid,'metadata_path':str(root/meta),'metadata_sha256':digest(root/meta),'timing_class':signature(x)}
 primary=readlog(root/folder/(mid+'.log'),x);rec.update(primary)
 rec['runs']=[dict(primary)];rec['repeat_requested']=mid in requested_repeats;rec['sample_count']=len(primary.get('round_us',[]));rec['median_method']='7_round_median'
 if mid in requested_repeats:
  for rd in ['logs-repeat1','logs-repeat2']:rec['runs'].append(readlog(root/rd/(mid+'.log'),x))
  rec['valid']=all(y['valid'] for y in rec['runs'])
  rec['errors']=[f'run{i}: '+e for i,y in enumerate(rec['runs']) for e in y['errors']]
  rec['sample_count']=sum(len(y.get('round_us',[])) for y in rec['runs'])
  rec['median_method']='pooled_21_round_median'
  if rec['valid']:
   rec['round_us']=[v for y in rec['runs'] for v in y['round_us']];assert len(rec['round_us'])==21
   rec['median_us']=statistics.median(rec['round_us'])
  else:rec['median_us']=None
 records.append(rec)
assert len(used)==323
assert requested_repeats<=used, ('repeat_plan_unknown_jobs',sorted(requested_repeats-used))
byid={x['dispatch_id']:x for x in records};bad=[{'dispatch_id':x['dispatch_id'],'measurement_job_id':x['measurement_job_id'],'errors':x['errors'],'log_path':x['log_path']} for x in records if not x['valid']]
final=not bad and not preview
out=root/('analysis-final' if final else 'analysis-preview-old' if preview else 'analysis-pending');out.mkdir(exist_ok=True)
def ids(s):return s.split(';') if s else []
def family(row):
 b=int(row['blocks'].split(';')[0])
 if '.boundary' in row['group_id'] or 'head_boundary' in row['group_id']:return 'boundary_groups'
 if row['group_id'].startswith('vit.'):return 'ViT_repack'
 if 31<=b<=38:return 'ViT'
 if b==39:return 'decoder39'
 if 23<=b<=30 or 40<=b<=47:return 'C512_skipped' if b in [42,43,46] else 'C512'
 if b<=4 or b>=66:return 'C32'
 if b<=8 or b>=62:return 'C64'
 if b<=14 or b>=56:return 'C128'
 return 'C256'
rows=[]
for row in positions:
 os=[byid[k] for k in ids(row['ours_dispatch_ids'])];ds=[byid[k] for k in ids(row['daniel_dispatch_ids'])]
 ok=all(x['valid'] for x in os+ds);ratios=json.loads(row['area_ratio_by_block_json']);rr=dict(row)
 rr.update(family=family(row),measurement_status='valid' if ok else 'incomplete_or_invalid',status='valid' if ok else 'incomplete_or_invalid')
 if ok:
  om=sum(x['median_us'] for x in os);dm=sum(x['median_us'] for x in ds);da=sum(x['median_us']*float(ratios[str(x['block'])]) for x in ds)
  rr.update(ours_us=om,daniel_us=dm,delta_us=om-dm,daniel_area_estimate_us=da,delta_area_estimate_us=om-da)
 else:rr.update(ours_us='',daniel_us='',delta_us='',daniel_area_estimate_us='',delta_area_estimate_us='')
 rows.append(rr)
def csvout(name,data,fields=None):
 with (out/name).open('w',newline='') as f:
  if fields is None:fields=list(data[0]) if data else []
  w=csv.DictWriter(f,lineterminator="\n",fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(data)
csvout('position-timings.csv',rows)
validrows=[r for r in rows if r['measurement_status']=='valid']
strict=sorted((r for r in validrows if r['eligible_exact_shape_rank']=='1'),key=lambda r:r['delta_us'],reverse=True)
area=sorted((r for r in validrows if r['comparison_policy'] not in ['skip_difference_exclude_implementation_rank','post_shift_mismatch_separate']),key=lambda r:r['delta_area_estimate_us'],reverse=True)
csvout('ranking-same-geometry.csv',strict,fields=list(rows[0]));csvout('ranking-area-estimate.csv',area,fields=list(rows[0]))
# Flag outliers; NEVER discard them or silently substitute medians.
classes=defaultdict(list)
for x in records:
 if x['valid']:classes[x['timing_class']].append(x)
repeat=[]
for key,xs in classes.items():
 if len(xs)<2:continue
 m=statistics.median(x['median_us'] for x in xs)
 for x in xs:
  ratio=x['median_us']/m
  if abs(ratio-1)>.30:repeat.append({'measurement_job_id':x['measurement_job_id'],'dispatch_id':x['dispatch_id'],'kernel':x['kernel'],'class':key,'class_n':len(xs),'median_us':x['median_us'],'class_median_us':m,'ratio':ratio,'reason':'same launch/scalar ABI >30% from peer median; pointed tensor contents may differ','log_path':x['log_path']})
csvout('repeat-list.csv',repeat,fields=['measurement_job_id','dispatch_id','kernel','class','class_n','median_us','class_median_us','ratio','reason','log_path'])
fams=[]
for fam in sorted({x['family'] for x in rows}):
 fs=[x for x in rows if x['family']==fam];ok=all(x['measurement_status']=='valid' for x in fs)
 fams.append({'family':fam,'groups':len(fs),'complete':ok,'ours_us':sum(x['ours_us'] for x in fs) if ok else '', 'daniel_us':sum(x['daniel_us'] for x in fs) if ok else '', 'delta_us':sum(x['delta_us'] for x in fs) if ok else '', 'delta_area_estimate_us':sum(x['delta_area_estimate_us'] for x in fs) if ok else ''})
csvout('family-group-gaps.csv',fams)
# A second family view attributes actual dispatches by their network stage. Cross-stage
# fusion boundaries make this accounting convention-dependent; group ranking remains above.
def dispatch_family(x):
 b=int(x['block']);ph=x['phase']
 if ph in ['entry_gather','exit_gather'] or 31<=b<=38:return 'ViT_including_repack'
 if ph=='head':return 'head'
 if b==39:return 'decoder39'
 if 23<=b<=30 or 40<=b<=47:return 'C512'
 if b<=4 or b>=66:return 'C32'
 if b<=8 or b>=62:return 'C64'
 if b<=14 or b>=56:return 'C128'
 return 'C256'
fdispatch=[]
for fam in sorted({dispatch_family(x) for x in records}):
 xs=[x for x in records if dispatch_family(x)==fam];oo=[x for x in xs if x['backend']=='ours'];dd=[x for x in xs if x['backend']=='daniel'];ok=all(x['valid'] for x in xs)
 om=sum(x['median_us'] for x in oo) if ok else '';dm=sum(x['median_us'] for x in dd) if ok else ''
 fdispatch.append({'family':fam,'ours_dispatches':len(oo),'daniel_dispatches':len(dd),'complete':ok,'ours_us':om,'daniel_us':dm,'delta_us':om-dm if ok else '', 'daniel_skipped_by_ours_dispatches':sum(int(x['block']) in [42,43,46] for x in dd),'scope':'native independent medians; cross-family fused boundary attribution follows block number'})
csvout('family-gaps.csv',fdispatch)
summary={'final':final,'discarded_entire_batch':'logs-ours (42 zero-output jobs; no values used in final)','preview_old_explicit':preview,'expected_jobs':323,'valid_jobs':len(records)-len(bad),'invalid_or_missing':bad,'repeat_flag_count':len(repeat),'repeat_plan':sorted(requested_repeats),'repeat_resolved':sum(x['valid'] and x['repeat_requested'] for x in records),'repeat_unresolved':[x['measurement_job_id'] for x in records if x['repeat_requested'] and not x['valid']],'count_ours':169,'count_daniel':154,'groups':len(rows),'sum_scope':'sum of each independent-dispatch median, not end-to-end frame latency','area_scope':'sum Daniel native medians scaled per-block valid area; window quantization and post shift not corrected','native_totals':{'ours_us':sum(x['ours_us'] for x in rows),'daniel_us':sum(x['daniel_us'] for x in rows),'gap_us':sum(x['delta_us'] for x in rows)} if not bad else None,'area_estimate_totals':{'daniel_us':sum(x['daniel_area_estimate_us'] for x in rows),'gap_us':sum(x['delta_area_estimate_us'] for x in rows)} if not bad else None,'rankings_provisional':not final}
(out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n');(out/'measurement-provenance.json').write_text(json.dumps(records,indent=2)+'\n')
state={'output':str(out),'final':final,'valid_jobs':len(records)-len(bad),'bad':len(bad),'repeat_flags':len(repeat)}
(root/'analysis-state.json').write_text(json.dumps(state,indent=2)+'\n')
if not final and not preview and (root/'analysis-final/summary.json').exists():
 stale=json.loads((root/'analysis-final/summary.json').read_text());stale['final']=False;stale['superseded_by']=str(out/'summary.json');stale['status']='stale_results_pending_required_repeats'
 (root/'analysis-final/summary.json').write_text(json.dumps(stale,indent=2)+'\n')
print(json.dumps(state))
