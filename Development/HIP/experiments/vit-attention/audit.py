#!/usr/bin/env python3
import argparse,csv,json,re,subprocess,sys
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('raw',type=Path);p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
rows=list(csv.DictReader((a.raw/'hashes.csv').open(encoding='utf-8-sig')))
selected=[x for x in rows if x['batch'] in ['runtime-regression-P-correct','runtime-regression-P-adaptive']]
with (a.raw/'hashes-P.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=rows[0],lineterminator='\n');w.writeheader();w.writerows(selected)
subprocess.run([sys.executable,str(r/'Development/tools/compiler-versions/analyze-results.py'),'--version','P','--collected',str(a.raw),'--out',str(a.out)],check=True)
assert json.loads((a.out/'validation-P.json').read_text())['pass']
golden={(x['mode'],x['case'],x['frame']):x['sha'].upper() for x in csv.DictReader((r/'Development/results/float-fma-20260928/new-baseline-hashes.csv').open())}
def text(p):
 b=p.read_bytes();return b.decode('utf-16' if b[:2] in [b'\xff\xfe',b'\xfe\xff'] else 'utf-8-sig')
pressure=[]
for mode in [0,1]:
 batch=f'runtime-regression-P-roll-{mode}';rr=[x for x in rows if x['batch']==batch];assert len(rr)==48
 for x in rr:assert x['sha'].upper()==golden['AE' if mode else 'EXACT',x['slot'].rsplit('-',1)[0],x['frame']]
 for case in ['900-history','1080-history']:
  root=a.raw/batch;slot=root/(case+'-True');log=text(slot/'run.log')
  m=re.search('SP_STATS (.*)',log);assert m
  stats={k:int(v) for k,v in re.findall(r'(\w+)=(\d+)',m[1])}
  assert stats['runs']==stats['rollover']==24 and stats['fallback']==stats['errors']==0
  data=list(csv.DictReader((slot/'rgb.csv').open()));assert len(data)==12 and all(x['checked']=='1' and int(x['invalid'])==0 for x in data)
  if mode:
   b=list(csv.reader((root/(case+'-False')/'adaptive.csv').open()));c=list(csv.reader((slot/'adaptive.csv').open()));assert b==c and len(c)==12
  pressure.append(dict(mode=mode,case=case,frames=12,**stats))
(a.out/'pressure.json').write_text(json.dumps(pressure,indent=2)+'\n')
micro=[]
for folder in sorted(a.raw.glob('micro*')):
 if not folder.is_dir():continue
 for f in sorted(folder.glob('*.log')):
  s=text(f);times=[float(x) for x in re.findall(r'^TIME,[^,]+,\d+,([0-9.]+)',s,re.M)]
  match=re.search(r'^RESULT,([^,]+),([0-9.]+),(\d+),(\d+)',s,re.M);assert match and len(times)==7
  median=sorted(times)[3];assert abs(median-float(match[2]))<1e-6
  assert len(re.findall(r'^CHECK,[^\n]*guards=0,invalid=0,nonzero=[1-9]',s,re.M))==2
  if match[1].startswith(('ours-','constv-')) and not match[1].endswith('-base'):
   assert len(re.findall(r'^EXACT,[^\n]*different=0',s,re.M))==2
  micro.append(dict(batch=folder.name,job=match[1],median_us=median,times_us=times,diagnostic=match[1].startswith('constv-')))
(a.out/'micro.json').write_text(json.dumps(micro,indent=2)+'\n')
print(f'PASS 168 golden + 48 rollover frames; {len(micro)} isolated jobs')
