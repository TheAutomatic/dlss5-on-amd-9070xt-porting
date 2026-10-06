#!/usr/bin/env python3
import argparse,csv,json,re,statistics
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('raw',type=Path);p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
repo=Path(__file__).resolve().parents[4]
hashes=list(csv.DictReader((a.raw/'hashes.csv').open(encoding='utf-8-sig')))
golden={(r['mode'],r['case'],r['frame']):r['sha'].upper() for r in csv.DictReader((repo/'Development/results/float-fma-20260928/new-baseline-hashes.csv').open())}
validation=[];timings=[];stats=[]
for root in sorted(a.raw.glob('runtime-regression-P-*')):
 batch=root.name.removeprefix('runtime-regression-P-');rr=[r for r in hashes if r['batch']==root.name]
 if rr:
  mode='AE' if batch.endswith('a1') or batch.endswith('-1') else 'EXACT'
  count=0;ae=0
  for r in rr:
   case=r['slot'].rsplit('-',1)[0]
   assert r['sha'].upper()==golden[mode,case,r['frame']],r
   count+=r['slot'].endswith('-True')
  for slot in root.glob('*-True'):
   data=list(csv.DictReader((slot/'rgb.csv').open()));assert len(data)==12 and all(r['checked']=='1' and int(r['invalid'])==0 for r in data)
   if mode=='AE':
    b=list(csv.reader((slot.with_name(slot.name[:-4]+'False')/'adaptive.csv').open()));c=list(csv.reader((slot/'adaptive.csv').open()));assert b==c and len(c)==12;ae+=len(c)
   b=(slot/'run.log').read_bytes();log=b.decode('utf-16' if b[:2]==b'\xff\xfe' else 'utf-8-sig')
   stage='-'.join(batch.split('-')[:2])
   targets={'c2-s1':(128,10),'c2-s2':(128,57),'c1-s1':(64,6),'c1-s2':(64,63)}
   if not slot.name.startswith('720-'):
    c,first=targets[stage];assert f'SP_PLAN c={c} first={first} ' in log
   m=re.search('SP_STATS (.*)',log);assert m
   st={k:int(v) for k,v in re.findall(r'(\w+)=(\d+)',m[1])};stats.append(dict(batch=batch,slot=slot.name,**st))
   if 'timeout' in batch:assert st['fallback']==st['disabled']==st['errors']==1
   else:assert st['fallback']==st['errors']==0
   if 'roll' in batch:assert st['rollover']>0
  if re.fullmatch(r'c[12]-s[12]-a[01]',batch):
   assert count==84 and (mode!='AE' or ae==84)
   assert {r['slot'].rsplit('-',1)[0] for r in rr}=={k[1] for k in golden if k[0]==mode}
  elif 'roll' in batch or 'timeout' in batch:
   assert count==24 and (mode!='AE' or ae==24)
  validation.append(dict(batch=batch,candidate_frames=count,ae_rows=ae,pass_all=True))
 for height in [900,1080]:
  dirs=[root/f'time-{height}-{i}' for i in range(4)]
  if not dirs[0].exists():continue
  means=[];slots=[]
  for d in dirs:
   data=list(csv.DictReader((d/'rgb.csv').open()));n=len(data);assert n in (240,1000)
   assert all(int(r['invalid'])==0 for r in data if r['checked']=='1')
   b=(d/'run.log').read_bytes();log=b.decode('utf-16' if b[:2]==b'\xff\xfe' else 'utf-8-sig')
   m=re.search('SP_STATS (.*)',log);assert m
   st={k:int(v) for k,v in re.findall(r'(\w+)=(\d+)',m[1])}
   assert st['fallback']==st['errors']==st['disabled']==0
   assert st['runs']==n*(3 if d.name[-1] in '12' else 2)
   vals=[float(r['wall_ms']) for r in data if int(r['frame'])>=(200 if n==1000 else 32)]
   means.append(statistics.mean(vals));slots.append(dict(slot=d.name,frames=n,kept=len(vals),mean_ms=means[-1]))
  base=(means[0]+means[3])/2;cand=(means[1]+means[2])/2
  timings.append(dict(batch=batch,height=height,baseline_ms=base,candidate_ms=cand,delta_ms=cand-base,delta_percent=(cand/base-1)*100,slots=slots))
for name,data in [('validation',validation),('timings',timings),('stats',stats)]:
 (a.out/f'{name}.json').write_text(json.dumps(data,indent=2)+'\n')
print(json.dumps(dict(validation=validation,timings=[{k:v for k,v in t.items() if k!='slots'} for t in timings]),indent=2))
