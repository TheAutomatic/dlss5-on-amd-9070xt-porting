#!/usr/bin/env python3
import json,csv,re,collections
from pathlib import Path
R=Path(__file__).resolve().parents[4];O=R/'Development/results/daniel-kernels-20260928';D=Path('/tmp/daniel-kernels/dispatch')
ours=json.loads(Path('/tmp/daniel-kernels/ours/ours-schedule.json').read_text());oc=json.loads(Path('/tmp/daniel-kernels/ours/ours-census.json').read_text());dc=json.loads(Path('/tmp/daniel-kernels/isa/census.json').read_text())['kernels'];dan=json.loads((D/'swin-schedule.json').read_text())+json.loads((D/'deep-schedule.json').read_text())
out=[];flat=[]
for tier,res in [(900,'900-default'),(1080,'1080-daniel-default'),(1080,'1080-matched-ours')]:
 a=collections.defaultdict(list);b=collections.defaultdict(list)
 topo=list(csv.DictReader((R/f'Development/results/tier900-20260927/{tier}-pdl1/topology.csv').open()))
 assert len(topo)==len(ours[str(tier)])==214
 for i,(t,x) in enumerate(zip(topo,ours[str(tier)])):
  assert t['kernel'].split(':',1)[1].split('|')[0]==x['kernel'],(i,t,x)
  key=t['stage'].replace('block','');key='0' if key=='pre-down' else key
  if 1<=i<=4:key=str(i)
  if 208<=i<=212:key='66' if i==208 else str(i-143)
  if x['kernel']=='vit_gather':key='repack'
  n=x['module']+':'+x['kernel'];a[key].append(dict(index=i,**x,resources=oc[n]['resources'],static=oc[n]['static'],census_key=n))
 for x in dan:
  if x['resolution']!=res:continue
  key='head' if x['family']=='head' else 'repack' if x['family']=='ViT-repack' else str(x['block']);r=dc[x['symbol']]
  b[key].append(dict(**x,resources=r['resources'],static=r['static'],loop_expanded_path_sum_upper=r['loop_expanded_path_sum_upper']))
 for key in sorted(set(a)|set(b),key=lambda k:(not k.isdigit(),int(k) if k.isdigit() else k)):
  note='many-to-many network-position match; boundary projection may belong to adjacent fused block; no numerical equivalence asserted'
  if key in ['42','43','46']:note='ours intentionally skips this C512 decoder block; Daniel executes it'
  if key=='70':note+='; ours post shift(-4,-4), Daniel(0,0)'
  row=dict(resolution=res,position=key,ours=a[key],daniel=b[key],note=note);out.append(row)
  flat.append(dict(resolution=res,position=key,ours_calls=len(a[key]),daniel_calls=len(b[key]),ours_waves=sum(x['waves'] for x in a[key]),daniel_waves=sum(x['waves'] for x in b[key]),ours_kernels=';'.join(x['census_key'] for x in a[key]),daniel_kernels=';'.join(x['symbol'] for x in b[key]),note=note))
 assert sum(len(x) for x in a.values())==214 and sum(len(x) for x in b.values())==154
(O/'layer-pairs.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
with (O/'layer-pairs.csv').open('w') as f:w=csv.DictWriter(f,list(flat[0]));w.writeheader();w.writerows(flat)
print('paired',len(out),'position rows; three schedules each ours214 / Daniel154')
